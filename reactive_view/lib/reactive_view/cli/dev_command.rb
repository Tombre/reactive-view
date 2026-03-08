# frozen_string_literal: true

require 'optparse'
require 'pathname'

require_relative 'doctor_command'

module ReactiveView
  module CLI
    class DevCommand
      CommandError = Class.new(StandardError)
      AUTO_DOCTOR_FIX_SKIP_ENV = 'REACTIVE_VIEW_DEV_SKIP_DOCTOR_FIX'

      def initialize(argv, stdout: $stdout, stderr: $stderr)
        @argv = argv.dup
        @stdout = stdout
        @stderr = stderr
        @options = {}
      end

      # @return [Integer] process exit code
      def run
        parse_options!

        return 0 if @options[:help]

        boot_rails_environment!
        apply_overrides!
        doctor_status = run_auto_doctor_fix
        return doctor_status unless doctor_status.zero?

        require 'reactive_view/dev_orchestrator'

        ReactiveView::DevOrchestrator.new(stdout: @stdout, stderr: @stderr).run
      rescue OptionParser::ParseError => e
        @stderr.puts("#{e.message}\n\n#{parser}")
        1
      rescue CommandError => e
        @stderr.puts("[ReactiveView] #{e.message}")
        1
      end

      private

      def parse_options!
        parser.parse!(@argv)
      end

      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = 'Usage: reactiveview dev [options]'

          opts.on('--port PORT', Integer, 'Override daemon port for this run') do |port|
            raise OptionParser::InvalidArgument, 'port must be positive' unless port.positive?

            @options[:port] = port
          end

          opts.on('--rails-env ENV', 'Boot Rails in a specific environment') do |env|
            @options[:rails_env] = env
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

      def apply_overrides!
        return unless @options[:port]

        ReactiveView.configuration.daemon_port = @options[:port]
      end

      def run_auto_doctor_fix
        return 0 unless auto_doctor_fix_enabled?

        ReactiveView::CLI::DoctorCommand.new(
          ['--fix'],
          stdout: @stdout,
          stderr: @stderr,
          boot_rails_environment: false,
          quiet: true
        ).run
      end

      def auto_doctor_fix_enabled?
        value = ENV[AUTO_DOCTOR_FIX_SKIP_ENV]
        return true if value.nil?

        !truthy?(value)
      end

      def truthy?(value)
        %w[1 true yes on].include?(value.strip.downcase)
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
    end
  end
end
