# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'stringio'

RSpec.describe ReactiveView::DevOrchestrator do
  let(:tmp_dir) { Pathname.new(Dir.mktmpdir('reactive_view_dev_orchestrator')) }
  let(:working_dir) { tmp_dir.join('.reactive_view') }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:orchestrator) { described_class.new(stdout: stdout, stderr: stderr) }

  before do
    FileUtils.mkdir_p(working_dir)
    allow(Rails).to receive(:root).and_return(tmp_dir)
    allow(ReactiveView.configuration).to receive(:working_directory_absolute_path).and_return(working_dir)

    ReactiveView.configuration.daemon_host = 'localhost'
    ReactiveView.configuration.daemon_port = 13_001
  end

  after do
    orchestrator.send(:release_lock!)
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#daemon_command' do
    it 'builds argv for development mode with explicit port' do
      expect(orchestrator.send(:daemon_command)).to eq(['npx', 'reactiveview', 'dev', '--port', '13001'])
    end
  end

  describe '#start_daemon!' do
    it 'spawns daemon with argv form and process group' do
      log_file = working_dir.join('daemon.log')

      allow(orchestrator).to receive(:wait_for_daemon_start!).and_return(true)

      expect(Process).to receive(:spawn).with(
        { 'PORT' => '13001' },
        'npx', 'reactiveview', 'dev', '--port', '13001',
        chdir: tmp_dir.to_s,
        out: [log_file.to_s, 'a'],
        err: [log_file.to_s, 'a'],
        pgroup: true
      ).and_return(12_345)

      orchestrator.send(:start_daemon!)

      expect(working_dir.join('daemon.pid').read.strip).to eq('12345')
    end
  end

  describe '#ensure_daemon_not_running!' do
    it 'raises when daemon pid file points at a live process' do
      working_dir.join('daemon.pid').write("777\n")
      allow(orchestrator).to receive(:process_alive?).with(777).and_return(true)

      expect do
        orchestrator.send(:ensure_daemon_not_running!)
      end.to raise_error(ReactiveView::Error, /already running/)
    end

    it 'raises when a ReactiveView listener already occupies daemon port' do
      allow(orchestrator).to receive(:listener_pids_for_port).with(13_001).and_return([44_444])
      allow(orchestrator).to receive(:command_for_pid).with(44_444).and_return('npx reactiveview dev --port 3001')

      expect do
        orchestrator.send(:ensure_daemon_not_running!)
      end.to raise_error(ReactiveView::Error, /already listening on port 13001/)
    end

    it 'raises when another process occupies daemon port' do
      allow(orchestrator).to receive(:listener_pids_for_port).with(13_001).and_return([55_555])
      allow(orchestrator).to receive(:command_for_pid).with(55_555).and_return('postgres')

      expect do
        orchestrator.send(:ensure_daemon_not_running!)
      end.to raise_error(ReactiveView::Error, /Port 13001 is already in use/)
    end

    it 'removes stale daemon pid files when process is not alive' do
      daemon_pid_file = working_dir.join('daemon.pid')
      daemon_pid_file.write("888\n")

      allow(orchestrator).to receive(:process_alive?).with(888).and_return(false)
      allow(orchestrator).to receive(:listener_pids_for_port).with(13_001).and_return([])

      expect { orchestrator.send(:ensure_daemon_not_running!) }.not_to raise_error
      expect(daemon_pid_file).not_to exist
    end
  end

  describe '#acquire_lock!' do
    it 'enforces a single orchestrator instance' do
      orchestrator.send(:acquire_lock!)

      other = described_class.new(stdout: stdout, stderr: stderr)

      expect do
        other.send(:acquire_lock!)
      end.to raise_error(ReactiveView::Error, /already running/)
    ensure
      other&.send(:release_lock!)
    end
  end
end
