# frozen_string_literal: true

module ReactiveView
  # Base class for defining validated data shapes.
  #
  # A Shape is both a schema definition and a validator. It can be used standalone
  # via class inheritance or created anonymously via the block DSL on loaders.
  #
  # Shapes produce structured field-level errors on validation failure and
  # coerce string params (from HTTP) to their declared types.
  #
  # @example Standalone shape class
  #   class UserShape < ReactiveView::Shape
  #     shape do
  #       param :id, :integer
  #       param :name, ReactiveView::Types::String
  #       collection :pets do
  #         param :name
  #         param :species
  #       end
  #     end
  #   end
  #
  #   result = UserShape.new(id: "1", name: "Alice", pets: [{ name: "Fido", species: "dog" }])
  #   result.valid?  # => true
  #   result.data    # => { id: 1, name: "Alice", pets: [{ name: "Fido", species: "dog" }] }
  #
  # @example Non-raising class method
  #   result = UserShape.call(params)
  #   result.valid?   # => true/false
  #   result.data     # => coerced data hash
  #   result.errors   # => { "id" => ["must be Integer"] }
  #
  # @example Raising class method
  #   result = UserShape.call!(params)  # raises ReactiveView::ValidationError on failure
  #   result.data
  #
  class Shape
    attr_reader :data, :errors

    class << self
      # Define the schema for this shape via the DSL block.
      #
      # @yield Block evaluated in the context of a SignatureBuilder
      # @return [void]
      #
      # @example
      #   class MyShape < ReactiveView::Shape
      #     shape do
      #       param :id, :integer
      #       param :name
      #     end
      #   end
      def shape(&block)
        @_shape_builder_block = block
      end

      # @return [Proc, nil] The block used to build this shape's schema
      def _shape_builder_block
        @_shape_builder_block
      end

      # Build and return the Dry::Types schema for this shape.
      # Used by the TypeScript generator and for introspection.
      #
      # @return [Dry::Types::Type] The built schema
      def dry_schema
        block = _shape_builder_block
        return Types::Hash unless block

        builder = Types::SignatureBuilder.new(&block)
        builder.build
      end

      # Non-raising factory: returns a Shape instance.
      # Check `.valid?` and `.errors` on the result.
      #
      # @param input [Hash, ActionController::Parameters] Data to validate
      # @return [Shape] The validated shape instance
      def call(input = {})
        new(input)
      end

      # Raising factory: returns a Shape instance or raises on validation failure.
      #
      # @param input [Hash, ActionController::Parameters] Data to validate
      # @return [Shape] The validated shape instance
      # @raise [ReactiveView::ValidationError] If validation fails
      def call!(input = {})
        instance = new(input)
        unless instance.valid?
          raise ReactiveView::ValidationError, instance.errors.inspect
        end

        instance
      end
    end

    # Create a new shape instance, validating the input against the schema.
    #
    # @param input [Hash, ActionController::Parameters, nil] Data to validate
    def initialize(input = {})
      @input = normalize_input(input)
      @errors = {}
      @data = {}
      process
    end

    # @return [Boolean] Whether the input passed validation
    def valid?
      @errors.empty?
    end

    # @return [Boolean] Alias for valid?
    alias_method :success?, :valid?

    # @return [Boolean] Whether the input failed validation
    def failure?
      !valid?
    end

    private

    # Normalize input to a plain hash with string keys.
    #
    # @param input [Hash, ActionController::Parameters, nil] Raw input
    # @return [Hash] Normalized hash
    def normalize_input(input)
      return {} if input.nil?

      hash = if input.respond_to?(:to_unsafe_h)
               input.to_unsafe_h
             elsif input.respond_to?(:to_h)
               input.to_h
             else
               {}
             end

      # Ensure string keys for consistent key lookup
      hash.transform_keys(&:to_s)
    end

    # Run the full validation pipeline: filter, coerce, validate.
    def process
      schema = self.class.dry_schema
      return if schema == Types::Hash # empty schema, nothing to validate

      # Extract permitted keys from the schema
      permitted_keys = extract_permitted_keys(schema)

      # Filter to only include defined keys
      filtered = @input.slice(*permitted_keys.map(&:to_s))

      # Coerce values to expected types
      coerced = coerce_params(filtered, schema)

      # Validate against the Dry schema
      validate_against_schema(coerced, schema)
    end

    # Extract permitted key names from a Dry::Types schema.
    #
    # @param schema [Dry::Types::Type] The schema
    # @return [Array<Symbol>] List of key names
    def extract_permitted_keys(schema)
      return [] unless schema.respond_to?(:keys)

      schema.keys.map(&:name)
    rescue StandardError => e
      ReactiveView.logger.debug "[ReactiveView] Could not extract keys from shape: #{e.message}"
      []
    end

    # Coerce string params to their expected types.
    #
    # @param params [Hash] Filtered params (string keys)
    # @param schema [Dry::Types::Type] The schema with type info
    # @return [Hash] Params with coerced values and symbolized keys
    def coerce_params(params, schema)
      return params.transform_keys(&:to_sym) unless schema.respond_to?(:keys)

      key_types = schema.keys.each_with_object({}) { |k, h| h[k.name] = k.type }
      result = {}

      params.each do |key, value|
        sym_key = key.to_sym
        type = key_types[sym_key]

        result[sym_key] = if type
                            coerce_value(value, type)
                          else
                            value
                          end
      end

      result
    end

    # Coerce a single value to the expected type.
    #
    # @param value [Object] The value to coerce
    # @param type [Dry::Types::Type] The expected type
    # @return [Object] The coerced value
    def coerce_value(value, type)
      return value if value.nil?

      type_name = extract_type_name(type)

      case type_name
      when /Integer/i
        value.is_a?(Integer) ? value : value.to_s.to_i
      when /Float/i, /Decimal/i
        value.is_a?(Float) ? value : value.to_s.to_f
      when /Bool/i, /TrueClass/i, /FalseClass/i
        coerce_boolean(value)
      when /Array/i
        coerce_array(value, type)
      when /Hash/i
        coerce_hash(value, type)
      else
        value
      end
    rescue StandardError
      value
    end

    # Coerce an array value, recursively coercing member elements.
    #
    # @param value [Array, nil] The array to coerce
    # @param type [Dry::Types::Type] The array type with member info
    # @return [Array] Coerced array
    def coerce_array(value, type)
      return value unless value.is_a?(::Array)

      member_type = extract_array_member_type(type)
      return value unless member_type

      value.map { |item| coerce_value(item, member_type) }
    end

    # Coerce a hash value, recursively coercing nested values.
    #
    # @param value [Hash, nil] The hash to coerce
    # @param type [Dry::Types::Type] The hash type with schema info
    # @return [Hash] Coerced hash with symbolized keys
    def coerce_hash(value, type)
      return value unless value.is_a?(::Hash)
      return value.transform_keys(&:to_sym) unless type.respond_to?(:keys) && type.keys.any?

      coerce_params(value.transform_keys(&:to_s), type)
    end

    # Extract the member type from an array type.
    #
    # @param type [Dry::Types::Type] An array type
    # @return [Dry::Types::Type, nil] The member type
    def extract_array_member_type(type)
      inner = type
      inner = inner.type while inner.respond_to?(:type) && !inner.respond_to?(:member)
      return inner.member if inner.respond_to?(:member)

      nil
    rescue StandardError
      nil
    end

    # Extract the type name from a Dry::Types type.
    #
    # @param type [Dry::Types::Type] The type to inspect
    # @return [String] The type name
    def extract_type_name(type)
      return extract_type_name(type.right) if type.optional? && type.respond_to?(:right)
      return "Boolean" if type.respond_to?(:name) && type.name == "TrueClass | FalseClass"
      return type.primitive.name.to_s.split("::").last if type.respond_to?(:primitive)

      type.class.name.to_s.split("::").last
    rescue StandardError
      "Any"
    end

    # Coerce a value to boolean.
    #
    # @param value [Object] The value to coerce
    # @return [Boolean]
    def coerce_boolean(value)
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

      case value.to_s.downcase
      when "true", "1", "yes", "on"
        true
      when "false", "0", "no", "off", ""
        false
      else
        !!value
      end
    end

    # Validate coerced data against the Dry schema and populate @data / @errors.
    #
    # @param coerced [Hash] Coerced data with symbolized keys
    # @param schema [Dry::Types::Type] The Dry schema
    def validate_against_schema(coerced, schema)
      result = schema.try(coerced)

      if result.success?
        @data = result.input
        @errors = {}
      else
        @data = coerced
        @errors = build_structured_errors(result.error)
      end
    rescue Dry::Types::CoercionError => e
      @data = coerced
      @errors = {"base" => ["Type coercion failed: #{e.message}"]}
    rescue Dry::Types::ConstraintError => e
      @data = coerced
      @errors = {"base" => ["Constraint violation: #{e.message}"]}
    rescue Dry::Types::SchemaError => e
      @data = coerced
      @errors = {"base" => ["Schema error: #{e.message}"]}
    end

    # Build structured field-level errors from a Dry::Types error.
    #
    # @param error [Object] The error from Dry::Types schema.try
    # @param prefix [String] Current path prefix for nested errors
    # @return [Hash<String, Array<String>>] Field paths to error messages
    def build_structured_errors(error, prefix: "")
      errors = {}

      case error
      when ::Hash
        error.each do |key, value|
          path = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
          nested = build_structured_errors(value, prefix: path)
          errors.merge!(nested)
        end
      when ::Array
        messages = error.filter_map { |e| extract_error_message(e) }
        if messages.any?
          path = prefix.empty? ? "base" : prefix
          errors[path] = messages
        end

        # Also check for indexed errors (array element validation)
        error.each_with_index do |e, i|
          if e.is_a?(::Hash) || e.is_a?(::Array)
            nested = build_structured_errors(e, prefix: "#{prefix}[#{i}]")
            errors.merge!(nested)
          end
        end
      when Dry::Types::Result::Failure
        nested = build_structured_errors(error.error, prefix: prefix)
        errors.merge!(nested)
      else
        message = extract_error_message(error)
        if message
          path = prefix.empty? ? "base" : prefix
          errors[path] = [message]
        end
      end

      errors
    end

    # Extract a human-readable error message from a Dry error object.
    #
    # @param error [Object] A Dry error or string
    # @return [String, nil] The error message
    def extract_error_message(error)
      case error
      when ::String
        error
      when Dry::Types::CoercionError, Dry::Types::ConstraintError, Dry::Types::SchemaError
        error.message
      when Dry::Types::Result::Failure
        extract_error_message(error.error)
      else
        error.respond_to?(:message) ? error.message : error.to_s
      end
    rescue StandardError
      nil
    end
  end
end
