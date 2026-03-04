# frozen_string_literal: true

require_relative 'cli/dev_command'
require_relative 'cli/doctor_command'

module ReactiveView
  module CLI
    class << self
      def start(argv, stdout: $stdout, stderr: $stderr)
        command = argv.shift

        case command
        when 'dev'
          ReactiveView::CLI::DevCommand.new(argv, stdout: stdout, stderr: stderr).run
        when 'doctor'
          ReactiveView::CLI::DoctorCommand.new(argv, stdout: stdout, stderr: stderr).run
        when nil, 'help', '--help', '-h'
          stdout.puts(help_text)
          0
        else
          stderr.puts("Unknown command: #{command}")
          stderr.puts(help_text)
          1
        end
      end

      private

      def help_text
        <<~TEXT
          Usage: reactiveview <command> [options]

          Commands:
            dev      Start the ReactiveView development orchestrator
            doctor   Diagnose/fix local daemon startup conflicts
            help     Show this help message
        TEXT
      end
    end
  end
end
