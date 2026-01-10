# frozen_string_literal: true

module ReactiveView
  module Types
    # DSL for building type signatures in loaders.
    # Used with the `shape` class method.
    #
    # @example
    #   shape :load do
    #     param :id, Types::Integer
    #     param :name, Types::String
    #     param :email, Types::Optional[Types::String]
    #     param :tags, Types::Array[Types::String]
    #     param :metadata, Types::Hash.schema(
    #       created_at: Types::String,
    #       updated_at: Types::String
    #     )
    #   end
    #
    class SignatureBuilder
      attr_reader :schema

      def initialize(&block)
        @schema = {}
        instance_eval(&block) if block_given?
      end

      # Define a parameter in the signature
      #
      # @param name [Symbol] Parameter name
      # @param type [Dry::Types::Type] The Dry::Types type
      def param(name, type)
        @schema[name] = type
      end

      # Build the final type schema
      #
      # @return [Dry::Types::Type] A hash schema type
      def build
        return Types::Hash if @schema.empty?

        Types::Hash.schema(@schema)
      end
    end

    # Represents a complete loader signature with metadata
    class Signature
      attr_reader :schema, :params

      def initialize(schema)
        @schema = schema
        @params = extract_params(schema)
      end

      # Get all parameter names
      def param_names
        @params.keys
      end

      # Get the type for a specific parameter
      def type_for(name)
        @params[name]
      end

      # Check if the schema is empty
      def empty?
        @params.empty?
      end

      private

      def extract_params(schema)
        return {} unless schema.respond_to?(:keys)

        schema.keys.each_with_object({}) do |key, hash|
          hash[key.name] = key.type
        end
      rescue StandardError => e
        ReactiveView.logger.debug "[ReactiveView] Could not extract params from schema: #{e.message}"
        {}
      end
    end
  end
end
