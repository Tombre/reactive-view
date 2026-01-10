# frozen_string_literal: true

module ReactiveView
  # Represents the result of a mutation operation.
  # Used to communicate mutation outcomes from Loader methods to LoaderDataController,
  # which then handles the actual HTTP response rendering.
  #
  # This class enables a clean separation between mutation logic (in loaders) and
  # response handling (in the controller), avoiding double render errors.
  #
  # @example Creating a success result
  #   MutationResult.success(user: { id: 1, name: "John" })
  #
  # @example Creating an error result
  #   MutationResult.error(name: ["can't be blank"])
  #
  # @example Creating a redirect result
  #   MutationResult.redirect("/users", revalidate: ["users/index"])
  #
  class MutationResult
    # @return [Symbol] The type of result: :success, :error, or :redirect
    attr_reader :type

    # @return [Hash] Data payload for success results
    attr_reader :data

    # @return [Hash<Symbol, Array<String>>] Error messages for error results
    attr_reader :errors

    # @return [String, nil] Redirect path for redirect results
    attr_reader :redirect_path

    # @return [Array<String>] Routes to revalidate after the mutation
    attr_reader :revalidate

    # @return [Integer] HTTP status code for the response
    attr_reader :status

    # Create a new MutationResult
    #
    # @param type [Symbol] The result type (:success, :error, :redirect)
    # @param data [Hash] Data payload for success results
    # @param errors [Hash] Error messages for error results
    # @param redirect_path [String, nil] Path for redirect results
    # @param revalidate [Array<String>] Routes to revalidate
    # @param status [Integer] HTTP status code
    def initialize(type:, data: {}, errors: {}, redirect_path: nil, revalidate: [], status: 200)
      @type = type
      @data = data
      @errors = errors
      @redirect_path = redirect_path
      @revalidate = Array(revalidate)
      @status = status
    end

    # Create a success result
    #
    # @param data [Hash] Data to include in the response
    # @option data [Array<String>] :revalidate Routes to revalidate
    # @return [MutationResult]
    #
    # @example
    #   MutationResult.success(user: { id: 1, name: "John" })
    #   MutationResult.success(user: { id: 1 }, revalidate: ["users/index"])
    def self.success(data = {})
      revalidate = data.delete(:revalidate) || []
      new(type: :success, data: data, revalidate: revalidate, status: 200)
    end

    # Create an error result
    #
    # @param errors [Hash, ActiveModel::Errors, Object, String] The errors
    # @return [MutationResult]
    #
    # @example With a hash
    #   MutationResult.error(name: ["can't be blank"])
    #
    # @example With an ActiveRecord model
    #   MutationResult.error(user)  # Uses user.errors
    def self.error(errors)
      normalized = normalize_errors(errors)
      new(type: :error, errors: normalized, status: 422)
    end

    # Create a redirect result
    #
    # @param path [String] The path to redirect to
    # @param revalidate [Array<String>] Routes to revalidate
    # @return [MutationResult]
    #
    # @example
    #   MutationResult.redirect("/users")
    #   MutationResult.redirect("/users", revalidate: ["users/index"])
    def self.redirect(path, revalidate: [])
      new(type: :redirect, redirect_path: path, revalidate: Array(revalidate), status: 200)
    end

    # Check if this is a success result
    # @return [Boolean]
    def success?
      type == :success
    end

    # Check if this is an error result
    # @return [Boolean]
    def error?
      type == :error
    end

    # Check if this is a redirect result
    # @return [Boolean]
    def redirect?
      type == :redirect
    end

    # Convert to a JSON-serializable hash for the response body
    # @return [Hash]
    def to_json_hash
      case type
      when :success
        { success: true, **data }.tap do |h|
          h[:revalidate] = revalidate if revalidate.any?
        end
      when :error
        { success: false, errors: errors }
      when :redirect
        { _redirect: redirect_path, _revalidate: revalidate }
      end
    end

    # Normalize errors into a consistent hash format
    #
    # @param record_or_errors [Object] The error source
    # @return [Hash<Symbol, Array<String>>] Normalized error hash
    def self.normalize_errors(record_or_errors)
      case record_or_errors
      when Hash
        # Already a hash, ensure values are arrays
        record_or_errors.transform_values { |v| Array(v) }
      when String
        { base: [record_or_errors] }
      when ->(r) { r.respond_to?(:errors) }
        errors_to_hash(record_or_errors.errors)
      else
        { base: [record_or_errors.to_s] }
      end
    end

    # Convert ActiveModel-style errors to a hash
    #
    # @param errors [ActiveModel::Errors, Object] The errors object
    # @return [Hash<Symbol, Array<String>>] Error hash
    def self.errors_to_hash(errors)
      if errors.respond_to?(:to_hash)
        errors.to_hash
      elsif errors.respond_to?(:messages)
        errors.messages
      elsif errors.respond_to?(:full_messages)
        { base: errors.full_messages }
      else
        { base: [errors.to_s] }
      end
    end
  end
end
