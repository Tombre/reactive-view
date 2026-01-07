# frozen_string_literal: true

require 'faraday'

module ReactiveView
  class FileSync
    # Notifies the Vite dev server of loader file changes to trigger HMR.
    # When a .loader.rb file changes, this sends a message to Vite which
    # broadcasts to connected clients to refetch their data.
    class ViteNotifier
      class << self
        # Notify Vite of loader changes to trigger HMR
        #
        # @param routes [Array<String>] Route paths that changed
        # @param type [String] Type of change: "modified", "added", or "removed"
        # @return [void]
        def notify(routes, type)
          return if routes.empty?

          daemon_url = ReactiveView.configuration.daemon_url
          endpoint = "#{daemon_url}/__reactive_view/invalidate-loader"

          begin
            response = Faraday.post(endpoint) do |req|
              req.headers['Content-Type'] = 'application/json'
              req.body = { routes: routes, type: type }.to_json
              req.options.timeout = 5
              req.options.open_timeout = 2
            end

            if response.success?
              ReactiveView.logger.debug "[ReactiveView] Notified Vite of loader changes: #{routes.join(', ')}"
            else
              ReactiveView.logger.warn "[ReactiveView] Failed to notify Vite: #{response.status}"
            end
          rescue Faraday::Error => e
            # Don't fail if Vite is not running - this is expected during startup
            ReactiveView.logger.debug "[ReactiveView] Could not notify Vite (may not be running yet): #{e.message}"
          end
        end

        # Convert a loader file path to its route identifier
        #
        # @param path [String] Full path to the loader file
        # @param pages_path [Pathname] Base pages directory path
        # @return [String, nil] Route path (e.g., "users/index", "users/[id]")
        #
        # @example
        #   loader_path_to_route("/app/pages/users/index.loader.rb", pages_path) #=> "users/index"
        #   loader_path_to_route("/app/pages/users/[id].loader.rb", pages_path) #=> "users/[id]"
        def loader_path_to_route(path, pages_path)
          relative = Pathname.new(path).relative_path_from(pages_path).to_s

          # Remove .loader.rb extension to get route path
          route = relative.sub(/\.loader\.rb$/, '')

          route.empty? ? nil : route
        end
      end
    end
  end
end
