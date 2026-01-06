# frozen_string_literal: true

ReactiveView.configure do |config|
  # SolidStart daemon settings
  config.daemon_host = 'localhost'
  config.daemon_port = 3001
  config.daemon_timeout = 30

  # Don't auto-start daemon - we'll use Procfile.dev instead
  config.auto_start_daemon = false

  # Enable response validation in development/test
  config.validate_responses = true

  # Path settings
  config.pages_path = 'app/pages'
  config.working_directory = '.reactive_view'
end
