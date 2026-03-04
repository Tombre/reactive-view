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

      allow(command).to receive(:boot_rails_environment!).and_return(true)
      allow(ReactiveView::DevOrchestrator).to receive(:new).and_return(orchestrator)

      expect(ReactiveView.configuration).to receive(:daemon_port=).with(4010)

      expect(command.run).to eq(0)
    end

    it 'returns an error for invalid options' do
      command = described_class.new(['--port', '0'], stdout: stdout, stderr: stderr)

      expect(command.run).to eq(1)
      expect(stderr.string).to include('port must be positive')
    end
  end
end
