# frozen_string_literal: true

module ReactiveView
  # Internal controller that handles data requests for loader data and mutations.
  # This is called when useLoaderData() or mutation actions are invoked during:
  # - SSR: SolidStart daemon calls back to Rails with forwarded cookies
  # - Client-side navigation: Browser calls directly with session cookies
  #
  # Authentication is handled via Rails session cookies in both cases.
  class LoaderDataController < ActionController::Base
    include ActionController::Live

    # Skip CSRF for read-only load requests (GET)
    skip_forgery_protection only: [:show]

    # Enable CSRF protection for mutations and streaming
    protect_from_forgery with: :exception, only: %i[mutate stream]
    before_action :verify_csrf_for_mutation, only: %i[mutate stream]

    # GET /_reactive_view/loaders/:path/load
    # Fetches data from a loader for SSR or client-side navigation
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

    # POST/PUT/PATCH/DELETE /_reactive_view/loaders/:path/mutate
    # Handles mutation requests from forms or useAction calls
    #
    # The mutation method to call is determined by the _mutation parameter.
    # Defaults to 'mutate' if not specified.
    #
    # @example
    #   POST /_reactive_view/loaders/users/[id]/mutate?_mutation=update
    #   POST /_reactive_view/loaders/users/[id]/mutate?_mutation=delete
    def mutate
      loader_class = LoaderRegistry.class_for_path(loader_path)
      loader = build_loader(loader_class)

      # Determine which mutation method to call
      mutation_name = params[:_mutation].presence || 'mutate'
      mutation_method = mutation_name.to_sym

      # Validate the mutation method exists and is allowed
      unless valid_mutation_method?(loader, mutation_method)
        return render json: {
          success: false,
          error: "Mutation '#{mutation_name}' not defined for this loader"
        }, status: :not_found
      end

      # Call the mutation method and get the result
      result = loader.public_send(mutation_method)

      # Handle the mutation result
      render_mutation_result(result)
    rescue LoaderNotFoundError => e
      render json: { success: false, error: e.message }, status: :not_found
    rescue ArgumentError => e
      # Wrong number of arguments or other argument issues
      handle_argument_error(e, mutation_name)
    rescue NoMethodError => e
      # Defense-in-depth: shouldn't happen due to valid_mutation_method? check
      handle_no_method_error(e, mutation_name)
    rescue StandardError => e
      handle_mutation_error(e)
    end

    # POST /_reactive_view/loaders/:path/stream
    # Handles SSE streaming responses from mutation methods that call render_stream.
    #
    # The mutation method should return a StreamResponse (via render_stream).
    # If it returns a regular value, falls back to JSON response.
    def stream
      loader_class = LoaderRegistry.class_for_path(loader_path)
      loader = build_loader(loader_class)

      mutation_name = params[:_mutation].presence || 'stream'
      mutation_method = mutation_name.to_sym

      unless valid_mutation_method?(loader, mutation_method)
        response.headers['Content-Type'] = 'application/json'
        response.stream.write({ error: "Stream mutation '#{mutation_name}' not defined" }.to_json)
        response.stream.close
        return
      end

      result = loader.public_send(mutation_method)

      unless result.is_a?(StreamResponse)
        # Not a stream response -- fall back to JSON
        response.headers['Content-Type'] = 'application/json'
        response.stream.write(render_mutation_result_json(result))
        response.stream.close
        return
      end

      # Set SSE headers
      response.headers['Content-Type'] = 'text/event-stream'
      response.headers['Cache-Control'] = 'no-cache'
      response.headers['Connection'] = 'keep-alive'
      response.headers['X-Accel-Buffering'] = 'no'

      response_shape_class = loader_class.resolve_response_shape(mutation_method)
      response_mode = loader_class.response_shape_mode(mutation_method)

      stream_validator = if ReactiveView.configuration.should_validate_responses? &&
                            response_mode == :stream &&
                            response_shape_class
                           Types::Validator.new(response_shape_class.dry_schema)
                         end

      enforced_chunk_type = response_mode == :stream ? :json : nil

      writer = StreamWriter.new(
        response.stream,
        validator: stream_validator,
        enforced_chunk_type: enforced_chunk_type
      )
      begin
        result.block.call(writer)
      rescue StandardError => e
        ReactiveView.logger.error "[ReactiveView] Stream error: #{e.message}"
        ReactiveView.logger.error e.backtrace&.first(5)&.join("\n") if e.backtrace
        writer.event('error', message: e.message) unless writer.closed?
      ensure
        writer.close unless writer.closed?
      end
    rescue LoaderNotFoundError => e
      response.headers['Content-Type'] = 'application/json'
      response.stream.write({ error: e.message }.to_json)
      response.stream.close
    rescue StandardError => e
      handle_stream_error(e)
    end

    private

    # Verify CSRF token for mutation requests
    # Accepts token from either X-CSRF-Token header or authenticity_token param
    def verify_csrf_for_mutation
      token = request.headers['X-CSRF-Token'] || params[:authenticity_token]

      return if token.present? && valid_authenticity_token?(session, token)

      raise ActionController::InvalidAuthenticityToken
    end

    # Check if the mutation method is valid and allowed to be called.
    #
    # A method is valid if:
    # - The loader responds to it
    # - It's not the :load method (reserved for data loading)
    # - It's defined on the loader class itself or a Loader subclass (not inherited from
    #   ActionController::Base or other base classes)
    #
    # @param loader [ReactiveView::Loader] The loader instance
    # @param method [Symbol] The method name to check
    # @return [Boolean]
    def valid_mutation_method?(loader, method)
      # Must respond to the method
      return false unless loader.respond_to?(method)

      # Cannot be the load method (reserved for data loading)
      return false if method == :load

      # Check if the method is defined in the loader class hierarchy
      # We walk up the class hierarchy and accept methods defined on:
      # - The loader class itself
      # - Any class between the loader and ReactiveView::Loader (inclusive)
      # This excludes methods only defined on ActionController::Base or Object
      klass = loader.class
      while klass && klass != Object
        # Accept if method is defined directly on this class
        return true if klass.instance_methods(false).include?(method)

        # Stop checking once we reach ReactiveView::Loader
        break if klass == ReactiveView::Loader

        klass = klass.superclass
      end

      false
    end

    # Extract the loader path from the URL
    # The path comes from the route: /_reactive_view/loaders/:path/load
    # where :path can contain slashes (e.g., "users/index" or "users/[id]")
    def loader_path
      params[:path]
    end

    def build_loader(loader_class)
      loader = loader_class.new

      # Set up params from the request
      # Route params and form data are both accessible via params
      loader.params = ActionController::Parameters.new(loader_params)

      # Set the request/response for helpers (current_user, etc.)
      loader.request = request
      loader.response = response

      loader
    end

    # Extract loader-relevant params from the request
    # Excludes internal routing params
    def loader_params
      params.to_unsafe_h.except('controller', 'action', 'path', '_mutation')
    end

    def validate_response!(loader_class, data)
      return unless ReactiveView.configuration.should_validate_responses?

      # Resolve the response shape for the :load action
      shape_class = loader_class.resolve_response_shape(:load)
      return unless shape_class

      validator = Types::Validator.new(shape_class.dry_schema)
      validator.validate!(data)
    end

    # Render the result of a mutation method
    # Handles MutationResult objects or legacy direct responses
    #
    # @param result [MutationResult, Hash, nil] The mutation result
    def render_mutation_result(result)
      case result
      when MutationResult
        render json: result.to_json_hash, status: result.status
      when Hash
        # Legacy support: mutation returned a hash directly
        render json: result
      when nil
        # Mutation returned nothing, assume success
        render json: { success: true }
      else
        # Unknown return type, try to handle gracefully
        render json: { success: true, data: result }
      end
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

    def handle_mutation_error(error)
      ReactiveView.logger.error "[ReactiveView] Mutation error: #{error.message}"
      ReactiveView.logger.error error.backtrace.join("\n") if error.backtrace

      if Rails.env.development? || Rails.env.test?
        render json: {
          success: false,
          error: error.message,
          type: error.class.name,
          backtrace: error.backtrace&.first(10)
        }, status: :internal_server_error
      else
        render json: { success: false, error: 'Internal server error' },
               status: :internal_server_error
      end
    end

    # Handle ArgumentError from mutation methods (wrong number of arguments, etc.)
    #
    # @param error [ArgumentError] The error
    # @param mutation_name [String] The name of the mutation that was called
    def handle_argument_error(error, mutation_name)
      ReactiveView.logger.error "[ReactiveView] Mutation argument error: #{error.message}"

      render json: {
        success: false,
        error: "Invalid call to mutation '#{mutation_name}': #{error.message}"
      }, status: :bad_request
    end

    # Handle NoMethodError from mutation methods (defense-in-depth)
    #
    # @param error [NoMethodError] The error
    # @param mutation_name [String] The name of the mutation that was called
    def handle_no_method_error(error, mutation_name)
      ReactiveView.logger.error "[ReactiveView] Mutation method error: #{error.message}"

      render json: {
        success: false,
        error: "Mutation '#{mutation_name}' is not available"
      }, status: :not_found
    end

    # Serialize a mutation result to JSON string (for stream fallback).
    # Mirrors render_mutation_result but returns a string instead of calling render.
    #
    # @param result [MutationResult, Hash, nil] The mutation result
    # @return [String] JSON string
    def render_mutation_result_json(result)
      case result
      when MutationResult then result.to_json_hash.to_json
      when Hash then result.to_json
      when nil then { success: true }.to_json
      else { success: true, data: result }.to_json
      end
    end

    # Handle errors during stream setup (before writer is available)
    #
    # @param error [StandardError] The error that occurred
    def handle_stream_error(error)
      ReactiveView.logger.error "[ReactiveView] Stream error: #{error.message}"
      ReactiveView.logger.error error.backtrace&.join("\n") if error.backtrace
      begin
        response.stream.write("data: #{{ type: 'error', message: error.message }.to_json}\n\n")
        response.stream.close
      rescue StandardError => e
        ReactiveView.logger.error "[ReactiveView] Failed to write stream error: #{e.message}"
      end
    end
  end
end
