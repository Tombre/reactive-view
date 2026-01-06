# frozen_string_literal: true

module ReactiveView
  # Base controller for handling ReactiveView page requests.
  # Subclass this in your app/pages/*.loader.rb files to provide data to your pages.
  #
  # @example Basic loader with data
  #   # app/pages/users/[id].loader.rb
  #   class Pages::Users::IdLoader < ReactiveView::Loader
  #     loader_sig do
  #       param :id, ReactiveView::Types::Integer
  #       param :name, ReactiveView::Types::String
  #     end
  #
  #     def load
  #       { id: user.id, name: user.name }
  #     end
  #
  #     private
  #
  #     def user
  #       @user ||= User.find(params[:id])
  #     end
  #   end
  #
  # @example Loader with authentication
  #   class Pages::Admin::DashboardLoader < ReactiveView::Loader
  #     before_action :authenticate_admin!
  #
  #     loader_sig do
  #       param :stats, ReactiveView::Types::Hash
  #     end
  #
  #     def load
  #       { stats: AdminStats.current }
  #     end
  #
  #     private
  #
  #     def authenticate_admin!
  #       redirect_to login_path unless current_user&.admin?
  #     end
  #   end
  #
  class Loader < ActionController::Base
    # Store the type signature for this loader
    class_attribute :_loader_sig, default: nil

    class << self
      # Define the type signature for this loader's data
      # Used for TypeScript type generation and runtime validation
      #
      # @yield Block defining the parameters
      def loader_sig(&block)
        builder = Types::SignatureBuilder.new(&block)
        self._loader_sig = builder.build
      end
    end

    # Main action - called when the route is hit
    # Handles auth (via before_actions), then delegates to SolidStart for rendering
    def call
      # Determine the loader path from the request
      loader_path = extract_loader_path

      # Determine Rails base URL for callbacks
      rails_base_url = ReactiveView.configuration.rails_base_url || request.base_url

      # Ask SolidStart to render the page
      # Forward cookies so SolidStart can pass them back for authenticated loader requests
      html = renderer.render(
        path: request.fullpath,
        loader_path: loader_path,
        rails_base_url: rails_base_url,
        cookies: request.headers['Cookie']
      )

      render html: html.html_safe, layout: false
    rescue ReactiveView::DaemonUnavailableError => e
      handle_daemon_error(e)
    rescue ReactiveView::RenderError => e
      handle_render_error(e)
    end

    # Override in subclasses to provide data to your pages
    # Called by LoaderDataController when SolidStart requests data
    #
    # @return [Hash] Data to pass to the page component
    def load
      {}
    end

    private

    def renderer
      @renderer ||= ReactiveView::Renderer.new
    end

    # Extract the loader path from the request
    # This maps the URL to the corresponding loader file path
    def extract_loader_path
      # The router sets this in params
      params[:reactive_view_loader_path] || path_from_url
    end

    def path_from_url
      # Convert URL path to loader path
      # /users/123 -> users/[id] (based on route params)
      path = request.path.sub(%r{^/}, '')
      return 'index' if path.blank?

      # Replace dynamic segments with their parameter names
      route_params = request.path_parameters.except(:controller, :action, :reactive_view_loader_path)

      route_params.each do |key, value|
        path = path.gsub(value.to_s, "[#{key}]")
      end

      path
    end

    def handle_daemon_error(error)
      ReactiveView.logger.error "[ReactiveView] Daemon unavailable: #{error.message}"

      if Rails.env.development?
        render html: daemon_error_html(error), status: :service_unavailable, layout: false
      else
        render plain: 'Service temporarily unavailable', status: :service_unavailable
      end
    end

    def handle_render_error(error)
      ReactiveView.logger.error "[ReactiveView] Render error: #{error.message}"

      raise error unless Rails.env.development?

      render html: render_error_html(error), status: :internal_server_error, layout: false

      # Let Rails error handling take over
    end

    def daemon_error_html(error)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>ReactiveView - Daemon Unavailable</title>
          <style>
            body { font-family: system-ui, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
            h1 { color: #e53e3e; }
            pre { background: #f7f7f7; padding: 20px; overflow-x: auto; border-radius: 8px; }
            .hint { background: #fffbeb; border: 1px solid #fbbf24; padding: 16px; border-radius: 8px; margin-top: 20px; }
          </style>
        </head>
        <body>
          <h1>ReactiveView Daemon Unavailable</h1>
          <p>The SolidStart rendering daemon is not responding.</p>
          <pre>#{ERB::Util.html_escape(error.message)}</pre>
          <div class="hint">
            <strong>Hint:</strong> Make sure the daemon is running. You can start it manually with:
            <pre>cd #{ReactiveView.configuration.working_directory} && npm run dev</pre>
            Or ensure <code>auto_start_daemon</code> is enabled in your ReactiveView configuration.
          </div>
        </body>
        </html>
      HTML
    end

    def render_error_html(error)
      <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>ReactiveView - Render Error</title>
          <style>
            body { font-family: system-ui, sans-serif; padding: 40px; max-width: 800px; margin: 0 auto; }
            h1 { color: #e53e3e; }
            pre { background: #f7f7f7; padding: 20px; overflow-x: auto; border-radius: 8px; }
          </style>
        </head>
        <body>
          <h1>ReactiveView Render Error</h1>
          <p>An error occurred while rendering the page.</p>
          <pre>#{ERB::Util.html_escape(error.message)}</pre>
        </body>
        </html>
      HTML
    end
  end
end
