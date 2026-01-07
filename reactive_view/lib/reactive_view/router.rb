# frozen_string_literal: true

module ReactiveView
  # Scans the app/pages directory and generates Rails routes for ReactiveView pages.
  #
  # Implements SolidStart-style file-based routing, automatically mapping TSX files
  # to Rails routes with the appropriate loader controllers.
  #
  # ## Route Patterns
  #
  # | File Path | Rails Route | Description |
  # |-----------|-------------|-------------|
  # | `index.tsx` | `/` | Root route |
  # | `about.tsx` | `/about` | Static route |
  # | `users/index.tsx` | `/users` | Nested index |
  # | `users/[id].tsx` | `/users/:id` | Dynamic segment |
  # | `blog/[...slug].tsx` | `/blog/*slug` | Catch-all segment |
  # | `users/[[id]].tsx` | `/users(/:id)` | Optional segment |
  # | `(admin)/dashboard/analytics.tsx` | `/dashboard/analytics` | Grouped route (no URL prefix) |
  #
  # ## Route Priority
  #
  # Routes are sorted so that more specific routes match before less specific ones:
  # 1. Static routes (e.g., `/users/new`)
  # 2. Dynamic routes (e.g., `/users/:id`)
  # 3. Optional routes (e.g., `/users(/:id)`)
  # 4. Catch-all routes (e.g., `/blog/*slug`)
  #
  # @example Drawing routes in config/routes.rb
  #   Rails.application.routes.draw do
  #     ReactiveView::Router.draw(self)
  #   end
  #
  class Router
    class << self
      # Draws routes from the pages directory into the Rails router.
      #
      # Scans app/pages for TSX files and creates corresponding Rails routes.
      # Each route is mapped to its loader controller's `call` action.
      #
      # @param router [ActionDispatch::Routing::Mapper] The Rails router instance
      # @return [void]
      #
      # @example
      #   # In config/routes.rb
      #   Rails.application.routes.draw do
      #     ReactiveView::Router.draw(self)
      #   end
      def draw(router)
        pages_path = ReactiveView.configuration.pages_absolute_path
        return unless pages_path.exist?

        # Mount the engine for internal routes (loader data)
        router.mount ReactiveView::Engine, at: '/_reactive_view'

        # Scan and draw page routes
        routes = scan_directory(pages_path)
        draw_routes(router, routes)
      end

      private

      # Scan directory and collect route information
      #
      # @param base_path [Pathname] Base pages directory
      # @return [Array<Hash>] Route definitions
      def scan_directory(base_path)
        routes = []

        # Find all .tsx files (excluding .loader.rb files which are handled separately)
        Dir.glob(base_path.join('**', '*.tsx')).each do |file|
          file_path = Pathname.new(file)
          relative_path = file_path.relative_path_from(base_path)

          route_info = parse_route(relative_path)
          routes << route_info if route_info
        end

        # Sort routes: static routes before dynamic, longer paths before shorter
        sort_routes(routes)
      end

      # Parse a file path into route information
      #
      # @param relative_path [Pathname] Path relative to pages directory
      # @return [Hash, nil] Route definition
      def parse_route(relative_path)
        path_str = relative_path.to_s.sub(/\.tsx$/, '')
        segments = path_str.split('/')

        # Build Rails route path (filter out nil segments from grouped routes)
        route_path = segments.map { |s| segment_to_route(s) }.compact.join('/')

        # Normalize the path
        route_path = normalize_route_path(route_path)

        # Determine the loader path (used to find the loader class)
        loader_path = path_str

        # Determine if this is a layout (same name as a folder)
        is_layout = layout?(relative_path)

        {
          file_path: relative_path.to_s,
          route_path: route_path,
          loader_path: loader_path,
          segments: segments,
          is_layout: is_layout,
          priority: calculate_priority(segments)
        }
      end

      # Convert a path segment to Rails route format
      #
      # @param segment [String] Path segment
      # @return [String] Rails route segment
      def segment_to_route(segment)
        case segment
        when /^\[\.\.\.(.*?)\]$/
          # Catch-all: [...slug] -> *slug
          "*#{::Regexp.last_match(1)}"
        when /^\[\[(.*?)\]\]$/
          # Optional: [[id]] -> (:id)
          "(/:#{::Regexp.last_match(1)})"
        when /^\[(.*?)\]$/
          # Dynamic: [id] -> :id
          ":#{::Regexp.last_match(1)}"
        when /^\((.*?)\)$/
          # Grouped route: (admin) -> stripped from route path
          # These are used for layout grouping but don't affect the URL
          nil
        when 'index'
          # Index routes map to empty segment
          ''
        else
          segment
        end
      end

      # Normalize the final route path
      #
      # @param path [String] Route path
      # @return [String] Normalized path
      def normalize_route_path(path)
        # Remove trailing slashes and empty segments
        path = path.gsub(%r{//+}, '/').gsub(%r{^/|/$}, '')

        # Root path
        return '/' if path.empty?

        # Ensure leading slash
        "/#{path}"
      end

      # Check if a file is a layout (has a folder with the same name)
      #
      # @param relative_path [Pathname] Path to the file
      # @return [Boolean]
      def layout?(relative_path)
        # users.tsx is a layout if users/ directory exists
        dir_name = relative_path.to_s.sub(/\.tsx$/, '')
        pages_path = ReactiveView.configuration.pages_absolute_path

        pages_path.join(dir_name).directory?
      end

      # Calculate route priority for sorting
      # Lower number = higher priority (should be matched first)
      #
      # @param segments [Array<String>] Path segments
      # @return [Integer]
      def calculate_priority(segments)
        priority = 0

        segments.each do |segment|
          priority += case segment
                      when /^\[\.\.\./
                        # Catch-all: lowest priority
                        1000
                      when /^\[\[/
                        # Optional: low priority
                        100
                      when /^\[/
                        # Dynamic: medium-low priority
                        10
                      else
                        # Static: highest priority
                        1
                      end
        end

        # Longer paths generally have higher priority (matched more specifically)
        priority - (segments.length * 0.1)
      end

      # Sort routes by priority
      #
      # @param routes [Array<Hash>] Route definitions
      # @return [Array<Hash>] Sorted routes
      def sort_routes(routes)
        routes.sort_by { |r| [r[:priority], -r[:segments].length] }
      end

      # Draw the routes into the Rails router
      #
      # @param router [ActionDispatch::Routing::Mapper] Rails router
      # @param routes [Array<Hash>] Route definitions
      def draw_routes(router, routes)
        routes.each do |route|
          # Skip layout files - they don't need their own routes
          # (they wrap child routes but aren't directly accessible)
          next if route[:is_layout]

          draw_route(router, route)
        end
      end

      # Draw a single route
      #
      # @param router [ActionDispatch::Routing::Mapper] Rails router
      # @param route [Hash] Route definition
      def draw_route(router, route)
        loader_class = LoaderRegistry.class_for_path(route[:loader_path])

        # Use match with GET (and HEAD) for page routes
        router.match(
          route[:route_path],
          to: loader_class.action(:call),
          via: %i[get head],
          defaults: { reactive_view_loader_path: route[:loader_path] }
        )
      rescue StandardError => e
        ReactiveView.logger.error "[ReactiveView] Failed to draw route for #{route[:file_path]}: #{e.message}"
      end
    end
  end
end
