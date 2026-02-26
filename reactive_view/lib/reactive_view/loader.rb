# frozen_string_literal: true

module ReactiveView
  # Base controller for handling ReactiveView page requests and mutations.
  # Subclass this in your app/pages/*.loader.rb files to provide data to your pages
  # and handle mutations.
  #
  # @example Basic loader with data
  #   # app/pages/users/[id].loader.rb
  #   class Pages::Users::IdLoader < ReactiveView::Loader
  #     shape :load do
  #       param :id, :integer
  #       param :name
  #     end
  #
  #     response_shape :load, :load
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
  # @example Loader with mutations
  #   class Pages::Users::IdLoader < ReactiveView::Loader
  #     shape :load do
  #       param :user, ReactiveView::Types::Hash.schema(
  #         id: ReactiveView::Types::Integer,
  #         name: ReactiveView::Types::String
  #       )
  #     end
  #
  #     shape :update do
  #       param :name
  #       param :email
  #     end
  #
  #     response_shape :load, :load
  #     params_shape :update, :update
  #
  #     def load
  #       { user: { id: user.id, name: user.name } }
  #     end
  #
  #     def update
  #       result = shapes.update.call!(params)
  #       if user.update(result.data)
  #         render_success(user: { id: user.id, name: user.name })
  #       else
  #         render_error(user)
  #       end
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
  #     response_shape :load, :load
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
  # @example Using a standalone Shape class
  #   class UserUpdateShape < ReactiveView::Shape
  #     shape do
  #       param :name
  #       param :email
  #     end
  #   end
  #
  #   class Pages::Users::IdLoader < ReactiveView::Loader
  #     params_shape :update, UserUpdateShape
  #
  #     def update
  #       result = shapes.update.call!(params)
  #       user.update(result.data)
  #     end
  #   end
  #
  class Loader < ActionController::Base
    # Named shape definitions: { name => Shape class }
    # Shapes defined via the block DSL or assigned as Shape classes
    class_attribute :_shapes, default: {}

    # Params shape assignments: { action_name => shape_ref (Symbol or Class) }
    # Defines which shape validates incoming params for a given action
    class_attribute :_params_shapes, default: {}

    # Response shape assignments: { action_name => shape_ref (Symbol or Class) }
    # Defines which shape validates outgoing response data for a given action
    class_attribute :_response_shapes, default: {}

    class << self
      # Define a named shape. Creates an anonymous Shape subclass from the block
      # and stores it under the given name. Can also accept a Shape class directly.
      #
      # Shapes defined here are stored in `_shapes` and can be referenced by name
      # in `params_shape` and `response_shape` declarations.
      #
      # @param name [Symbol] The name to register the shape under
      # @param klass [Class, nil] An optional Shape class to use directly
      # @yield Block defining the shape's parameters (evaluated via SignatureBuilder DSL)
      #
      # @example Define a shape with a block
      #   shape :load do
      #     param :id, :integer
      #     param :name
      #   end
      #
      # @example Register a Shape class
      #   shape :update, UserUpdateShape
      def shape(name, klass = nil, &block)
        if klass
          unless klass.is_a?(Class) && klass <= ReactiveView::Shape
            raise ArgumentError, "Expected a ReactiveView::Shape subclass, got #{klass}"
          end

          self._shapes = _shapes.merge(name => klass)
        elsif block_given?
          shape_class = Class.new(ReactiveView::Shape) { shape(&block) }
          self._shapes = _shapes.merge(name => shape_class)
        else
          raise ArgumentError, "shape requires either a Shape class or a block"
        end
      end

      # Assign a shape as the params validator for an action.
      # The shape will be used to validate and coerce incoming params
      # when the action is called as a mutation.
      #
      # @param action [Symbol] The action (mutation) name
      # @param shape_ref [Symbol, Class] A symbol key referencing a shape in `_shapes`,
      #   or a Shape class directly
      #
      # @example Using a symbol key
      #   params_shape :update, :update
      #
      # @example Using a Shape class
      #   params_shape :update, UserUpdateShape
      def params_shape(action, shape_ref)
        self._params_shapes = _params_shapes.merge(action => shape_ref)
      end

      # Assign a shape as the response validator for an action.
      # The shape will be used to validate outgoing response data
      # and to generate TypeScript interfaces for the loader data.
      #
      # @param action [Symbol] The action name
      # @param shape_ref [Symbol, Class] A symbol key referencing a shape in `_shapes`,
      #   or a Shape class directly
      #
      # @example Using a symbol key
      #   response_shape :load, :load
      #
      # @example Using a Shape class
      #   response_shape :load, UserResponseShape
      def response_shape(action, shape_ref)
        self._response_shapes = _response_shapes.merge(action => shape_ref)
      end

      # Resolve a shape reference (Symbol or Class) to its Shape class.
      #
      # @param ref [Symbol, Class] A symbol key or Shape class
      # @return [Class, nil] The resolved Shape class, or nil if not found
      def resolve_shape(ref)
        case ref
        when Symbol
          _shapes[ref]
        when Class
          ref <= ReactiveView::Shape ? ref : nil
        else
          nil
        end
      end

      # Resolve the params shape for a given action.
      #
      # @param action [Symbol] The action name
      # @return [Class, nil] The Shape class for params, or nil
      def resolve_params_shape(action)
        ref = _params_shapes[action]
        ref ? resolve_shape(ref) : nil
      end

      # Resolve the response shape for a given action.
      #
      # @param action [Symbol] The action name
      # @return [Class, nil] The Shape class for response, or nil
      def resolve_response_shape(action)
        ref = _response_shapes[action]
        ref ? resolve_shape(ref) : nil
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
      # Include CSRF token for mutation forms
      html = renderer.render(
        path: request.fullpath,
        loader_path: loader_path,
        rails_base_url: rails_base_url,
        cookies: request.headers['Cookie'],
        csrf_token: form_authenticity_token
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

    # =========================================================================
    # Mutation Helpers
    # =========================================================================

    # Accessor for shape-based param extraction and validation.
    # Returns a ShapesAccessor that provides access to Shape classes
    # for each defined shape.
    #
    # @return [ShapesAccessor] Helper for accessing shapes
    #
    # @example Extract and validate params for an update mutation
    #   def update
    #     result = shapes.update.call!(params)
    #     user.update(result.data)
    #   end
    #
    # @example Non-raising validation
    #   def update
    #     result = shapes.update.call(params)
    #     if result.valid?
    #       user.update(result.data)
    #     else
    #       render_error(result.errors)
    #     end
    #   end
    def shapes
      @shapes ||= ShapesAccessor.new(self.class._shapes)
    end

    # Return a successful mutation response.
    # Returns a MutationResult that LoaderDataController will render.
    #
    # @param data [Hash] Optional additional data to include in response
    # @option data [Array<String>] :revalidate Routes to revalidate after mutation
    # @return [MutationResult] A success result object
    #
    # @example Simple success
    #   render_success
    #
    # @example Success with data
    #   render_success(user: { id: 1, name: "Updated" })
    #
    # @example Success with revalidation
    #   render_success(revalidate: ["users/index"])
    def render_success(data = {})
      MutationResult.success(data)
    end

    # Return an error response from a model or hash.
    # Returns a MutationResult that LoaderDataController will render.
    #
    # @param record_or_errors [ActiveModel::Errors, Hash, Object]
    #   An object with .errors method, or a hash of errors
    # @return [MutationResult] An error result object
    #
    # @example With an ActiveRecord model
    #   render_error(user)  # Uses user.errors
    #
    # @example With a hash of errors
    #   render_error(name: ["can't be blank"], email: ["is invalid"])
    #
    # @example With a string message
    #   render_error("Something went wrong")
    def render_error(record_or_errors)
      MutationResult.error(record_or_errors)
    end

    # Return a redirect response for mutations.
    # Returns a MutationResult that LoaderDataController will render as a redirect instruction.
    #
    # Note: For non-mutation requests (standard page navigation), this calls the parent
    # redirect_to method for normal HTTP redirects.
    #
    # @param options [String, Hash] URL or options hash for redirect
    # @param response_options [Hash] Additional options
    # @option response_options [Array<String>] :revalidate Routes to revalidate after redirect
    # @return [MutationResult, void] A redirect result object for mutations, or performs redirect
    #
    # @example Simple redirect after mutation
    #   def delete
    #     user.destroy
    #     mutation_redirect "/users"
    #   end
    #
    # @example Redirect with revalidation
    #   def delete
    #     user.destroy
    #     mutation_redirect "/users", revalidate: ["users/index"]
    #   end
    def mutation_redirect(path, revalidate: [])
      MutationResult.redirect(path, revalidate: revalidate)
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
