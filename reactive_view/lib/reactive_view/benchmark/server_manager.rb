# frozen_string_literal: true

require 'net/http'
require 'timeout'

module ReactiveView
  module Benchmark
    # Manages Rails server and SolidStart daemon lifecycle for benchmarks.
    class ServerManager
      STARTUP_TIMEOUT = 60 # seconds
      HEALTH_CHECK_INTERVAL = 0.5 # seconds
      SHUTDOWN_TIMEOUT = 10 # seconds

      attr_reader :rails_port, :daemon_port, :mode

      # @param rails_port [Integer] Port for Rails server
      # @param daemon_port [Integer] Port for SolidStart daemon
      # @param mode [Symbol] :development or :production
      # @param working_directory [Pathname, String] Path to .reactive_view directory
      def initialize(rails_port: 3000, daemon_port: 3001, mode: :production, working_directory: nil)
        @rails_port = rails_port
        @daemon_port = daemon_port
        @mode = mode
        @working_directory = working_directory || ReactiveView.configuration.working_directory_absolute_path
        @rails_pid = nil
        @daemon_pid = nil
        @output_buffer = []
      end

      # Start both Rails server and daemon
      # @return [void]
      def start_all
        ensure_production_build! if @mode == :production
        start_daemon
        start_rails
      end

      # Stop both processes
      # @return [void]
      def stop_all
        stop_rails
        stop_daemon
      end

      # Check if Rails server is responding
      # @return [Boolean]
      def rails_running?
        check_health(rails_url + '/up')
      end

      # Check if daemon is responding
      # @return [Boolean]
      def daemon_running?
        check_health(daemon_url + '/api/render')
      end

      # @return [String] Rails base URL
      def rails_url
        "http://localhost:#{@rails_port}"
      end

      # @return [String] Daemon base URL
      def daemon_url
        "http://localhost:#{@daemon_port}"
      end

      # Ensure production build exists, build if necessary
      # @return [void]
      def ensure_production_build!
        output_dir = File.join(@working_directory, '.output')

        return if File.directory?(output_dir)

        log 'Production build not found, building...'
        build_production!
      end

      private

      def start_rails
        return if rails_running?

        log "Starting Rails server on port #{@rails_port} (#{@mode} mode)..."

        env = {
          'RAILS_ENV' => @mode.to_s,
          'PORT' => @rails_port.to_s,
          'RAILS_LOG_TO_STDOUT' => 'false'
        }

        @rails_pid = Process.spawn(
          env,
          'bin/rails', 'server', '-p', @rails_port.to_s, '-b', '127.0.0.1',
          chdir: Rails.root.to_s,
          out: File::NULL,
          err: File::NULL
        )

        wait_for_server('Rails', rails_url + '/up')
        log "Rails server started (PID: #{@rails_pid})"
      end

      def stop_rails
        return unless @rails_pid

        log 'Stopping Rails server...'
        graceful_kill(@rails_pid, 'Rails')
        @rails_pid = nil
      end

      def start_daemon
        return if daemon_running?

        log "Starting SolidStart daemon on port #{@daemon_port} (#{@mode} mode)..."

        command = daemon_command

        @daemon_pid = Process.spawn(
          command,
          chdir: @working_directory.to_s,
          out: File::NULL,
          err: File::NULL
        )

        wait_for_server('Daemon', daemon_url + '/api/render')
        log "SolidStart daemon started (PID: #{@daemon_pid})"
      end

      def stop_daemon
        return unless @daemon_pid

        log 'Stopping SolidStart daemon...'
        graceful_kill(@daemon_pid, 'Daemon')
        @daemon_pid = nil
      end

      def daemon_command
        if @mode == :production
          'npm run start'
        else
          "npm run dev -- --port #{@daemon_port}"
        end
      end

      def build_production!
        log 'Running production build...'

        Dir.chdir(@working_directory.to_s) do
          unless system('npm run build', out: File::NULL, err: File::NULL)
            raise BenchmarkError, "Production build failed. Run 'npm run build' in #{@working_directory} to see errors."
          end
        end

        log 'Production build complete'
      end

      def wait_for_server(name, health_url)
        deadline = Time.now + STARTUP_TIMEOUT

        loop do
          return true if check_health(health_url)

          raise BenchmarkError, "#{name} failed to start within #{STARTUP_TIMEOUT} seconds" if Time.now > deadline

          sleep HEALTH_CHECK_INTERVAL
        end
      end

      def check_health(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 2
        http.read_timeout = 2

        response = http.get(uri.path)
        response.is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, Net::OpenTimeout, Net::ReadTimeout, SocketError
        false
      end

      def graceful_kill(pid, name)
        return unless pid

        # First try SIGTERM
        Process.kill('TERM', pid)

        # Wait for graceful shutdown
        deadline = Time.now + SHUTDOWN_TIMEOUT

        loop do
          # Check if process is still running
          Process.kill(0, pid)

          if Time.now > deadline
            log "#{name} did not stop gracefully, sending SIGKILL..."
            Process.kill('KILL', pid)
            break
          end

          sleep 0.1
        rescue Errno::ESRCH
          # Process is gone
          break
        end

        # Clean up zombie process
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Process already gone or already reaped
      end

      def log(message)
        ReactiveView.logger.info "[ServerManager] #{message}"
        @output_buffer << "[#{Time.now.strftime('%H:%M:%S')}] #{message}"
      end
    end
  end
end
