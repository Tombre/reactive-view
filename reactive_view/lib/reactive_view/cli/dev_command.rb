# frozen_string_literal: true

require 'optparse'
require 'pathname'

module ReactiveView
  module CLI
    class DevCommand
      CommandError = Class.new(StandardError)

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
        require 'reactive_view/dev_orchestrator'
        apply_overrides!

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
