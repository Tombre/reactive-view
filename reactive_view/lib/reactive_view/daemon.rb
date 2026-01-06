# frozen_string_literal: true

require 'singleton'

module ReactiveView
  # Manages the SolidStart daemon process.
  # Starts the daemon when Rails boots and stops it on shutdown.
  class Daemon
    include Singleton

    STARTUP_TIMEOUT = 30 # seconds
    HEALTH_CHECK_PATH = '/api/render'

    attr_reader :pid, :status

    def initialize
      @pid = nil
      @status = :stopped
      @mutex = Mutex.new
    end

    # Start the SolidStart daemon
    def start
      @mutex.synchronize do
        return if running?

        working_dir = ReactiveView.configuration.working_directory_absolute_path

        unless working_dir.exist?
          ReactiveView.logger.error "[ReactiveView] Working directory does not exist: #{working_dir}"
          ReactiveView.logger.error "[ReactiveView] Run 'rails reactive_view:setup' first"
          return false
        end

        ReactiveView.logger.info '[ReactiveView] Starting SolidStart daemon...'

        @status = :starting
        @pid = spawn_daemon(working_dir)

        if wait_for_startup
          @status = :running
          ReactiveView.logger.info "[ReactiveView] Daemon started (PID: #{@pid})"
          true
        else
          @status = :failed
          ReactiveView.logger.error "[ReactiveView] Daemon failed to start within #{STARTUP_TIMEOUT}s"
          stop
          false
        end
      end
    end

    # Stop the daemon
    def stop
      @mutex.synchronize do
        return unless @pid

        ReactiveView.logger.info "[ReactiveView] Stopping daemon (PID: #{@pid})..."

        begin
          # Send SIGTERM first
          Process.kill('TERM', @pid)

          # Wait up to 5 seconds for graceful shutdown
          5.times do
            break unless process_alive?(@pid)

            sleep 1
          end

          # Force kill if still running
          Process.kill('KILL', @pid) if process_alive?(@pid)

          Process.wait(@pid)
        rescue Errno::ESRCH, Errno::ECHILD
          # Process already gone
        end

        @pid = nil
        @status = :stopped
        ReactiveView.logger.info '[ReactiveView] Daemon stopped'
      end
    end

    # Check if daemon is running
    def running?
      return false unless @pid

      process_alive?(@pid) && health_check
    end

    # Check daemon health
    def health_check
      response = Faraday.get(health_check_url)
      response.success?
    rescue Faraday::Error
      false
    end

    # Restart the daemon
    def restart
      stop
      sleep 1
      start
    end

    private

    def spawn_daemon(working_dir)
      command = build_command

      # Spawn the process with output redirected
      log_file = working_dir.join('daemon.log')

      spawn(
        { 'PORT' => ReactiveView.configuration.daemon_port.to_s },
        command,
        chdir: working_dir.to_s,
        out: [log_file.to_s, 'a'],
        err: [log_file.to_s, 'a'],
        pgroup: true # Create new process group
      )
    end

    def build_command
      if Rails.env.production?
        'npm run start'
      else
        'npm run dev'
      end
    end

    def wait_for_startup
      STARTUP_TIMEOUT.times do
        return true if health_check

        sleep 1
      end

      false
    end

    def process_alive?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH, Errno::EPERM
      false
    end

    def health_check_url
      "#{ReactiveView.configuration.daemon_url}#{HEALTH_CHECK_PATH}"
    end
  end
end
