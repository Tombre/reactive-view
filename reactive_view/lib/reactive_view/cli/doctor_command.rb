# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'open3'

module ReactiveView
  module CLI
    class DoctorCommand
      CommandError = Class.new(StandardError)

      DEFAULT_RAILS_PORT = 3000
      FOREMAN_DEFAULT_RAILS_PORT = 5000
      SHUTDOWN_TIMEOUT_SECONDS = 3

      def initialize(argv, stdout: $stdout, stderr: $stderr)
        @argv = argv.dup
        @stdout = stdout
        @stderr = stderr
        @options = { fix: false }
      end

      # @return [Integer] process exit code
      def run
        parse_options!

        return 0 if @options[:help]

        boot_rails_environment!

        report = collect_report
        print_report(report)

        if @options[:fix]
          fix_passes = 0

          while report[:issues].any?(&:fixable?) && fix_passes < 3
            apply_fixes(report)
            fix_passes += 1

            @stdout.puts
            @stdout.puts '[ReactiveView] Re-running checks after fixes...'

            report = collect_report
            print_report(report)
          end
        elsif report[:issues].any?(&:fixable?)
          @stdout.puts
          @stdout.puts '[ReactiveView] Run `bundle exec reactiveview doctor --fix` to apply safe automatic cleanup.'
        end

        report[:blocking_issues].empty? ? 0 : 1
      rescue OptionParser::ParseError => e
        @stderr.puts("#{e.message}\n\n#{parser}")
        1
      rescue CommandError => e
        @stderr.puts("[ReactiveView] #{e.message}")
        1
      end

      private

      Issue = Struct.new(:message, :blocking, :fix, keyword_init: true) do
        def blocking?
          !!blocking
        end

        def fixable?
          !fix.nil?
        end
      end

      def parse_options!
        parser.parse!(@argv)
      end

      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = 'Usage: reactiveview doctor [options]'

          opts.on('--fix', 'Attempt safe automatic cleanup for ReactiveView-managed conflicts') do
            @options[:fix] = true
          end

          opts.on('--rails-env ENV', 'Boot Rails in a specific environment') do |env|
            @options[:rails_env] = env
          end

          opts.on('--rails-port PORT', Integer, 'Check a specific Rails web port (default: 3000)') do |port|
            raise OptionParser::InvalidArgument, 'rails port must be positive' unless port.positive?

            @options[:rails_port] = port
          end

          opts.on('-h', '--help', 'Show command help') do
            @options[:help] = true
            @stdout.puts(opts)
          end
        end
      end

      def boot_rails_environment!
        rails_root = locate_rails_root
        raise CommandError, 'Could not find Rails app root (missing config/environment.rb)' unless rails_root

        ENV['RAILS_ENV'] = @options[:rails_env] if @options[:rails_env]

        Dir.chdir(rails_root)
        require rails_root.join('config/environment').to_s
      end

      def collect_report
        rails_port = configured_rails_port
        daemon_port = ReactiveView.configuration.daemon_port

        rails_listener = listener_for_port(rails_port)
        daemon_listener = listener_for_port(daemon_port)
        foreman_default_listener = listener_for_port(FOREMAN_DEFAULT_RAILS_PORT)

        issues = []

        if rails_listener
          issues << Issue.new(
            blocking: true,
            message: "Rails port #{rails_port} is already in use by PID #{rails_listener[:pid]} (#{rails_listener[:command]})."
          )
        end

        if daemon_listener
          fix = if reactive_view_command?(daemon_listener[:command])
                  { type: :terminate_pid,
                    pid: daemon_listener[:pid] }
                end

          issues << Issue.new(
            blocking: true,
            fix: fix,
            message: "Daemon port #{daemon_port} is already in use by PID #{daemon_listener[:pid]} (#{daemon_listener[:command]})."
          )
        end

        daemon_pid_status = pid_file_status(daemon_pid_file_path)
        orchestrator_pid_status = pid_file_status(orchestrator_pid_file_path)

        if daemon_pid_status[:stale]
          issues << Issue.new(
            blocking: true,
            fix: { type: :remove_file, path: daemon_pid_file_path },
            message: "Stale daemon pid file detected at #{daemon_pid_file_path}."
          )
        elsif daemon_pid_status[:alive]
          issues << Issue.new(
            blocking: true,
            fix: { type: :terminate_pid, pid: daemon_pid_status[:pid] },
            message: "Daemon pid file points to a running process (PID #{daemon_pid_status[:pid]})."
          )
        end

        if orchestrator_pid_status[:stale]
          issues << Issue.new(
            blocking: true,
            fix: { type: :remove_file, path: orchestrator_pid_file_path },
            message: "Stale orchestrator pid file detected at #{orchestrator_pid_file_path}."
          )
        elsif orchestrator_pid_status[:alive]
          issues << Issue.new(
            blocking: true,
            fix: { type: :terminate_pid, pid: orchestrator_pid_status[:pid] },
            message: "ReactiveView orchestrator is already running (PID #{orchestrator_pid_status[:pid]})."
          )
        end

        lock_exists = orchestrator_lock_file_path.exist?
        if lock_exists && !orchestrator_pid_status[:alive]
          issues << Issue.new(
            blocking: true,
            fix: { type: :remove_file, path: orchestrator_lock_file_path },
            message: "Stale orchestrator lock file detected at #{orchestrator_lock_file_path}."
          )
        end

        procfile_web_explicit_port = procfile_web_port_explicit?
        if !procfile_web_explicit_port && foreman_default_listener
          issues << Issue.new(
            blocking: true,
            message: "Port 5000 is already in use by PID #{foreman_default_listener[:pid]} and Procfile.dev does not pin web PORT."
          )
        end

        {
          rails_root: Rails.root,
          rails_port: rails_port,
          daemon_port: daemon_port,
          procfile_web_explicit_port: procfile_web_explicit_port,
          blocking_issues: issues.select(&:blocking?),
          issues: issues
        }
      end

      def print_report(report)
        @stdout.puts '[ReactiveView] Doctor report'
        @stdout.puts "- Rails root: #{report[:rails_root]}"
        @stdout.puts "- Rails port check: #{report[:rails_port]}"
        @stdout.puts "- Daemon port check: #{report[:daemon_port]}"
        @stdout.puts "- Procfile web port pinned: #{report[:procfile_web_explicit_port] ? 'yes' : 'no'}"

        if report[:issues].empty?
          @stdout.puts '- Status: healthy'
          return
        end

        @stdout.puts '- Status: issues found'
        report[:issues].each do |issue|
          @stdout.puts "  - #{issue.message}"
        end
      end

      def apply_fixes(report)
        fixes = report[:issues].map(&:fix).compact.uniq
        return if fixes.empty?

        @stdout.puts
        @stdout.puts '[ReactiveView] Applying fixes...'

        fixes.each do |fix|
          case fix[:type]
          when :remove_file
            remove_file(fix[:path])
            @stdout.puts "- removed #{fix[:path]}"
          when :terminate_pid
            terminate_reactive_view_process(fix[:pid])
          end
        end
      end

      def terminate_reactive_view_process(pid)
        return unless pid

        command = command_for_pid(pid)
        unless reactive_view_command?(command)
          @stdout.puts "- skipped PID #{pid}; not a ReactiveView process (#{command})"
          return
        end

        terminate_pid(pid)
        @stdout.puts "- stopped PID #{pid}"
      end

      def terminate_pid(pid)
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          return
        end

        wait_for_process_exit(pid, SHUTDOWN_TIMEOUT_SECONDS)

        Process.kill('KILL', pid) if process_alive?(pid)
      rescue Errno::ESRCH
        nil
      end

      def wait_for_process_exit(pid, timeout_seconds)
        deadline = monotonic_time + timeout_seconds
        while process_alive?(pid)
          return if monotonic_time >= deadline

          sleep 0.1
        end
      end

      def pid_file_status(path)
        pid = read_pid(path)
        return { path: path, pid: nil, alive: false, stale: false } unless pid

        alive = process_alive?(pid)
        { path: path, pid: pid, alive: alive, stale: !alive }
      end

      def listener_for_port(port)
        pid = listener_pids_for_port(port).first
        return nil unless pid

        { pid: pid, command: command_for_pid(pid) }
      end

      def listener_pids_for_port(port)
        output = capture_command_output('lsof', '-nP', "-iTCP:#{port}", '-sTCP:LISTEN', '-t')
        return [] if output.empty?

        output.lines.map(&:strip).reject(&:empty?).map(&:to_i).select(&:positive?).uniq
      end

      def command_for_pid(pid)
        capture_command_output('ps', '-o', 'command=', '-p', pid.to_s).strip
      end

      def reactive_view_command?(command_line)
        command_line.include?('reactiveview dev') ||
          command_line.include?('vinxi dev') ||
          command_line.include?('reactive-view-dev') ||
          command_line.include?('.reactive_view')
      end

      def capture_command_output(*command)
        stdout, status = Open3.capture2(*command)
        status.success? ? stdout : ''
      rescue Errno::ENOENT
        ''
      end

      def procfile_web_port_explicit?
        procfile_path = Rails.root.join('Procfile.dev')
        return false unless procfile_path.exist?

        web_line = procfile_path.each_line.find { |line| line.strip.start_with?('web:') }
        return false unless web_line

        web_line.include?('PORT=')
      end

      def configured_rails_port
        @options[:rails_port] || ENV.fetch('PORT', DEFAULT_RAILS_PORT).to_i
      end

      def read_pid(path)
        return nil unless path.exist?

        value = path.read.strip
        return nil if value.empty? || value !~ /^\d+$/

        value.to_i
      rescue SystemCallError
        nil
      end

      def remove_file(path)
        path.delete if path.exist?
      rescue SystemCallError
        nil
      end

      def process_alive?(pid)
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH, Errno::EPERM
        false
      end

      def daemon_pid_file_path
        working_directory_path.join('daemon.pid')
      end

      def orchestrator_pid_file_path
        working_directory_path.join('orchestrator.pid')
      end

      def orchestrator_lock_file_path
        working_directory_path.join('orchestrator.lock')
      end

      def working_directory_path
        ReactiveView.configuration.working_directory_absolute_path
      end

      def locate_rails_root
        current = Pathname.new(Dir.pwd).expand_path

        loop do
          return current if current.join('config/environment.rb').exist?

          parent = current.parent
          return nil if parent == current

          current = parent
        end
      end

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
