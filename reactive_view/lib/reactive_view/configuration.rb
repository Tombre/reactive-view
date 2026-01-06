# frozen_string_literal: true

module ReactiveView
  class Configuration
    # SolidStart daemon settings
    attr_accessor :daemon_host, :daemon_port, :daemon_timeout

    # Whether to automatically start the SolidStart daemon with Rails
    attr_accessor :auto_start_daemon

    # Whether the daemon is managed externally (e.g., in production on a different server)
    attr_accessor :external_daemon

    # Path to the pages directory (relative to Rails.root)
    attr_accessor :pages_path

    # Path to the SolidStart working directory (relative to Rails.root)
    attr_accessor :working_directory

    # Enable response validation in development/test
    attr_accessor :validate_responses

    # Rails base URL for SolidStart to call back
    attr_accessor :rails_base_url

    def initialize
      @daemon_host = 'localhost'
      @daemon_port = 3001
      @daemon_timeout = 30 # seconds
      @auto_start_daemon = true
      @external_daemon = false
      @pages_path = 'app/pages'
      @working_directory = '.reactive_view'
      @validate_responses = true
      @rails_base_url = nil # Auto-detected from request if nil
    end

    # Determines if daemon should be auto-started based on configuration and environment
    def should_auto_start_daemon?
      auto_start_daemon && !external_daemon
    end

    # Determines if response validation should occur
    def should_validate_responses?
      validate_responses && (Rails.env.development? || Rails.env.test?)
    end

    # Full URL to the SolidStart daemon
    def daemon_url
      "http://#{daemon_host}:#{daemon_port}"
    end

    # Absolute path to the pages directory
    def pages_absolute_path
      Rails.root.join(pages_path)
    end

    # Absolute path to the working directory
    def working_directory_absolute_path
      Rails.root.join(working_directory)
    end
  end
end
