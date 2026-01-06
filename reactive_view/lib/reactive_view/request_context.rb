# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'json'
require 'securerandom'

module ReactiveView
  # Manages request context storage and token-based retrieval.
  # Tokens allow the SolidStart daemon to securely call back to Rails
  # to fetch loader data during SSR.
  class RequestContext
    TOKEN_EXPIRY = 30 # seconds
    HMAC_ALGORITHM = 'SHA256'

    class << self
      # Store request context and return a signed token
      #
      # @param request [ActionDispatch::Request] The original request
      # @param loader_path [String] The loader path (e.g., "users/[id]")
      # @param loader_class [Class, nil] The loader class (optional, uses default if nil)
      # @return [String] Signed token for SolidStart to use
      def store(request, loader_path, loader_class = nil)
        token = generate_token

        context = {
          loader_path: loader_path,
          loader_class: loader_class&.name,
          params: sanitize_params(request.params),
          created_at: Time.current.to_i
        }

        cache.write(cache_key(token), context, expires_in: TOKEN_EXPIRY.seconds)

        token
      end

      # Retrieve and consume stored context by token
      # Tokens are single-use for security
      #
      # @param token [String] The token from SolidStart
      # @return [Hash] The stored context
      # @raise [InvalidTokenError] If token is invalid, expired, or already used
      def retrieve(token)
        validate_token_format!(token)

        context = cache.read(cache_key(token))
        raise InvalidTokenError, 'Invalid or expired token' unless context

        # Verify token hasn't expired (double-check beyond cache expiry)
        if Time.current.to_i - context[:created_at] > TOKEN_EXPIRY
          cache.delete(cache_key(token))
          raise InvalidTokenError, 'Token has expired'
        end

        # Single use - delete after retrieval
        cache.delete(cache_key(token))

        context
      end

      # Check if a token exists without consuming it (for testing)
      #
      # @param token [String] The token to check
      # @return [Boolean]
      def exists?(token)
        cache.exist?(cache_key(token))
      end

      # Clear all stored contexts (useful for testing)
      def clear_all
        # Only works if cache supports clear or we track keys
        # For now, rely on expiry
      end

      private

      def generate_token
        timestamp = Time.current.to_i
        random = SecureRandom.hex(16)
        payload = "#{timestamp}.#{random}"
        signature = sign(payload)

        "#{Base64.urlsafe_encode64(payload)}.#{signature}"
      end

      def validate_token_format!(token)
        parts = token.to_s.split('.')
        raise InvalidTokenError, 'Malformed token' unless parts.length == 2

        payload = Base64.urlsafe_decode64(parts[0])
        expected_signature = sign(payload)

        raise InvalidTokenError, 'Invalid token signature' unless secure_compare(parts[1], expected_signature)

        true
      rescue ArgumentError => e
        raise InvalidTokenError, "Malformed token: #{e.message}"
      end

      def sign(payload)
        OpenSSL::HMAC.hexdigest(HMAC_ALGORITHM, secret_key, payload)
      end

      def secret_key
        # Use Rails secret_key_base or a dedicated secret
        Rails.application.secret_key_base || raise(Error, 'Rails secret_key_base is not set')
      end

      def secure_compare(a, b)
        ActiveSupport::SecurityUtils.secure_compare(a, b)
      end

      def cache_key(token)
        "reactive_view:request_context:#{Digest::SHA256.hexdigest(token)}"
      end

      def cache
        # Use Rails.cache, but fall back to memory store in development if caching is disabled
        if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
          @memory_cache ||= ActiveSupport::Cache::MemoryStore.new
        else
          Rails.cache
        end
      end

      def sanitize_params(params)
        # Convert to hash and remove sensitive/non-serializable data
        # Handle both ActionController::Parameters and regular Hash
        hash = if params.respond_to?(:to_unsafe_h)
                 params.to_unsafe_h
               else
                 params.to_h
               end

        hash.except('controller', 'action', :controller, :action).deep_stringify_keys
      end
    end
  end
end
