# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe ReactiveView::Daemon do
  let(:daemon) { described_class.instance }
  let(:tmp_dir) { Pathname.new(Dir.mktmpdir('reactive_view_test')) }
  let(:working_dir) { tmp_dir.join('.reactive_view') }

  before do
    # Create a minimal working directory
    FileUtils.mkdir_p(working_dir)

    # Configure to use the test working directory
    ReactiveView.configure do |config|
      config.daemon_port = 13_001 # Use non-standard port for tests
      config.daemon_max_restarts = 3
      config.daemon_restart_window = 10
      config.daemon_health_check_interval = 1
      config.daemon_health_check_ttl = 0.5
    end

    # Stub working_directory_absolute_path to return our test directory
    allow(ReactiveView.configuration).to receive(:working_directory_absolute_path).and_return(working_dir)

    # Reset the daemon state for each test
    reset_daemon_state
  end

  after do
    # Ensure daemon is stopped after each test
    begin
      daemon.stop
    rescue StandardError
      nil
    end

    # Clean up temp directory
    FileUtils.rm_rf(tmp_dir)
  end

  # Helper to reset daemon state between tests
  def reset_daemon_state
    daemon.instance_variable_set(:@pid, nil)
    daemon.instance_variable_set(:@status, :stopped)
    daemon.instance_variable_set(:@monitor_thread, nil)
    daemon.instance_variable_set(:@restart_count, 0)
    daemon.instance_variable_set(:@restart_window_start, nil)
    daemon.instance_variable_set(:@last_health_check_result, nil)
    daemon.instance_variable_set(:@last_health_check_time, nil)
  end

  describe '#initialize' do
    it 'starts with stopped status' do
      expect(daemon.status).to eq(:stopped)
    end

    it 'starts with nil pid' do
      expect(daemon.pid).to be_nil
    end
  end

  describe '#pid_file_path' do
    it 'returns path to daemon.pid in working directory' do
      expect(daemon.pid_file_path).to eq(working_dir.join('daemon.pid'))
    end
  end

  describe 'daemon command execution' do
    describe '#build_command' do
      it 'uses argv form for development mode' do
        allow(Rails).to receive(:env).and_return(Rails::Env.new('development'))

        expect(daemon.send(:build_command)).to eq(%w[npx reactiveview dev])
      end

      it 'uses argv form for production mode' do
        allow(Rails).to receive(:env).and_return(Rails::Env.new('production'))

        expect(daemon.send(:build_command)).to eq(%w[npx reactiveview start])
      end
    end

    describe '#spawn_daemon' do
      it 'spawns using argv without shell interpolation' do
        log_file = working_dir.join('daemon.log')

        allow(daemon).to receive(:build_command).and_return(%w[npx reactiveview dev])
        expect(daemon).to receive(:spawn).with(
          { 'PORT' => '13001' },
          'npx', 'reactiveview', 'dev',
          chdir: Rails.root.to_s,
          out: [log_file.to_s, 'a'],
          err: [log_file.to_s, 'a'],
          pgroup: true
        ).and_return(12_345)

        expect(daemon.send(:spawn_daemon, working_dir)).to eq(12_345)
      end
    end
  end

  describe '#health_check' do
    context 'when daemon is not running' do
      before do
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_raise(Faraday::ConnectionFailed)
      end

      it 'returns false' do
        expect(daemon.health_check).to be false
      end
    end

    context 'when daemon is running' do
      before do
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_return(status: 200, body: '')
      end

      it 'returns true' do
        expect(daemon.health_check).to be true
      end
    end

    context 'caching behavior' do
      before do
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_return(status: 200, body: '')
      end

      it 'caches health check results for TTL duration' do
        # First call should hit the network
        expect(daemon.health_check).to be true

        # Stub a failure for the second call
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_raise(Faraday::ConnectionFailed)

        # Should return cached result (still true)
        expect(daemon.health_check).to be true

        # Wait for TTL to expire
        sleep 0.6

        # Now should get the fresh (failing) result
        expect(daemon.health_check).to be false
      end
    end
  end

  describe '#within_restart_budget?' do
    it 'returns true when no restarts have occurred' do
      expect(daemon.within_restart_budget?).to be true
    end

    it 'returns true when under the max restart limit' do
      daemon.instance_variable_set(:@restart_count, 2)
      daemon.instance_variable_set(:@restart_window_start, daemon.send(:monotonic_time))

      expect(daemon.within_restart_budget?).to be true
    end

    it 'returns false when at the max restart limit' do
      daemon.instance_variable_set(:@restart_count, 3)
      daemon.instance_variable_set(:@restart_window_start, daemon.send(:monotonic_time))

      expect(daemon.within_restart_budget?).to be false
    end

    it 'resets budget when window expires' do
      daemon.instance_variable_set(:@restart_count, 3)
      # Set window start to 15 seconds ago (window is 10 seconds)
      daemon.instance_variable_set(:@restart_window_start, daemon.send(:monotonic_time) - 15)

      expect(daemon.within_restart_budget?).to be true
    end
  end

  describe '#running?' do
    context 'when pid is nil' do
      it 'returns false' do
        expect(daemon.running?).to be false
      end
    end

    context 'when process is alive and healthy' do
      before do
        daemon.instance_variable_set(:@pid, Process.pid)
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_return(status: 200, body: '')
      end

      it 'returns true' do
        expect(daemon.running?).to be true
      end
    end

    context 'when process is alive but unhealthy' do
      before do
        daemon.instance_variable_set(:@pid, Process.pid)
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_raise(Faraday::ConnectionFailed)
      end

      it 'returns false' do
        expect(daemon.running?).to be false
      end
    end
  end

  describe '#start' do
    before do
      allow(daemon).to receive(:resolve_development_daemon_port!).and_return(true)
    end

    context 'when working directory does not exist' do
      before do
        allow(ReactiveView.configuration).to receive(:working_directory_absolute_path)
          .and_return(Pathname.new('/nonexistent/path'))
      end

      it 'returns false' do
        expect(daemon.start).to be false
      end

      it 'logs an error' do
        expect(ReactiveView.logger).to receive(:error).at_least(:once)
        daemon.start
      end
    end

    context 'when daemon fails to become healthy' do
      before do
        # Stub spawn to return a fake PID
        allow(daemon).to receive(:spawn_daemon).and_return(99_999)

        # Make health checks always fail
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_raise(Faraday::ConnectionFailed)

        # Stub process_alive? to return true so we don't try to kill a real process
        allow(daemon).to receive(:process_alive?).and_return(true)

        # Stub Process methods for cleanup
        allow(Process).to receive(:kill)
        allow(Process).to receive(:wait)

        # Speed up startup timeout by stubbing sleep
        allow(daemon).to receive(:sleep)
      end

      it 'returns false' do
        expect(daemon.start).to be false
      end

      it 'sets status to failed' do
        daemon.start
        expect(daemon.status).to eq(:stopped) # stop_internal sets it to stopped
      end
    end

    context 'when daemon starts successfully' do
      before do
        # Stub spawn to return a fake PID
        allow(daemon).to receive(:spawn_daemon).and_return(12_345)

        # Make health check succeed
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_return(status: 200, body: '')

        # Don't actually start the monitoring thread
        allow(daemon).to receive(:start_monitoring)
      end

      it 'returns true' do
        expect(daemon.start).to be true
      end

      it 'sets status to running' do
        daemon.start
        expect(daemon.status).to eq(:running)
      end

      it 'stores the PID' do
        daemon.start
        expect(daemon.pid).to eq(12_345)
      end

      it 'writes a PID file' do
        daemon.start
        expect(daemon.pid_file_path).to exist
        expect(daemon.pid_file_path.read.strip).to eq('12345')
      end

      it 'starts monitoring' do
        expect(daemon).to receive(:start_monitoring)
        daemon.start
      end
    end

    context 'when daemon port cannot be resolved in development' do
      before do
        allow(daemon).to receive(:resolve_development_daemon_port!).and_return(false)
      end

      it 'returns false and does not spawn the daemon' do
        expect(daemon).not_to receive(:spawn_daemon)
        expect(daemon.start).to be false
      end
    end
  end

  describe '#resolve_development_daemon_port!' do
    before do
      allow(Rails).to receive(:env).and_return(Rails::Env.new('development'))
      allow(daemon).to receive(:local_daemon_host?).and_return(true)
      ReactiveView.configuration.daemon_port = 13_001
    end

    it 'returns true when configured port is available' do
      allow(daemon).to receive(:port_available?).with(13_001).and_return(true)

      expect(daemon.send(:resolve_development_daemon_port!)).to be true
      expect(ReactiveView.configuration.daemon_port).to eq(13_001)
    end

    it 'reclaims configured port by terminating stale ReactiveView process' do
      allow(daemon).to receive(:port_available?).with(13_001).and_return(false)
      allow(daemon).to receive(:reactive_view_listener_pid).with(13_001).and_return(44_444)
      allow(daemon).to receive(:terminate_process).with(44_444)
      allow(daemon).to receive(:wait_for_port_release).with(13_001).and_return(true)

      expect(daemon.send(:resolve_development_daemon_port!)).to be true
      expect(ReactiveView.configuration.daemon_port).to eq(13_001)
    end

    it 'switches to a fallback port when current port is occupied' do
      allow(daemon).to receive(:port_available?).with(13_001).and_return(false)
      allow(daemon).to receive(:reactive_view_listener_pid).with(13_001).and_return(nil)
      allow(daemon).to receive(:find_available_port).with(13_002).and_return(13_021)

      expect(daemon.send(:resolve_development_daemon_port!)).to be true
      expect(ReactiveView.configuration.daemon_port).to eq(13_021)
    end

    it 'returns false when no fallback port can be found' do
      allow(daemon).to receive(:port_available?).with(13_001).and_return(false)
      allow(daemon).to receive(:reactive_view_listener_pid).with(13_001).and_return(nil)
      allow(daemon).to receive(:find_available_port).with(13_002).and_return(nil)

      expect(daemon.send(:resolve_development_daemon_port!)).to be false
    end

    it 'skips resolution outside development' do
      allow(Rails).to receive(:env).and_return(Rails::Env.new('production'))

      expect(daemon.send(:resolve_development_daemon_port!)).to be true
    end

    it 'skips resolution for non-local daemon hosts' do
      allow(daemon).to receive(:local_daemon_host?).and_return(false)

      expect(daemon.send(:resolve_development_daemon_port!)).to be true
    end
  end

  describe '#stop' do
    context 'when daemon is running' do
      before do
        daemon.instance_variable_set(:@pid, 12_345)
        daemon.instance_variable_set(:@status, :running)

        # Create a PID file
        daemon.pid_file_path.write('12345')

        # Stub process operations
        allow(daemon).to receive(:process_alive?).and_return(true, false) # First check true, then false after TERM
        allow(Process).to receive(:kill)
        allow(Process).to receive(:wait)
      end

      it 'sends SIGTERM' do
        expect(Process).to receive(:kill).with('TERM', 12_345)
        daemon.stop
      end

      it 'sets status to stopped' do
        daemon.stop
        expect(daemon.status).to eq(:stopped)
      end

      it 'clears the PID' do
        daemon.stop
        expect(daemon.pid).to be_nil
      end

      it 'removes the PID file' do
        daemon.stop
        expect(daemon.pid_file_path).not_to exist
      end
    end

    context 'when daemon does not stop gracefully' do
      before do
        daemon.instance_variable_set(:@pid, 12_345)
        daemon.instance_variable_set(:@status, :running)

        # Stub process_alive? to always return true (daemon won't die)
        allow(daemon).to receive(:process_alive?).and_return(true)
        allow(Process).to receive(:kill)
        allow(Process).to receive(:wait)

        # Speed up the test by stubbing sleep
        allow(daemon).to receive(:sleep)
      end

      it 'sends SIGKILL after timeout' do
        expect(Process).to receive(:kill).with('TERM', 12_345)
        expect(Process).to receive(:kill).with('KILL', 12_345)
        daemon.stop
      end
    end

    context 'when daemon pid is the current process' do
      before do
        daemon.instance_variable_set(:@pid, Process.pid)
        daemon.instance_variable_set(:@status, :running)
      end

      it 'does not signal the current process' do
        expect(Process).not_to receive(:kill).with(anything, Process.pid)

        daemon.stop

        expect(daemon.pid).to be_nil
        expect(daemon.status).to eq(:stopped)
      end
    end
  end

  describe 'PID file cleanup' do
    context 'when stale PID file exists on start' do
      before do
        # Create a stale PID file with a fake PID
        daemon.pid_file_path.write('99998')

        # Stub spawn for the new daemon
        allow(daemon).to receive(:spawn_daemon).and_return(12_345)

        # Make health check succeed
        stub_request(:get, 'http://localhost:13001/api/render')
          .to_return(status: 200, body: '')

        allow(daemon).to receive(:start_monitoring)
      end

      context 'when stale process is not running' do
        before do
          # First call is for stale process check (returns false)
          # Subsequent calls are for new process
          allow(daemon).to receive(:process_alive?).with(99_998).and_return(false)
        end

        it 'removes the stale PID file and starts normally' do
          expect(daemon.start).to be true
          expect(daemon.pid).to eq(12_345)
        end
      end

      context 'when stale process is still running' do
        before do
          # Stub process_alive? for both stale and new processes
          allow(daemon).to receive(:process_alive?).and_return(false) # default
          allow(daemon).to receive(:process_alive?).with(99_998).and_return(true, false)
          allow(daemon).to receive(:process_alive?).with(12_345).and_return(true)
          allow(Process).to receive(:kill)
          allow(daemon).to receive(:sleep) # Speed up the test
        end

        it 'kills the stale process before starting' do
          expect(Process).to receive(:kill).with('TERM', 99_998)
          daemon.start
        end
      end
    end
  end

  describe 'exponential backoff' do
    it 'uses increasing delays when waiting for startup' do
      # Verify the delay pattern is correct
      expect(ReactiveView::Daemon::STARTUP_DELAYS).to eq([0.1, 0.2, 0.3, 0.5, 0.5, 1, 1, 2, 2, 4, 4])
    end

    it 'total startup timeout is around 16 seconds' do
      total = ReactiveView::Daemon::STARTUP_DELAYS.sum
      expect(total).to be_within(1).of(16)
    end
  end

  describe 'thread safety' do
    it 'uses mutex for start' do
      mutex = daemon.instance_variable_get(:@mutex)
      expect(mutex).to be_a(Mutex)
    end
  end
end
