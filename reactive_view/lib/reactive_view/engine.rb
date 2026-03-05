# frozen_string_literal: true

module ReactiveView
  class Engine < ::Rails::Engine
    isolate_namespace ReactiveView

    config.reactive_view = ActiveSupport::OrderedOptions.new

    # Configure Zeitwerk ignores before autoloading starts.
    # Grouped route directories and *.loader.rb files are framework conventions,
    # not Ruby constant paths.
    initializer 'reactive_view.configure_autoloaders', before: :setup_main_autoloader do |app|
      pages_path = app.root.join('app/pages')

      ReactiveView::AutoloadIgnorer.ignore_pages_paths!(
        pages_path: pages_path,
        autoloaders: [Rails.autoloaders.main, Rails.autoloaders.once],
        logger: ReactiveView.logger
      )
    rescue StandardError => e
      # Raise error if scanning or configuration fails
      raise ReactiveView::ConfigurationError, "Failed to configure ReactiveView autoloader ignores: #{e.message}"
    end

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
  end
end
