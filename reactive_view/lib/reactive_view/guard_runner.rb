# frozen_string_literal: true

module ReactiveView
  # Executes folder-level guard chains for a given loader path + context.
  class GuardRunner
    class << self
      # Run all guards for the provided loader path and context.
      #
      # @param loader_path [String]
      # @param context [Symbol] one of :page, :load, :mutate, :stream
      # @param request [ActionDispatch::Request]
      # @param params [ActionController::Parameters, Hash]
      # @return [void]
      # @raise [ReactiveView::GuardRejectedError] when a guard rejects access
      def run!(loader_path:, context:, request:, params:)
        guard_classes = GuardRegistry.classes_for_loader_path(loader_path)
        return if guard_classes.empty?

        guard_classes.each do |guard_class|
          run_guard_class!(
            guard_class: guard_class,
            context: context,
            request: request,
            params: params
          )
        end
      end

      private

      def run_guard_class!(guard_class:, context:, request:, params:)
        guard_methods = guard_class.guards_for(context)
        return if guard_methods.empty?

        guard = build_guard(guard_class, request, params)

        guard_methods.each do |method_name|
          unless guard.respond_to?(method_name, true)
            raise NoMethodError, "Undefined guard method '#{method_name}' for #{guard_class.name}"
          end

          begin
            guard.send(method_name)
          rescue ReactiveView::GuardRejectedError
            raise
          rescue StandardError => e
            raise GuardRejectedError.new(e.message, redirect_path: e.redirect_path) if e.respond_to?(:redirect_path)

            raise
          end

          redirect_path = redirect_path_from_response(guard.response)
          raise GuardRejectedError.new('Access denied', redirect_path: redirect_path) if redirect_path
        end
      end

      def build_guard(guard_class, request, params)
        guard = guard_class.new
        guard.request = request
        guard.response = ActionDispatch::Response.new
        guard.response_body = nil
        guard.params = ActionController::Parameters.new(normalize_params(params))
        guard
      end

      def normalize_params(params)
        return params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
        return params.to_h if params.respond_to?(:to_h)

        {}
      end

      def redirect_path_from_response(response)
        location = response&.location
        return nil if location.blank?

        begin
          uri = URI.parse(location)
          return uri.request_uri if uri.absolute?
        rescue URI::InvalidURIError
          # Fall through and return the original location
        end

        location
      end
    end
  end
end
