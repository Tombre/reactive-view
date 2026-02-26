# frozen_string_literal: true

module ReactiveView
  module Types
    # DSL for building type signatures in shapes and loaders.
    # Used with the `shape` class method or inside `ReactiveView::Shape` subclasses.
    #
    # @example Basic params with symbol shortcuts
    #   shape :load do
    #     param :id, :integer
    #     param :name             # defaults to String
    #     param :email, Types::Optional[Types::String]
    #   end
    #
    # @example Nested collections and hashes
    #   shape :load do
    #     param :id, :integer
    #     collection :pets do
    #       param :name
    #       param :species
    #     end
    #     hash :contact_data do
    #       param :email
    #       param :phone_number
    #     end
    #   end
    #
    class SignatureBuilder
      # Map of symbol shortcuts to their Dry::Types equivalents
      TYPE_SHORTCUTS = {
        string: -> { Types::String },
        integer: -> { Types::Integer },
        float: -> { Types::Float },
        boolean: -> { Types::Boolean },
        bool: -> { Types::Boolean },
        date: -> { Types::Date },
        date_time: -> { Types::DateTime },
        time: -> { Types::Time },
        any: -> { Types::Any }
      }.freeze

      attr_reader :schema

      def initialize(&block)
        @schema = {}
        instance_eval(&block) if block_given?
      end

      # Define a parameter in the signature.
      #
      # @param name [Symbol] Parameter name
      # @param type [Dry::Types::Type, Symbol, nil] The type. Accepts a Dry::Types type,
      #   a symbol shortcut (:integer, :string, :boolean, :float, :date, :date_time, :time, :any),
      #   or nil (defaults to Types::String).
      #
      # @example With explicit type
      #   param :id, ReactiveView::Types::Integer
      #
      # @example With symbol shortcut
      #   param :id, :integer
      #
      # @example With default type (String)
      #   param :name
      def param(name, type = nil)
        @schema[name] = resolve_type(type)
      end

      # Define a collection (array of hashes) parameter.
      # The block defines the schema for each element in the array.
      #
      # @param name [Symbol] Parameter name
      # @yield Block defining the hash schema for each element
      #
      # @example
      #   collection :pets do
      #     param :name
      #     param :species
      #   end
      #   # Equivalent to: param :pets, Types::Array[Types::Hash.schema(name: String, species: String)]
      def collection(name, &block)
        nested_builder = self.class.new(&block)
        nested_schema = nested_builder.build
        @schema[name] = Types::Array[nested_schema]
      end

      # Define a nested hash parameter.
      # The block defines the schema for the hash.
      #
      # @param name [Symbol] Parameter name
      # @yield Block defining the hash schema
      #
      # @example
      #   hash :contact_data do
      #     param :email
      #     param :phone_number
      #   end
      #   # Equivalent to: param :contact_data, Types::Hash.schema(email: String, phone_number: String)
      def hash(name, &block)
        nested_builder = self.class.new(&block)
        nested_schema = nested_builder.build
        @schema[name] = nested_schema
      end

      # Build the final type schema.
      #
      # @return [Dry::Types::Type] A hash schema type
      def build
        return Types::Hash if @schema.empty?

        Types::Hash.schema(@schema)
      end

      private

      # Resolve a type argument to a Dry::Types type.
      # Handles symbol shortcuts, nil (defaults to String), and pass-through of Dry types.
      #
      # @param type [Dry::Types::Type, Symbol, nil] The type to resolve
      # @return [Dry::Types::Type] The resolved Dry type
      def resolve_type(type)
        case type
        when nil
          Types::String
        when Symbol
          shortcut = TYPE_SHORTCUTS[type]
          if shortcut
            shortcut.call
          else
            raise ArgumentError, "Unknown type shortcut :#{type}. " \
              "Available shortcuts: #{TYPE_SHORTCUTS.keys.join(', ')}"
          end
        else
          type
        end
      end
    end

    # Represents a complete loader signature with metadata.
    # Wraps a built Dry::Types schema for introspection.
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
