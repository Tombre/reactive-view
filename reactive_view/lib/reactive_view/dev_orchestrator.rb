# frozen_string_literal: true

require 'fileutils'
require 'open3'

module ReactiveView
  # Manages the ReactiveView development daemon as an explicit companion process.
  #
  # Rails no longer auto-starts the daemon. Developers run this orchestrator with
  # `bundle exec reactiveview dev` so startup is deterministic and failures are
  # surfaced immediately.
  class DevOrchestrator
    STARTUP_DELAYS = [0.1, 0.2, 0.3, 0.5, 0.5, 1, 1, 2, 2, 4, 4].freeze
    HEALTH_CHECK_PATH = '/api/render'
    SHUTDOWN_TIMEOUT_SECONDS = 5
    SIGNALS = %w[INT TERM].freeze

    def initialize(stdout: $stdout, stderr: $stderr)
      @stdout = stdout
      @stderr = stderr
      @daemon_pid = nil
      @shutdown_requested = false
      @lock_file = nil
      @previous_signal_handlers = {}
    end

    # @return [Integer] process exit code
    def run
      ensure_working_directory!
      acquire_lock!
      write_orchestrator_pid_file!
      ensure_daemon_not_running!
      sync_runtime!
      ReactiveView::FileSync.start_watching
      start_daemon!
      install_signal_handlers!
      wait_for_exit
    rescue Error => e
      @stderr.puts "[ReactiveView] #{e.message}"
      1
    ensure
      uninstall_signal_handlers!
      shutdown
    end

    private

    def sync_runtime!
      @stdout.puts '[ReactiveView] Syncing routes and loader types...'
      ReactiveView::LoaderRegistry.load_all
      ReactiveView::FileSync.sync_all
    end

    def start_daemon!
      @stdout.puts "[ReactiveView] Starting daemon on port #{daemon_port}..."

      @daemon_pid = Process.spawn(
        { 'PORT' => daemon_port.to_s },
        *daemon_command,
        chdir: Rails.root.to_s,
        out: [daemon_log_path.to_s, 'a'],
        err: [daemon_log_path.to_s, 'a'],
        pgroup: true
      )

      daemon_pid_file_path.write("#{@daemon_pid}\n")
      wait_for_daemon_start!

      @stdout.puts "[ReactiveView] Daemon ready at #{ReactiveView.configuration.daemon_url} (PID #{@daemon_pid})"
    end

    def wait_for_daemon_start!
      STARTUP_DELAYS.each do |delay|
        return if daemon_healthy?

        raise Error, daemon_boot_failure_message unless process_alive?(@daemon_pid)

        sleep delay
      end

      raise Error, daemon_boot_failure_message
    end

    def wait_for_exit
      loop do
        return 0 if @shutdown_requested

        _pid, child_status = Process.wait2(@daemon_pid, Process::WNOHANG)
        next sleep 0.5 unless child_status

        @daemon_pid = nil
        @stderr.puts '[ReactiveView] Daemon exited unexpectedly. Check .reactive_view/daemon.log for details.'
        return 1
      rescue Errno::ECHILD
        @daemon_pid = nil
        return @shutdown_requested ? 0 : 1
      end
    end

    def ensure_daemon_not_running!
      ensure_local_daemon_host!

      existing_pid = read_pid(daemon_pid_file_path)
      if existing_pid && process_alive?(existing_pid)
        raise Error, "ReactiveView daemon is already running (PID #{existing_pid})."
      end

      remove_file(daemon_pid_file_path)

      listening_pid = listener_pids_for_port(daemon_port).first
      return unless listening_pid

      command_line = command_for_pid(listening_pid)
      message = if reactive_view_command?(command_line)
                  "ReactiveView daemon is already listening on port #{daemon_port} (PID #{listening_pid})."
                else
                  "Port #{daemon_port} is already in use by PID #{listening_pid}."
                end

      raise Error, message
    end

    def ensure_local_daemon_host!
      return if local_daemon_host?

      raise Error,
            'Development orchestrator only supports localhost daemon hosts. ' \
            "Current host: #{ReactiveView.configuration.daemon_host.inspect}"
    end

    def local_daemon_host?
      host = ReactiveView.configuration.daemon_host.to_s
      %w[localhost 127.0.0.1 ::1].include?(host)
    end

    def daemon_command
      ['npx', 'reactiveview', 'dev', '--port', daemon_port.to_s]
    end

    def daemon_healthy?
      response = Faraday.get(health_check_url) do |req|
        req.options.open_timeout = 2
        req.options.timeout = 2
      end

      response.success?
    rescue Faraday::Error
      false
    end

    def daemon_boot_failure_message
      "ReactiveView daemon failed to boot on port #{daemon_port}. See #{daemon_log_path}."
    end

    def install_signal_handlers!
      SIGNALS.each do |signal|
        @previous_signal_handlers[signal] = Signal.trap(signal) do
          @shutdown_requested = true
        end
      end
    end

    def uninstall_signal_handlers!
      @previous_signal_handlers.each do |signal, handler|
        Signal.trap(signal, handler)
      rescue ArgumentError
        nil
      end

      @previous_signal_handlers.clear
    end

    def shutdown
      stop_daemon
      ReactiveView::FileSync.stop_watching
      remove_file(daemon_pid_file_path)
      remove_file(orchestrator_pid_file_path)
      release_lock!
    end

    def stop_daemon
      return unless @daemon_pid

      pid = @daemon_pid

      begin
        Process.kill('TERM', -pid)
      rescue Errno::ESRCH
        nil
      end

      wait_for_process_exit(pid, SHUTDOWN_TIMEOUT_SECONDS)

      begin
        Process.kill('KILL', -pid) if process_alive?(pid)
      rescue Errno::ESRCH
        nil
      end

      Process.wait(pid)
    rescue Errno::ECHILD, Errno::ESRCH
      nil
    ensure
      @daemon_pid = nil
    end

    def wait_for_process_exit(pid, timeout_seconds)
      deadline = monotonic_time + timeout_seconds

      while process_alive?(pid)
        return if monotonic_time >= deadline

        sleep 0.1
      end
    end

    def acquire_lock!
      @lock_file = File.open(orchestrator_lock_file_path, File::RDWR | File::CREAT, 0o644)

      # WHY: A file lock gives process-level exclusivity without stale-lock cleanup.
      # If the orchestrator crashes, the OS releases the lock automatically.
      locked = @lock_file.flock(File::LOCK_EX | File::LOCK_NB)
      return if locked

      existing_pid = read_pid(orchestrator_pid_file_path)
      message = if existing_pid
                  "ReactiveView orchestrator already running (PID #{existing_pid})."
                else
                  'ReactiveView orchestrator already running.'
                end
      raise Error, message
    end

    def release_lock!
      return unless @lock_file

      @lock_file.flock(File::LOCK_UN)
      @lock_file.close
      @lock_file = nil
    end

    def write_orchestrator_pid_file!
      orchestrator_pid_file_path.write("#{Process.pid}\n")
    end

    def process_alive?(pid)
      return false unless pid

      Process.kill(0, pid)
      true
    rescue Errno::ESRCH, Errno::EPERM
      false
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
        command_line.include?('reactiveview start') ||
        command_line.include?('vinxi dev') ||
        command_line.include?('vinxi start') ||
        command_line.include?('.reactive_view')
    end

    def capture_command_output(*command)
      stdout, status = Open3.capture2(*command)
      status.success? ? stdout : ''
    rescue Errno::ENOENT
      ''
    end

    def ensure_working_directory!
      FileUtils.mkdir_p(working_directory_path)
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

    def daemon_port
      ReactiveView.configuration.daemon_port
    end

    def health_check_url
      "#{ReactiveView.configuration.daemon_url}#{HEALTH_CHECK_PATH}"
    end

    def working_directory_path
      ReactiveView.configuration.working_directory_absolute_path
    end

    def daemon_log_path
      working_directory_path.join('daemon.log')
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

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
