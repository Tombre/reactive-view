# frozen_string_literal: true

require 'dry-types'

module ReactiveView
  # Type system for loader signatures, built on top of Dry::Types.
  # Provides convenient type definitions that map to TypeScript types.
  module Types
    include Dry.Types()

    # NOTE: When you include Dry.Types(), it adds type builders like:
    # - Strict::String, Strict::Integer, etc.
    # - Coercible::String, Coercible::Integer, etc.
    #
    # We create convenient aliases below for use in loader_sig blocks.

    # Primitive types - these map directly to TypeScript primitives
    # Using self:: to avoid constant redefinition warnings
    module Primitives
      String = Dry::Types['strict.string']
      Integer = Dry::Types['strict.integer']
      Float = Dry::Types['strict.float']
      Bool = Dry::Types['strict.bool']
      Any = Dry::Types['any']
      Date = Dry::Types['strict.date']
      DateTime = Dry::Types['strict.date_time']
      Time = Dry::Types['strict.time']
    end

    # Re-export for convenient access
    String = Primitives::String
    Integer = Primitives::Integer
    Float = Primitives::Float
    Boolean = Primitives::Bool
    Any = Primitives::Any
    Date = Primitives::Date
    DateTime = Primitives::DateTime
    Time = Primitives::Time

    # Nullable/Optional wrapper
    # Usage: Types::Optional[Types::String]
    Optional = ->(type) { type.optional }

    # Array wrapper
    # Usage: Types::Array[Types::String]
    Array = ->(type) { Dry::Types['strict.array'].of(type) }

    # Hash type is already available from Dry::Types include
    # Usage: Types::Hash.schema(name: Types::String)
  end
end
