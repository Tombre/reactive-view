# frozen_string_literal: true

require 'thor'

require_relative 'cli/dev_command'
require_relative 'cli/doctor_command'

module ReactiveView
  module CLI
    class Shell < Thor::Shell::Basic
      def initialize(stdout:, stderr:)
        super()
        @stdout_override = stdout
        @stderr_override = stderr
      end

      def stdout
        @stdout_override || super
      end

      def stderr
        @stderr_override || super
      end
    end

    class App < Thor
      stop_on_unknown_option! :dev, :doctor
      default_task :help

      class << self
        def exit_on_failure?
          true
        end
      end

      desc 'dev', 'Start the ReactiveView development orchestrator'
      def dev(*argv)
        ReactiveView::CLI::DevCommand.new(argv, stdout: shell.stdout, stderr: shell.stderr).run
      end

      desc 'doctor', 'Diagnose/fix local daemon startup conflicts'
      def doctor(*argv)
        ReactiveView::CLI::DoctorCommand.new(argv, stdout: shell.stdout, stderr: shell.stderr).run
      end
    end

    class << self
      def start(argv = ARGV, stdout: $stdout, stderr: $stderr, **config)
        shell = Shell.new(stdout: stdout, stderr: stderr)
        result = App.start(argv, config.merge(shell: shell))
        result.is_a?(Integer) ? result : 0
      rescue SystemExit => e
        e.status
      end
    end
  end
end
