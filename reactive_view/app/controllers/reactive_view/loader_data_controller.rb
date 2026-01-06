# frozen_string_literal: true

module ReactiveView
  # Internal controller that handles data requests from the SolidStart daemon.
  # This is called when useLoaderData() is invoked during SSR.
  #
  # Security: Only requests with valid tokens (generated during the initial page request)
  # can access this endpoint. Tokens are single-use and short-lived.
  class LoaderDataController < ActionController::Base
    # Skip CSRF for API-style requests from SolidStart
    skip_forgery_protection

    before_action :validate_token!

    # GET /_reactive_view/loaders/:path/load
    def show
      # Retrieve stored context using the token
      context = RequestContext.retrieve(params[:token])

      # Get the loader class
      loader_class = resolve_loader_class(context)

      # Instantiate and configure the loader
      loader = build_loader(loader_class, context)

      # Call the load method
      data = loader.load

      # Validate the response in development/test
      validate_response!(loader_class, data)

      render json: data
    rescue InvalidTokenError => e
      render json: { error: e.message }, status: :forbidden
    rescue ValidationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      handle_loader_error(e)
    end

    private

    def validate_token!
      return if params[:token].present?

      render json: { error: 'Token required' }, status: :forbidden
    end

    def resolve_loader_class(context)
      if context[:loader_class]
        context[:loader_class].constantize
      else
        LoaderRegistry.class_for_path(context[:loader_path])
      end
    end

    def build_loader(loader_class, context)
      loader = loader_class.new

      # Set up the params from the stored context
      loader.params = ActionController::Parameters.new(context[:params])

      # Set the request/response if needed (for helpers)
      loader.request = request
      loader.response = response

      loader
    end

    def validate_response!(loader_class, data)
      return unless ReactiveView.configuration.should_validate_responses?
      return unless loader_class._loader_sig

      validator = Types::Validator.new(loader_class._loader_sig)
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
