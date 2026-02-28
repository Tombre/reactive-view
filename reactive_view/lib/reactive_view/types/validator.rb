# frozen_string_literal: true

require_relative 'error_formatter'

module ReactiveView
  module Types
    # Validates data against a Dry::Types schema.
    # Used by LoaderDataController for response validation and by Shape
    # for structured field-level error reporting.
    #
    # @example
    #   validator = Validator.new(schema)
    #   validator.validate!({ id: 1, name: "John" }) # => returns data or raises
    #
    #   result = validator.validate({ id: "bad" })
    #   result.success?  # => false
    #   result.errors    # => { "id" => ["must be Integer"] }
    #
    class Validator
      attr_reader :schema

      def initialize(schema)
        @schema = schema
      end

      # Validate data against the schema (raising version).
      #
      # @param data [Hash] The data to validate
      # @return [Hash] The validated data (possibly coerced)
      # @raise [ValidationError] If validation fails
      def validate!(data)
        return data if schema.nil?

        begin
          result = schema.try(data)

          raise ValidationError, ErrorFormatter.format_error(result.error) if result.failure?

          result.input
        rescue Dry::Types::CoercionError => e
          raise ValidationError, "Type coercion failed: #{e.message}"
        rescue Dry::Types::ConstraintError => e
          raise ValidationError, "Constraint violation: #{e.message}"
        rescue Dry::Types::SchemaError => e
          raise ValidationError, "Schema error: #{e.message}"
        end
      end

      # Validate without raising. Returns a result object with structured errors.
      #
      # @param data [Hash] The data to validate
      # @return [ValidationResult] Result object with success/failure info and structured errors
      def validate(data)
        return ValidationResult.new(true, data, {}) if schema.nil?

        begin
          result = schema.try(data)

          if result.success?
            ValidationResult.new(true, result.input, {})
          else
            errors = ErrorFormatter.build_structured_errors(result.error)
            ValidationResult.new(false, data, errors)
          end
        rescue Dry::Types::CoercionError => e
          ValidationResult.new(false, data, { 'base' => ["Type coercion failed: #{e.message}"] })
        rescue Dry::Types::ConstraintError => e
          ValidationResult.new(false, data, { 'base' => ["Constraint violation: #{e.message}"] })
        rescue Dry::Types::SchemaError => e
          ValidationResult.new(false, data, { 'base' => ["Schema error: #{e.message}"] })
        end
      end
    end

    # Result object for non-raising validation.
    # Provides structured field-level errors with paths.
    class ValidationResult
      attr_reader :data, :errors

      # @param success [Boolean] Whether validation passed
      # @param data [Hash] The validated (or original) data
      # @param errors [Hash<String, Array<String>>] Structured field-level errors
      def initialize(success, data, errors)
        @success = success
        @data = data
        @errors = errors || {}
      end

      # @return [Boolean] Whether validation passed
      def success?
        @success
      end

      # @return [Boolean] Whether validation failed
      def failure?
        !@success
      end

      # Backward compatibility: returns first error message or nil.
      #
      # @return [String, nil] The first error message
      def error
        return nil if @errors.empty?

        first_key = @errors.keys.first
        messages = @errors[first_key]
        messages.is_a?(::Array) ? messages.first : messages.to_s
      end
    end
  end
end
