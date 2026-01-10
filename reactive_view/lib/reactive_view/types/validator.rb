# frozen_string_literal: true

module ReactiveView
  module Types
    # Validates loader response data against the declared type shape.
    # Only active in development and test environments by default.
    #
    # @example
    #   validator = Validator.new(loader_class._method_shapes[:load])
    #   validator.validate!({ id: 1, name: "John" }) # => returns data or raises
    #
    class Validator
      attr_reader :schema

      def initialize(schema)
        @schema = schema
      end

      # Validate data against the schema
      #
      # @param data [Hash] The data to validate
      # @return [Hash] The validated data (possibly coerced)
      # @raise [ValidationError] If validation fails
      def validate!(data)
        return data if schema.nil?

        begin
          result = schema.try(data)

          raise ValidationError, format_error(result.error) if result.failure?

          result.input
        rescue Dry::Types::CoercionError => e
          raise ValidationError, "Type coercion failed: #{e.message}"
        rescue Dry::Types::ConstraintError => e
          raise ValidationError, "Constraint violation: #{e.message}"
        rescue Dry::Types::SchemaError => e
          raise ValidationError, "Schema error: #{e.message}"
        end
      end

      # Validate without raising (returns result object)
      #
      # @param data [Hash] The data to validate
      # @return [ValidationResult] Result object with success/failure info
      def validate(data)
        validate!(data)
        ValidationResult.new(true, data, nil)
      rescue ValidationError => e
        ValidationResult.new(false, data, e.message)
      end

      private

      def format_error(error)
        case error
        when Hash
          error.map { |k, v| "#{k}: #{format_error(v)}" }.join(', ')
        when ::Array
          error.map { |e| format_error(e) }.join('; ')
        when Dry::Types::Result::Failure
          format_error(error.error)
        when Dry::Types::CoercionError, Dry::Types::ConstraintError, Dry::Types::SchemaError
          error.message
        else
          error.to_s
        end
      end
    end

    # Result object for non-raising validation
    class ValidationResult
      attr_reader :data, :error

      def initialize(success, data, error)
        @success = success
        @data = data
        @error = error
      end

      def success?
        @success
      end

      def failure?
        !@success
      end
    end
  end
end
