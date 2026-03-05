# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'reactive_view/cli'

RSpec.describe ReactiveView::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  describe '.start' do
    it 'dispatches the doctor command' do
      doctor = instance_double(ReactiveView::CLI::DoctorCommand, run: 0)

      expect(ReactiveView::CLI::DoctorCommand)
        .to receive(:new)
        .with([], stdout: stdout, stderr: stderr)
        .and_return(doctor)

      expect(described_class.start(['doctor'], stdout: stdout, stderr: stderr)).to eq(0)
    end

    it 'returns an error when command is unknown' do
      expect(described_class.start(['missing-command'], stdout: stdout, stderr: stderr)).to eq(1)
      expect(stderr.string).to include('Could not find command "missing-command"')
    end

    it 'prints help and succeeds when no command is provided' do
      expect(described_class.start([], stdout: stdout, stderr: stderr)).to eq(0)
      expect(stdout.string).to include('Commands:')
      expect(stdout.string).to include('dev')
    end
  end
end
