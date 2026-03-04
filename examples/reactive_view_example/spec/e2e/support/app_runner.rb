require 'fileutils'
require 'net/http'
require 'socket'
require 'timeout'

module E2E
  class AppRunner
    APP_HOST = '127.0.0.1'.freeze
    DAEMON_HOST = 'localhost'.freeze

    attr_reader :app_port, :daemon_port

    def initialize(root:)
      @root = root
      @rails_pid = nil
      @daemon_pid = nil
      @app_port = pick_port
      @daemon_port = nil
    end

    def start
      if external_app?
        @app_port = 3000
        @daemon_port = 3001
        return
      end

      FileUtils.mkdir_p(log_dir)
      daemon_log = log_dir.join('daemon.log')

      @daemon_port = pick_port(default_port: 3001, host: DAEMON_HOST)

      @daemon_pid = spawn_process(
        { 'PORT' => daemon_port.to_s },
        'npx reactiveview dev',
        daemon_log
      )

      wait_for_port_open(DAEMON_HOST, daemon_port, daemon_log)

      @rails_pid = spawn_process(
        {
          'CI' => nil,
          'RAILS_ENV' => 'test',
          'REACTIVE_VIEW_DAEMON_HOST' => DAEMON_HOST,
          'REACTIVE_VIEW_DAEMON_PORT' => daemon_port.to_s
        },
        "bundle exec rails server -b #{APP_HOST} -p #{app_port}",
        log_dir.join('rails.log')
      )

      wait_for_http("http://#{APP_HOST}:#{app_port}/up")
    end

    def stop
      [@daemon_pid, @rails_pid].compact.each do |pid|
        terminate_process_group(pid)
      end
    end

    private

    def external_app?
      ENV['E2E_EXTERNAL_APP'] == '1'
    end

    def log_dir
      @root.join('tmp/e2e')
    end

    def spawn_process(env, command, log_file)
      log = File.open(log_file, 'w')
      Process.spawn(env, command, chdir: @root.to_s, out: log, err: log, pgroup: true)
    end

    def terminate_process_group(pid)
      Process.kill('TERM', -pid)
      Timeout.timeout(10) { Process.wait(pid) }
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    rescue Timeout::Error
      Process.kill('KILL', -pid)
      Process.wait(pid)
    end

    def wait_for_http(url, timeout: 60)
      uri = URI(url)

      Timeout.timeout(timeout) do
        loop do
          response = Net::HTTP.get_response(uri)
          return if response.is_a?(Net::HTTPSuccess)
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          nil
        ensure
          sleep 0.5
        end
      end
    end

    def wait_for_port_open(host, port, log_file, timeout: 120)
      Timeout.timeout(timeout) do
        loop do
          raise daemon_startup_error(log_file) if daemon_process_exited?

          begin
            socket = TCPSocket.new(host, port)
            socket.close
            return
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
            nil
          end

          sleep 0.5
        end
      end
    end

    def daemon_process_exited?
      return false unless @daemon_pid

      _pid, status = Process.wait2(@daemon_pid, Process::WNOHANG)
      return false unless status

      @daemon_pid = nil
      true
    rescue Errno::ECHILD
      @daemon_pid = nil
      true
    end

    def daemon_startup_error(log_file)
      output = File.exist?(log_file) ? File.read(log_file).strip : ''
      message = 'ReactiveView daemon exited before reporting its port'
      return message if output.empty?

      "#{message}. Output:\n#{output}"
    end

    def pick_port(default_port: nil, host: APP_HOST)
      return default_port if default_port && port_available?(default_port, host)

      server = TCPServer.new(host, 0)
      server.addr[1]
    ensure
      server&.close
    end

    def port_available?(port, host)
      server = TCPServer.new(host, port)
      true
    rescue Errno::EADDRINUSE
      false
    ensure
      server&.close
    end
  end
end
