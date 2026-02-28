# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe ReactiveView::Benchmark::ServerManager do
  let(:working_directory) { Dir.mktmpdir('reactive_view_server_manager') }

  after do
    FileUtils.rm_rf(working_directory)
  end

  describe '#daemon_command' do
    it 'builds argv for development mode with explicit port' do
      manager = described_class.new(mode: :development, daemon_port: 4312, working_directory: working_directory)

      expect(manager.send(:daemon_command)).to eq(['npx', 'reactiveview', 'dev', '--port', '4312'])
    end

    it 'builds argv for production mode' do
      manager = described_class.new(mode: :production, daemon_port: 4312, working_directory: working_directory)

      expect(manager.send(:daemon_command)).to eq(%w[npx reactiveview start])
    end
  end

  describe '#start_daemon' do
    it 'spawns daemon with argv form in development mode' do
      manager = described_class.new(mode: :development, daemon_port: 4312, working_directory: working_directory)

      allow(manager).to receive(:daemon_running?).and_return(false)
      allow(manager).to receive(:wait_for_server).and_return(true)
      allow(manager).to receive(:log)

      expect(Process).to receive(:spawn).with(
        'npx', 'reactiveview', 'dev', '--port', '4312',
        chdir: Rails.root.to_s,
        out: File::NULL,
        err: File::NULL
      ).and_return(12_345)

      manager.send(:start_daemon)
      expect(manager.instance_variable_get(:@daemon_pid)).to eq(12_345)
    end
  end

  describe '#build_production!' do
    it 'runs npm build with argv form' do
      manager = described_class.new(mode: :production, working_directory: working_directory)

      allow(manager).to receive(:log)
      expect(manager).to receive(:system)
        .with('npx', 'reactiveview', 'build', out: File::NULL, err: File::NULL)
        .and_return(true)

      manager.send(:build_production!)
    end
  end
end
