# frozen_string_literal: true

ReactiveView.configure do |config|
  # SolidStart daemon settings
  config.daemon_host = ENV.fetch('REACTIVE_VIEW_DAEMON_HOST', 'localhost')
  config.daemon_port = ENV.fetch('REACTIVE_VIEW_DAEMON_PORT', 3001).to_i
  config.daemon_timeout = 30

  # Auto-start daemon in development for single-command startup
  config.auto_start_daemon = Rails.env.development?

  # Keep production compatible with standalone/external daemon deployments
  config.external_daemon = Rails.env.production?

  # Enable response validation in development/test
  config.validate_responses = true

  # Path settings
  config.pages_path = 'app/pages'
  config.working_directory = '.reactive_view'
end
