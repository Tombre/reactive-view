# frozen_string_literal: true

module ReactiveView
  # Base controller for handling ReactiveView page requests.
  # Subclass this in your app/pages/*.loader.rb files to provide data to your pages.
  #
  # @example Basic loader with data
  #   # app/pages/users/[id].loader.rb
  #   class Pages::Users::IdLoader < ReactiveView::Loader
  #     shape :load do
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
  #     shape :load do
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
    # Store the type shapes for loader methods
    # Supports multiple methods like :load, :mutate, etc.
    class_attribute :_method_shapes, default: {}

    class << self
      # Define the type shape for a loader method
      # Used for TypeScript type generation and runtime validation
      #
      # @param method_name [Symbol] The method to define the shape for (defaults to :load)
      # @yield Block defining the parameters
      #
      # @example Define a load shape
      #   shape :load do
      #     param :id, ReactiveView::Types::Integer
      #     param :name, ReactiveView::Types::String
      #   end
      #
      # @example Using default method (:load)
      #   shape do
      #     param :users, ReactiveView::Types::Array[...]
      #   end
      #
      # @example Future: Define a mutate shape
      #   shape :mutate do
      #     param :name, ReactiveView::Types::String
      #     param :email, ReactiveView::Types::String
      #   end
      def shape(method_name = :load, &block)
        builder = Types::SignatureBuilder.new(&block)
        self._method_shapes = _method_shapes.merge(method_name => builder.build)
      end

      # Internal helper to access the :load shape
      # Maintains compatibility with existing code that accesses _loader_sig
      #
      # @return [Dry::Types::Type, nil] The load method's type schema
      def _loader_sig
        _method_shapes[:load]
      end
    end

    # Renders the page via the SolidStart daemon.
    #
    # This is the main controller action that:
    # 1. Runs any before_action callbacks (authentication, authorization, etc.)
    # 2. Forwards the request to the SolidStart daemon for SSR
    # 3. Returns the rendered HTML to the browser
    #
    # The daemon calls back to Rails to fetch loader data via LoaderDataController.
    #
    # @return [void] Renders HTML response directly
    # @raise [ReactiveView::DaemonUnavailableError] if the SolidStart daemon is not running
    # @raise [ReactiveView::RenderError] if SSR rendering fails
    #
    # @example In routes, this is called automatically:
    #   # The Router maps /users/:id to Pages::Users::IdLoader.action(:call)
    #   get '/users/:id', to: Pages::Users::IdLoader.action(:call)
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

    # Provides data to the page component.
    #
    # Override this method in subclasses to fetch and return data for your pages.
    # This is called by LoaderDataController when SolidStart requests data during SSR
    # or client-side navigation.
    #
    # @return [Hash] Data to pass to the page component as props
    #
    # @example Fetching a user
    #   def load
    #     user = User.find(params[:id])
    #     { id: user.id, name: user.name, email: user.email }
    #   end
    #
    # @example Using memoization for complex queries
    #   def load
    #     { user: user_data, posts: user_posts }
    #   end
    #
    #   private
    #
    #   def user_data
    #     @user_data ||= User.find(params[:id]).as_json(only: [:id, :name])
    #   end
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
      Templates.render('error_pages/daemon_unavailable.html',
                       error_message: ERB::Util.html_escape(error.message),
                       working_directory: ReactiveView.configuration.working_directory)
    end

    def render_error_html(error)
      Templates.render('error_pages/render_error.html',
                       error_message: ERB::Util.html_escape(error.message))
    end
  end
end
