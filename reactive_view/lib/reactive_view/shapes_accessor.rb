# frozen_string_literal: true

module ReactiveView
  # Provides access to Shape classes registered on a loader.
  #
  # When you call `shapes.update`, it returns the Shape class for that name.
  # You then call `.call(params)` or `.call!(params)` on the Shape class to
  # validate and coerce the input.
  #
  # @example Usage in a loader
  #   class IdLoader < ReactiveView::Loader
  #     shape :update do
  #       param :name
  #       param :email
  #     end
  #
  #     params_shape :update, :update
  #
  #     def update
  #       result = shapes.update.call!(params)
  #       user.update(result.data)
  #     end
  #   end
  #
  # @example Non-raising validation
  #   result = shapes.update.call(params)
  #   if result.valid?
  #     user.update(result.data)
  #   else
  #     render_error(result.errors)
  #   end
  #
  class ShapesAccessor
    # @param shapes [Hash<Symbol, Class>] Map of shape names to Shape classes
    def initialize(shapes)
      @shapes = shapes || {}
    end

    # Dynamically return the Shape class for any defined shape name.
    #
    # @param method_name [Symbol] The shape name
    # @return [Class] The Shape class
    # @raise [NoMethodError] If no shape with that name is defined
    def method_missing(method_name, *args, &block)
      if @shapes.key?(method_name)
        @shapes[method_name]
      else
        super
      end
    end

    # @param method_name [Symbol] Method name to check
    # @param include_private [Boolean] Include private methods
    # @return [Boolean] Whether we respond to this method
    def respond_to_missing?(method_name, include_private = false)
      @shapes.key?(method_name) || super
    end
  end
end
