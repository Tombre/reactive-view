# frozen_string_literal: true

ReactiveView.configure do |config|
  # SolidStart daemon settings
  # The daemon runs on a separate port and handles SSR rendering
  config.daemon_host = 'localhost'
  config.daemon_port = 3001

  # How long to wait for the daemon to respond (seconds)
  config.daemon_timeout = 30

  # Automatically start the SolidStart daemon when Rails boots
  # Set to false if you want to manage the daemon separately
  config.auto_start_daemon = Rails.env.development?

  # Set to true if the daemon is running on a different server
  # (e.g., in production with separate frontend/backend servers)
  config.external_daemon = Rails.env.production?

  # Path to your pages directory (relative to Rails.root)
  config.pages_path = 'app/pages'

  # Path to the SolidStart working directory (relative to Rails.root)
  config.working_directory = '.reactive_view'

  # Enable response validation against loader_sig in development/test
  # This helps catch type mismatches early
  config.validate_responses = true

  # Rails base URL for SolidStart to call back
  # Leave nil to auto-detect from the request
  # config.rails_base_url = "http://localhost:3000"
end

# Enable caching in development for ReactiveView request tokens
# This is required for the token-based communication between Rails and SolidStart
#
# If you haven't already, run:
#   rails dev:cache
#
# Or add this to config/environments/development.rb:
#   config.cache_store = :memory_store
