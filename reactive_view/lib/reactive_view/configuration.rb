# frozen_string_literal: true

module ReactiveView
  class Configuration
    # SolidStart daemon settings
    attr_accessor :daemon_host, :daemon_port, :daemon_timeout

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
      @pages_path = 'app/pages'
      @working_directory = '.reactive_view'
      @validate_responses = true
      @rails_base_url = nil # Auto-detected from request if nil
    end

    # Set the daemon port with validation
    #
    # @param value [Integer] Port number (must be positive)
    # @raise [ArgumentError] if port is not a positive integer
    def daemon_port=(value)
      unless value.is_a?(Integer) && value.positive?
        raise ArgumentError, "daemon_port must be a positive integer, got: #{value.inspect}"
      end

      @daemon_port = value
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
