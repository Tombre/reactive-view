# frozen_string_literal: true

module ReactiveView
  # Provides a strong-parameters-like interface for extracting and validating
  # params based on shape definitions.
  #
  # This class enables loaders to extract only the parameters defined in their
  # shape declarations, automatically filtering out unexpected keys and optionally
  # validating the types.
  #
  # @example Usage in a loader
  #   class IdLoader < ReactiveView::Loader
  #     shape :update do
  #       param :name, ReactiveView::Types::String
  #       param :email, ReactiveView::Types::String
  #     end
  #
  #     def update
  #       attrs = shapes.update(params)  # Extract only :name and :email
  #       user.update(attrs)
  #     end
  #   end
  #
  # @example With validation errors
  #   # If params contain invalid types and validation is enabled,
  #   # a Types::ValidationError will be raised
  #   shapes.update({ name: 123 })  # Raises ValidationError - name must be String
  #
  class ShapesAccessor
    # @param method_shapes [Hash<Symbol, Dry::Types::Type>] Map of method names to their schemas
    def initialize(method_shapes)
      @method_shapes = method_shapes || {}
    end

    # Dynamically handle calls for any defined shape
    #
    # @param method_name [Symbol] The shape name to extract params for
    # @param args [Array] Arguments (expects a single params-like object)
    # @return [Hash] Filtered and symbolized params
    # @raise [Types::ValidationError] If validation is enabled and params are invalid
    def method_missing(method_name, *args, &block)
      if @method_shapes.key?(method_name)
        extract_and_validate(method_name, args.first)
      else
        super
      end
    end

    # @param method_name [Symbol] Method name to check
    # @param include_private [Boolean] Include private methods
    # @return [Boolean] Whether we respond to this method
    def respond_to_missing?(method_name, include_private = false)
      @method_shapes.key?(method_name) || super
    end

    private

    # Extract permitted keys and validate against the shape schema
    #
    # @param method_name [Symbol] The shape name
    # @param params [ActionController::Parameters, Hash] The params to filter
    # @return [Hash] Filtered params with symbolized keys
    def extract_and_validate(method_name, params)
      shape = @method_shapes[method_name]
      return {} unless shape

      # Get permitted keys from the shape schema
      permitted_keys = extract_permitted_keys(shape)

      # Convert params to hash, handling ActionController::Parameters
      params_hash = normalize_params(params)

      # Filter to only include defined keys (like strong params)
      filtered = params_hash.slice(*permitted_keys.map(&:to_s))

      # Convert values to appropriate types where possible
      coerced = coerce_params(filtered, shape)

      # Validate in dev/test environments if configured
      if ReactiveView.configuration.should_validate_responses?
        validator = Types::Validator.new(shape)
        validator.validate!(coerced)
      end

      coerced
    end

    # Extract the list of permitted keys from a schema
    #
    # @param shape [Dry::Types::Type] The shape schema
    # @return [Array<Symbol>] List of permitted key names
    def extract_permitted_keys(shape)
      return [] unless shape.respond_to?(:keys)

      shape.keys.map(&:name)
    rescue StandardError => e
      ReactiveView.logger.debug "[ReactiveView] Could not extract keys from shape: #{e.message}"
      []
    end

    # Normalize params to a plain hash
    #
    # @param params [ActionController::Parameters, Hash, nil] The params object
    # @return [Hash] Plain hash of params
    def normalize_params(params)
      return {} if params.nil?

      if params.respond_to?(:to_unsafe_h)
        params.to_unsafe_h
      elsif params.respond_to?(:to_h)
        params.to_h
      else
        {}
      end
    end

    # Coerce string params to their expected types where possible
    #
    # @param params [Hash] The filtered params
    # @param shape [Dry::Types::Type] The shape schema
    # @return [Hash] Params with coerced values and symbolized keys
    def coerce_params(params, shape)
      return params.symbolize_keys unless shape.respond_to?(:keys)

      result = {}
      key_types = shape.keys.each_with_object({}) { |k, h| h[k.name] = k.type }

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

    # Coerce a single value to the expected type
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
      else
        value
      end
    rescue StandardError
      value
    end

    # Extract the type name from a Dry::Types type
    #
    # @param type [Dry::Types::Type] The type to inspect
    # @return [String] The type name
    def extract_type_name(type)
      # Handle optional types
      return extract_type_name(type.right) if type.optional? && type.respond_to?(:right)

      # Check for Boolean (Sum type of TrueClass | FalseClass) by name
      return 'Boolean' if type.respond_to?(:name) && type.name == 'TrueClass | FalseClass'

      # Try to get the primitive type first
      return type.primitive.name.to_s.split('::').last if type.respond_to?(:primitive)

      # Fallback to class name
      type.class.name.to_s.split('::').last
    rescue StandardError
      'Any'
    end

    # Coerce a value to boolean
    #
    # @param value [Object] The value to coerce
    # @return [Boolean] The boolean value
    def coerce_boolean(value)
      return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

      case value.to_s.downcase
      when 'true', '1', 'yes', 'on'
        true
      when 'false', '0', 'no', 'off', ''
        false
      else
        !!value
      end
    end
  end
end
