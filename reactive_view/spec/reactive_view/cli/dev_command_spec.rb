# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'reactive_view/cli/dev_command'

RSpec.describe ReactiveView::CLI::DevCommand do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  describe '#run' do
    it 'applies daemon port overrides before starting orchestrator' do
      command = described_class.new(['--port', '4010'], stdout: stdout, stderr: stderr)
      orchestrator = instance_double(ReactiveView::DevOrchestrator, run: 0)
      doctor = instance_double(ReactiveView::CLI::DoctorCommand, run: 0)

      allow(command).to receive(:boot_rails_environment!).and_return(true)
      allow(ReactiveView::CLI::DoctorCommand).to receive(:new).and_return(doctor)
      allow(ReactiveView::DevOrchestrator).to receive(:new).and_return(orchestrator)

      expect(ReactiveView.configuration).to receive(:daemon_port=).with(4010)

      expect(command.run).to eq(0)
    end

    it 'runs doctor auto-fix before starting orchestrator' do
      command = described_class.new([], stdout: stdout, stderr: stderr)
      orchestrator = instance_double(ReactiveView::DevOrchestrator, run: 0)
      doctor = instance_double(ReactiveView::CLI::DoctorCommand)

      allow(command).to receive(:boot_rails_environment!).and_return(true)
      expect(ReactiveView::CLI::DoctorCommand).to receive(:new).with(
        ['--fix'],
        stdout: stdout,
        stderr: stderr,
        boot_rails_environment: false,
        quiet: true
      ).ordered.and_return(doctor)
      expect(doctor).to receive(:run).ordered.and_return(0)
      expect(ReactiveView::DevOrchestrator).to receive(:new).ordered.and_return(orchestrator)

      expect(command.run).to eq(0)
    end

    it 'skips doctor auto-fix when REACTIVE_VIEW_DEV_SKIP_DOCTOR_FIX is truthy' do
      command = described_class.new([], stdout: stdout, stderr: stderr)
      orchestrator = instance_double(ReactiveView::DevOrchestrator, run: 0)
      previous = ENV['REACTIVE_VIEW_DEV_SKIP_DOCTOR_FIX']
      ENV['REACTIVE_VIEW_DEV_SKIP_DOCTOR_FIX'] = '1'

      allow(command).to receive(:boot_rails_environment!).and_return(true)
      expect(ReactiveView::CLI::DoctorCommand).not_to receive(:new)
      expect(ReactiveView::DevOrchestrator).to receive(:new).and_return(orchestrator)

      expect(command.run).to eq(0)
    ensure
      ENV['REACTIVE_VIEW_DEV_SKIP_DOCTOR_FIX'] = previous
    end

    it 'returns an error for invalid options' do
      command = described_class.new(['--port', '0'], stdout: stdout, stderr: stderr)

      expect(command.run).to eq(1)
      expect(stderr.string).to include('port must be positive')
    end
  end
end
