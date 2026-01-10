# frozen_string_literal: true

module ReactiveView
  # Internal controller that handles data requests for loader data.
  # This is called when useLoaderData() is invoked during:
  # - SSR: SolidStart daemon calls back to Rails with forwarded cookies
  # - Client-side navigation: Browser calls directly with session cookies
  #
  # Authentication is handled via Rails session cookies in both cases.
  class LoaderDataController < ActionController::Base
    # Skip CSRF for API-style requests
    skip_forgery_protection

    # GET /_reactive_view/loaders/:path/load
    def show
      # Get the loader class from the path
      loader_class = LoaderRegistry.class_for_path(loader_path)

      # Instantiate and configure the loader
      loader = build_loader(loader_class)

      # Call the load method
      data = loader.load

      # Validate the response in development/test
      validate_response!(loader_class, data)

      render json: data
    rescue ValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue LoaderNotFoundError => e
      render json: { error: e.message }, status: :not_found
    rescue StandardError => e
      handle_loader_error(e)
    end

    private

    # Extract the loader path from the URL
    # The path comes from the route: /_reactive_view/loaders/:path/load
    # where :path can contain slashes (e.g., "users/index" or "users/[id]")
    def loader_path
      params[:path]
    end

    def build_loader(loader_class)
      loader = loader_class.new

      # Set up params from the request query parameters
      # Route params (like :id) are passed as query params by the frontend
      loader.params = ActionController::Parameters.new(loader_params)

      # Set the request/response for helpers (current_user, etc.)
      loader.request = request
      loader.response = response

      loader
    end

    # Extract loader-relevant params from the request
    # Excludes internal routing params
    def loader_params
      params.to_unsafe_h.except('controller', 'action', 'path')
    end

    def validate_response!(loader_class, data)
      return unless ReactiveView.configuration.should_validate_responses?
      return unless loader_class._method_shapes[:load]

      validator = Types::Validator.new(loader_class._method_shapes[:load])
      validator.validate!(data)
    end

    def handle_loader_error(error)
      ReactiveView.logger.error "[ReactiveView] Loader error: #{error.message}"
      ReactiveView.logger.error error.backtrace.join("\n") if error.backtrace

      if Rails.env.development? || Rails.env.test?
        render json: {
          error: error.message,
          type: error.class.name,
          backtrace: error.backtrace&.first(10)
        }, status: :internal_server_error
      else
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end
    end
  end
end
