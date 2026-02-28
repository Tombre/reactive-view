# frozen_string_literal: true

require 'singleton'

module ReactiveView
  # Manages the SolidStart daemon process.
  #
  # Features:
  # - Automatic startup with Rails boot
  # - Graceful shutdown with SIGTERM -> SIGKILL escalation
  # - Health monitoring with automatic restart on failure
  # - Bounded restart attempts to prevent infinite loops
  # - PID file support for crash recovery
  # - Health check caching to reduce HTTP overhead
  # - Exponential backoff for startup polling
  #
  # @example Basic usage
  #   ReactiveView::Daemon.instance.start
  #   ReactiveView::Daemon.instance.running? # => true
  #   ReactiveView::Daemon.instance.stop
  #
  # @example Configuration
  #   ReactiveView.configure do |config|
  #     config.daemon_max_restarts = 5          # Max restarts per window
  #     config.daemon_restart_window = 60       # Window in seconds
  #     config.daemon_health_check_interval = 5 # Health check interval
  #     config.daemon_health_check_ttl = 2      # Cache health check results
  #   end
  #
  class Daemon
    include Singleton

    # Exponential backoff delays for startup polling (in seconds)
    # Total wait time: ~16 seconds before giving up
    STARTUP_DELAYS = [0.1, 0.2, 0.3, 0.5, 0.5, 1, 1, 2, 2, 4, 4].freeze

    HEALTH_CHECK_PATH = '/api/render'

    attr_reader :pid, :status

    def initialize
      @pid = nil
      @status = :stopped
      @mutex = Mutex.new
      @monitor_thread = nil
      @restart_count = 0
      @restart_window_start = nil
      @last_health_check_result = nil
      @last_health_check_time = nil
    end

    # Start the SolidStart daemon.
    #
    # This method:
    # 1. Cleans up any stale daemon from a previous crash
    # 2. Spawns the daemon process
    # 3. Waits for it to become healthy (with exponential backoff)
    # 4. Starts the health monitoring thread
    #
    # @return [Boolean] true if daemon started successfully, false otherwise
    def start
      @mutex.synchronize do
        return true if @status == :running && health_check_internal

        cleanup_stale_daemon
        working_dir = ReactiveView.configuration.working_directory_absolute_path

        unless working_dir.exist?
          ReactiveView.logger.error "[ReactiveView] Working directory does not exist: #{working_dir}"
          ReactiveView.logger.error "[ReactiveView] Run 'rails reactive_view:setup' first"
          return false
        end

        ReactiveView.logger.info '[ReactiveView] Starting SolidStart daemon...'

        @status = :starting
        @pid = spawn_daemon(working_dir)
        write_pid_file

        if wait_for_startup
          @status = :running
          reset_restart_budget
          ReactiveView.logger.info "[ReactiveView] Daemon started (PID: #{@pid})"
          start_monitoring
          true
        else
          @status = :failed
          ReactiveView.logger.error '[ReactiveView] Daemon failed to start within timeout'
          stop_internal
          false
        end
      end
    end

    # Stop the daemon gracefully.
    #
    # Sends SIGTERM first, waits up to 5 seconds, then SIGKILL if needed.
    #
    # @return [void]
    def stop
      @mutex.synchronize do
        stop_monitoring_internal
        stop_internal
      end
    end

    # Check if daemon is running and healthy.
    #
    # Uses cached health check result if within TTL to reduce HTTP overhead.
    #
    # @return [Boolean] true if daemon is running and healthy
    def running?
      return false unless @pid
      return false unless process_alive?(@pid)

      health_check
    end

    # Perform a health check against the daemon.
    #
    # Results are cached for `daemon_health_check_ttl` seconds.
    #
    # @return [Boolean] true if daemon responds successfully
    def health_check
      now = monotonic_time
      ttl = ReactiveView.configuration.daemon_health_check_ttl

      return @last_health_check_result if @last_health_check_time && (now - @last_health_check_time) < ttl

      result = health_check_internal
      @last_health_check_result = result
      @last_health_check_time = now
      result
    end

    # Restart the daemon.
    #
    # @return [Boolean] true if restart was successful
    def restart
      @mutex.synchronize do
        stop_monitoring_internal
        stop_internal
        sleep 0.5
      end
      start
    end

    # Check if we're within the restart budget.
    #
    # @return [Boolean] true if more restarts are allowed
    def within_restart_budget?
      max_restarts = ReactiveView.configuration.daemon_max_restarts
      window = ReactiveView.configuration.daemon_restart_window

      # If window has expired, we're within budget (will reset on next restart)
      return true if @restart_window_start && (monotonic_time - @restart_window_start) > window

      @restart_count < max_restarts
    end

    # Path to the PID file.
    #
    # @return [Pathname]
    def pid_file_path
      ReactiveView.configuration.working_directory_absolute_path.join('daemon.pid')
    end

    private

    # Spawn the daemon process with output redirected to log file.
    #
    # @param working_dir [Pathname] The working directory
    # @return [Integer] The PID of the spawned process
    def spawn_daemon(working_dir)
      command = build_command
      log_file = working_dir.join('daemon.log')

      spawn(
        { 'PORT' => ReactiveView.configuration.daemon_port.to_s },
        *command,
        chdir: working_dir.to_s,
        out: [log_file.to_s, 'a'],
        err: [log_file.to_s, 'a'],
        pgroup: true # Create new process group for clean shutdown
      )
    end

    # Build the command to start the daemon.
    #
    # @return [Array<String>]
    def build_command
      if Rails.env.production?
        %w[npm run start]
      else
        %w[npm run dev]
      end
    end

    # Wait for the daemon to become healthy using exponential backoff.
    #
    # @return [Boolean] true if daemon became healthy, false if timeout
    def wait_for_startup
      STARTUP_DELAYS.each do |delay|
        return true if health_check_internal

        sleep delay
      end

      false
    end

    # Internal health check without caching.
    #
    # @return [Boolean]
    def health_check_internal
      response = Faraday.get(health_check_url)
      response.success?
    rescue Faraday::Error
      false
    end

    # Check if a process is alive.
    #
    # @param pid [Integer] Process ID to check
    # @return [Boolean]
    def process_alive?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH, Errno::EPERM
      false
    end

    # Internal stop without mutex (for use when mutex is already held).
    #
    # @return [void]
    def stop_internal
      return unless @pid

      ReactiveView.logger.info "[ReactiveView] Stopping daemon (PID: #{@pid})..."

      begin
        # Send SIGTERM first for graceful shutdown
        Process.kill('TERM', @pid)

        # Wait up to 5 seconds for graceful shutdown
        5.times do
          break unless process_alive?(@pid)

          sleep 1
        end

        # Force kill if still running
        if process_alive?(@pid)
          ReactiveView.logger.warn '[ReactiveView] Daemon did not stop gracefully, sending SIGKILL'
          Process.kill('KILL', @pid)
        end

        Process.wait(@pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already gone, that's fine
      end

      @pid = nil
      @status = :stopped
      remove_pid_file
      invalidate_health_cache
      ReactiveView.logger.info '[ReactiveView] Daemon stopped'
    end

    # Start the health monitoring thread.
    #
    # The monitor checks health every `daemon_health_check_interval` seconds.
    # If the daemon is unhealthy and within restart budget, it will restart.
    # If restart budget is exhausted, monitoring stops and status is set to :failed.
    #
    # @return [void]
    def start_monitoring
      return if @monitor_thread&.alive?

      @monitor_thread = Thread.new do
        Thread.current.name = 'reactive_view_daemon_monitor'
        monitor_loop
      end
    end

    # Internal method to stop monitoring without mutex.
    #
    # @return [void]
    def stop_monitoring_internal
      return unless @monitor_thread

      @monitor_thread.kill if @monitor_thread.alive?
      @monitor_thread = nil
    end

    # The main monitoring loop.
    #
    # @return [void]
    def monitor_loop
      interval = ReactiveView.configuration.daemon_health_check_interval

      loop do
        sleep interval

        # Only check if we think we're running
        next unless @status == :running

        # Skip if health check passes
        next if health_check_internal

        ReactiveView.logger.warn '[ReactiveView] Daemon health check failed'
        invalidate_health_cache

        if within_restart_budget?
          record_restart
          max = ReactiveView.configuration.daemon_max_restarts
          ReactiveView.logger.info "[ReactiveView] Attempting restart (#{@restart_count}/#{max})"
          restart_from_monitor
        else
          ReactiveView.logger.error '[ReactiveView] Restart budget exhausted. Manual intervention required.'
          @status = :failed
          break
        end
      end
    rescue StandardError => e
      ReactiveView.logger.error "[ReactiveView] Monitor thread error: #{e.message}"
    end

    # Restart from within the monitor thread (doesn't try to stop monitoring).
    #
    # @return [void]
    def restart_from_monitor
      @mutex.synchronize do
        stop_internal
        sleep 0.5
      end

      # Start without going through the public method to avoid monitor thread issues
      @mutex.synchronize do
        cleanup_stale_daemon
        working_dir = ReactiveView.configuration.working_directory_absolute_path

        unless working_dir.exist?
          ReactiveView.logger.error "[ReactiveView] Working directory missing: #{working_dir}"
          @status = :failed
          return
        end

        @status = :starting
        @pid = spawn_daemon(working_dir)
        write_pid_file

        if wait_for_startup
          @status = :running
          ReactiveView.logger.info "[ReactiveView] Daemon restarted successfully (PID: #{@pid})"
        else
          @status = :failed
          ReactiveView.logger.error '[ReactiveView] Daemon restart failed'
        end
      end
    end

    # Record a restart attempt and manage the restart window.
    #
    # @return [void]
    def record_restart
      window = ReactiveView.configuration.daemon_restart_window
      now = monotonic_time

      # Reset window if it has expired
      if @restart_window_start.nil? || (now - @restart_window_start) > window
        @restart_window_start = now
        @restart_count = 0
      end

      @restart_count += 1
    end

    # Reset the restart budget after a successful startup.
    #
    # @return [void]
    def reset_restart_budget
      @restart_count = 0
      @restart_window_start = nil
    end

    # Clean up any stale daemon process from a previous crash.
    #
    # Reads the PID file and terminates the process if it's still running.
    #
    # @return [void]
    def cleanup_stale_daemon
      return unless pid_file_path.exist?

      old_pid = pid_file_path.read.strip.to_i
      return if old_pid <= 0

      if process_alive?(old_pid)
        ReactiveView.logger.warn "[ReactiveView] Found stale daemon (PID: #{old_pid}), terminating..."
        begin
          Process.kill('TERM', old_pid)
          sleep 1
          Process.kill('KILL', old_pid) if process_alive?(old_pid)
        rescue Errno::ESRCH, Errno::EPERM
          # Process already gone or we don't have permission
        end
      end

      remove_pid_file
    end

    # Write the current PID to the PID file.
    #
    # @return [void]
    def write_pid_file
      return unless @pid

      pid_file_path.write(@pid.to_s)
    rescue SystemCallError => e
      ReactiveView.logger.warn "[ReactiveView] Failed to write PID file: #{e.message}"
    end

    # Remove the PID file.
    #
    # @return [void]
    def remove_pid_file
      pid_file_path.delete if pid_file_path.exist?
    rescue SystemCallError => e
      ReactiveView.logger.warn "[ReactiveView] Failed to remove PID file: #{e.message}"
    end

    # Invalidate the cached health check result.
    #
    # @return [void]
    def invalidate_health_cache
      @last_health_check_result = nil
      @last_health_check_time = nil
    end

    # Get monotonic time for timing operations.
    #
    # @return [Float] Current monotonic time in seconds
    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Build the health check URL.
    #
    # @return [String]
    def health_check_url
      "#{ReactiveView.configuration.daemon_url}#{HEALTH_CHECK_PATH}"
    end
  end
end
