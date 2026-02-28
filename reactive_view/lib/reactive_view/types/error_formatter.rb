# frozen_string_literal: true

module ReactiveView
  module Types
    module ErrorFormatter
      module_function

      def format_error(error)
        case error
        when ::Hash
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

      def build_structured_errors(error, prefix: '', include_array_indices: false)
        errors = {}

        case error
        when ::Hash
          error.each do |key, value|
            path = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
            errors.merge!(build_structured_errors(value, prefix: path, include_array_indices: include_array_indices))
          end
        when ::Array
          messages = error.filter_map { |e| extract_error_message(e) }
          if messages.any?
            path = prefix.empty? ? 'base' : prefix
            errors[path] = messages
          end

          if include_array_indices
            error.each_with_index do |entry, index|
              next unless entry.is_a?(::Hash) || entry.is_a?(::Array)

              indexed_prefix = "#{prefix}[#{index}]"
              nested = build_structured_errors(entry, prefix: indexed_prefix, include_array_indices: true)
              errors.merge!(nested)
            end
          end
        when Dry::Types::Result::Failure
          errors.merge!(build_structured_errors(error.error, prefix: prefix,
                                                             include_array_indices: include_array_indices))
        else
          message = extract_error_message(error)
          if message
            path = prefix.empty? ? 'base' : prefix
            errors[path] = [message]
          end
        end

        errors
      end

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
end
