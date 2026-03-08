# frozen_string_literal: true

module ReactiveView
  # Base class for folder-level route guards.
  #
  # Guards are defined with the `guard` DSL and run before requests are
  # handled by page render/load/mutate/stream entry points.
  class RouteGuard < ActionController::Base
    VALID_CONTEXTS = %i[page load mutate stream].freeze

    class_attribute :_guards, default: []

    class << self
      # Register a guard method.
      #
      # @param method_name [Symbol, String] Instance method to invoke
      # @param on [Array<Symbol>, Symbol] Contexts where this guard applies
      # @return [void]
      def guard(method_name, on: VALID_CONTEXTS)
        method = method_name.to_sym
        contexts = normalize_contexts(on)

        self._guards = _guards + [{ method: method, on: contexts }]
      end

      # Return guard methods for a given execution context.
      #
      # @param context [Symbol, String]
      # @return [Array<Symbol>]
      def guards_for(context)
        context_key = context.to_sym

        _guards.filter_map do |definition|
          definition[:method] if definition[:on].include?(context_key)
        end
      end

      private

      def normalize_contexts(contexts)
        normalized = Array(contexts).map(&:to_sym)
        invalid = normalized - VALID_CONTEXTS
        raise ArgumentError, "Unsupported guard context(s): #{invalid.join(', ')}" if invalid.any?

        normalized.uniq
      end
    end

    # Route guards are evaluated outside the Rails action callback chain.
    # Use redirect_to as a rejection signal rather than mutating controller response state.
    def redirect_to(options = {}, _response_options = {})
      redirect_path = options.is_a?(String) ? options : url_for(options)
      raise ReactiveView::GuardRejectedError.new('Access denied', redirect_path: redirect_path)
    end
  end
end
