# frozen_string_literal: true

module ReactiveView
  class Engine < ::Rails::Engine
    isolate_namespace ReactiveView

    config.reactive_view = ActiveSupport::OrderedOptions.new

    # Insert the dev proxy middleware in development to forward asset requests to Vinxi
    initializer 'reactive_view.dev_proxy', before: :build_middleware_stack do |app|
      app.middleware.insert_before ActionDispatch::Static, ReactiveView::DevProxy if Rails.env.development?
    end

    initializer 'reactive_view.configuration' do |app|
      # Allow configuration via Rails config
      app.config.reactive_view.each do |key, value|
        ReactiveView.configuration.public_send("#{key}=", value) if ReactiveView.configuration.respond_to?("#{key}=")
      end
    end

    initializer 'reactive_view.load_loaders', before: :load_config_initializers do |app|
      # Load all loader files from app/pages
      app.config.after_initialize do
        ReactiveView::LoaderRegistry.load_all
      end
    end

    initializer 'reactive_view.draw_routes', after: :add_routing_paths do |app|
      # Prepend our routes so they can be caught before other routes
      app.routes.prepend do
        ReactiveView::Router.draw(self)
      end
    end

    initializer 'reactive_view.setup_file_sync' do |app|
      app.config.after_initialize do
        # File sync should ALWAYS run in development, regardless of daemon startup mode.
        # This ensures TSX files are synced to the working directory and changes are
        # detected even when the daemon is managed externally (e.g., via Procfile).
        next unless Rails.env.development?

        # Initial sync of TSX files
        ReactiveView::FileSync.sync_all

        # Start file watcher to detect changes
        ReactiveView::FileSync.start_watching
      end
    end

    initializer 'reactive_view.start_daemon' do |app|
      app.config.after_initialize do
        next unless ReactiveView.configuration.should_auto_start_daemon?

        ReactiveView::Daemon.instance.start
      end
    end

    # Shutdown daemon when Rails stops
    config.after_initialize do
      at_exit do
        ReactiveView::Daemon.instance.stop if ReactiveView.configuration.should_auto_start_daemon?
        ReactiveView::FileSync.stop_watching
      end
    end
  end
end
