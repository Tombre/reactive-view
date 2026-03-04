# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'reactive_view/cli/doctor_command'

RSpec.describe ReactiveView::CLI::DoctorCommand do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  describe '#run' do
    it 'returns an error for invalid rails port' do
      command = described_class.new(['--rails-port', '0'], stdout: stdout, stderr: stderr)

      expect(command.run).to eq(1)
      expect(stderr.string).to include('rails port must be positive')
    end

    it 'runs fixes and succeeds when conflicts are resolved' do
      command = described_class.new(['--fix'], stdout: stdout, stderr: stderr)

      initial_report = {
        rails_root: Pathname.new('/tmp/app'),
        rails_port: 3000,
        daemon_port: 3001,
        procfile_web_explicit_port: true,
        blocking_issues: [described_class::Issue.new(message: 'Daemon in use', blocking: true,
                                                     fix: { type: :terminate_pid, pid: 111 })],
        issues: [described_class::Issue.new(message: 'Daemon in use', blocking: true,
                                            fix: { type: :terminate_pid, pid: 111 })]
      }

      healthy_report = {
        rails_root: Pathname.new('/tmp/app'),
        rails_port: 3000,
        daemon_port: 3001,
        procfile_web_explicit_port: true,
        blocking_issues: [],
        issues: []
      }

      allow(command).to receive(:boot_rails_environment!).and_return(true)
      allow(command).to receive(:collect_report).and_return(initial_report, healthy_report)
      expect(command).to receive(:apply_fixes).with(initial_report)

      expect(command.run).to eq(0)
      expect(stdout.string).to include('Re-running checks after fixes')
    end
  end
end
