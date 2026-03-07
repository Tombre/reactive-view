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

      # Validate and coerce params for the load action when configured
      validate_and_coerce_action_params!(loader_class, loader, :load)

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

      validate_and_coerce_action_params!(loader_class, loader, mutation_method)

      # Call the mutation method and get the result
      result = loader.public_send(mutation_method)

      # Handle the mutation result
      render_mutation_result(result)
    rescue LoaderNotFoundError => e
      render json: { success: false, error: e.message }, status: :not_found
    rescue ValidationError => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
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

      validate_and_coerce_action_params!(loader_class, loader, mutation_method)

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
        if client_disconnected_error?(e)
          ReactiveView.logger.debug '[ReactiveView] Stream closed by client'
        else
          ReactiveView.logger.error "[ReactiveView] Stream error: #{e.message}"
          ReactiveView.logger.error e.backtrace&.first(5)&.join("\n") if e.backtrace
          writer.event('error', message: e.message) unless writer.closed?
        end
      ensure
        writer.close unless writer.closed?
      end
    rescue LoaderNotFoundError => e
      response.headers['Content-Type'] = 'application/json'
      response.status = :not_found
      response.stream.write({ error: e.message }.to_json)
      response.stream.close
    rescue ValidationError => e
      response.headers['Content-Type'] = 'application/json'
      response.status = :unprocessable_entity
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
    # - It's not the :load method (reserved for data loading)
    # - It's a public instance method declared on the concrete loader class or a
    #   custom superclass between it and ReactiveView::Loader
    #
    # This blocks inherited framework/base helper methods from being callable via
    # the external mutation endpoint while preserving inherited user-defined
    # mutation methods.
    #
    # @param loader [ReactiveView::Loader] The loader instance
    # @param method [Symbol] The method name to check
    # @return [Boolean]
    def valid_mutation_method?(loader, method)
      # Cannot be the load method (reserved for data loading)
      return false if method == :load

      # Must be callable at all
      return false unless loader.respond_to?(method)

      klass = loader.class
      while klass && klass != ReactiveView::Loader && klass != Object
        return true if klass.public_instance_methods(false).include?(method)

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

    def validate_and_coerce_action_params!(loader_class, loader, action)
      shape_class = loader_class.resolve_params_shape(action)
      return unless shape_class

      result = shape_class.call(loader.params)
      raise ValidationError, result.errors.inspect unless result.valid?

      merged_params = loader.params.to_unsafe_h.merge(result.data.deep_stringify_keys)
      loader.params = ActionController::Parameters.new(merged_params)
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
      if error.respond_to?(:redirect_path)
        return render json: {
          error: error.message,
          redirect: error.redirect_path
        }, status: :unauthorized
      end

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
      if client_disconnected_error?(error)
        ReactiveView.logger.debug '[ReactiveView] Stream closed by client during setup'
        return
      end

      ReactiveView.logger.error "[ReactiveView] Stream error: #{error.message}"
      ReactiveView.logger.error error.backtrace&.join("\n") if error.backtrace
      begin
        response.stream.write("data: #{{ type: 'error', message: error.message }.to_json}\n\n")
        response.stream.close
      rescue StandardError => e
        return if client_disconnected_error?(e)

        ReactiveView.logger.error "[ReactiveView] Failed to write stream error: #{e.message}"
      end
    end

    def client_disconnected_error?(error)
      return true if defined?(ActionController::Live::ClientDisconnected) &&
                     error.is_a?(ActionController::Live::ClientDisconnected)
      return true if error.is_a?(Errno::EPIPE)

      return false unless error.is_a?(IOError)

      error.message.to_s.downcase.match?(/client disconnected|closed stream|stream closed|broken pipe/)
    end
  end
end
