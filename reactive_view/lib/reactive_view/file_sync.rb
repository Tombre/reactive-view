# frozen_string_literal: true

require 'faraday'

module ReactiveView
  # Synchronizes TSX files from app/pages to the SolidStart working directory.
  # In development, watches for changes and syncs automatically.
  #
  # Also watches for loader file (.loader.rb) changes and notifies Vite
  # to trigger HMR events for data refetching.
  class FileSync
    class << self
      # Sync all TSX files from pages to the working directory
      def sync_all
        setup_working_directory
        sync_tsx_files
        sync_loader_types
      end

      # Start watching for file changes (development only)
      #
      # Watches for:
      # - TSX/TS files: synced to working directory for Vite to pick up
      # - Loader files (.loader.rb): trigger HMR notification for data refetch
      def start_watching
        return if @listener

        pages_path = ReactiveView.configuration.pages_absolute_path
        return unless pages_path.exist?

        # Watch both TSX/TS files and loader.rb files
        @listener = Listen.to(pages_path.to_s, only: /\.(tsx|ts|rb)$/) do |modified, added, removed|
          handle_changes(modified, added, removed)
        end

        @listener.start
        ReactiveView.logger.info "[ReactiveView] File watcher started for #{pages_path}"
      end

      # Stop the file watcher
      def stop_watching
        return unless @listener

        @listener.stop
        @listener = nil
        ReactiveView.logger.info '[ReactiveView] File watcher stopped'
      end

      private

      # Setup the SolidStart working directory from the template
      def setup_working_directory
        working_dir = ReactiveView.configuration.working_directory_absolute_path
        template_dir = gem_template_path

        unless working_dir.exist?
          ReactiveView.logger.info "[ReactiveView] Setting up working directory at #{working_dir}"
          FileUtils.mkdir_p(working_dir)

          # Copy template files
          FileUtils.cp_r("#{template_dir}/.", working_dir)

          # Create the routes directory for synced pages
          FileUtils.mkdir_p(working_dir.join('src', 'routes'))
        end

        # Ensure node_modules exists (run npm install if needed)
        return if working_dir.join('node_modules').exist?

        install_dependencies(working_dir)
      end

      # Copy TSX files to the working directory routes
      def sync_tsx_files
        pages_path = ReactiveView.configuration.pages_absolute_path
        routes_path = ReactiveView.configuration.working_directory_absolute_path.join('src', 'routes')

        return unless pages_path.exist?

        # Clean existing routes (except api directory which has our render endpoint)
        Dir.glob(routes_path.join('*')).each do |path|
          next if File.basename(path) == 'api'

          FileUtils.rm_rf(path)
        end

        # Copy TSX files maintaining directory structure
        Dir.glob(pages_path.join('**', '*.tsx')).each do |source|
          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = routes_path.join(relative)

          FileUtils.mkdir_p(dest.dirname)
          FileUtils.cp(source, dest)
        end

        ReactiveView.logger.debug "[ReactiveView] Synced TSX files to #{routes_path}"
      end

      # Generate TypeScript types from loader signatures
      def sync_loader_types
        Types::TypescriptGenerator.generate
      rescue StandardError => e
        ReactiveView.logger.warn "[ReactiveView] Failed to generate types: #{e.message}"
      end

      # Handle file change events
      #
      # @param modified [Array<String>] Paths of modified files
      # @param added [Array<String>] Paths of added files
      # @param removed [Array<String>] Paths of removed files
      def handle_changes(modified, added, removed)
        pages_path = ReactiveView.configuration.pages_absolute_path
        routes_path = ReactiveView.configuration.working_directory_absolute_path.join('src', 'routes')

        tsx_modified = []
        tsx_added = []
        tsx_removed = []
        loader_changes = { modified: [], added: [], removed: [] }

        # Categorize changes
        (modified + added).each do |source|
          if source.end_with?('.loader.rb')
            type = modified.include?(source) ? :modified : :added
            loader_changes[type] << source
          elsif source.end_with?('.tsx', '.ts')
            if modified.include?(source)
              tsx_modified << source
            else
              tsx_added << source
            end
          end
        end

        removed.each do |source|
          if source.end_with?('.loader.rb')
            loader_changes[:removed] << source
          elsif source.end_with?('.tsx', '.ts')
            tsx_removed << source
          end
        end

        # Handle TSX/TS file changes - sync to working directory
        sync_tsx_changes(tsx_modified + tsx_added, tsx_removed, pages_path, routes_path)

        # Handle loader file changes - regenerate types and notify Vite
        handle_loader_changes(loader_changes, pages_path)
      end

      # Sync TSX/TS file changes to the working directory
      #
      # @param changed [Array<String>] Paths of modified/added files
      # @param removed [Array<String>] Paths of removed files
      # @param pages_path [Pathname] Source pages directory
      # @param routes_path [Pathname] Destination routes directory
      def sync_tsx_changes(changed, removed, pages_path, routes_path)
        changed.each do |source|
          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = routes_path.join(relative)

          FileUtils.mkdir_p(dest.dirname)
          FileUtils.cp(source, dest)

          ReactiveView.logger.debug "[ReactiveView] Synced: #{relative}"
        end

        removed.each do |source|
          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = routes_path.join(relative)

          next unless dest.exist?

          FileUtils.rm(dest)
          ReactiveView.logger.debug "[ReactiveView] Removed: #{relative}"

          cleanup_empty_directories(dest.dirname, routes_path)
        end
      end

      # Handle loader file changes - regenerate types and notify Vite for HMR
      #
      # @param changes [Hash] Hash with :modified, :added, :removed keys containing file paths
      # @param pages_path [Pathname] Source pages directory
      def handle_loader_changes(changes, pages_path)
        all_changes = changes[:modified] + changes[:added] + changes[:removed]
        return if all_changes.empty?

        # Regenerate TypeScript types
        sync_loader_types

        # Build route paths from loader file paths
        routes = all_changes.map { |path| loader_path_to_route(path, pages_path) }.compact

        # Determine the change type (use most significant: removed > added > modified)
        type = if changes[:removed].any?
                 'removed'
               elsif changes[:added].any?
                 'added'
               else
                 'modified'
               end

        ReactiveView.logger.info "[ReactiveView] Loader #{type}: #{routes.join(', ')}"

        # Notify Vite to trigger HMR event for data refetch
        notify_vite_loader_change(routes, type)
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

      # Notify the Vite dev server of loader changes to trigger HMR
      #
      # @param routes [Array<String>] Route paths that changed
      # @param type [String] Type of change: "modified", "added", or "removed"
      def notify_vite_loader_change(routes, type)
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

      # Remove empty directories up to the base path
      def cleanup_empty_directories(dir, base)
        return if dir == base || !dir.to_s.start_with?(base.to_s)

        return unless dir.directory? && dir.empty?

        FileUtils.rmdir(dir)
        cleanup_empty_directories(dir.parent, base)
      end

      # Install npm dependencies
      def install_dependencies(working_dir)
        ReactiveView.logger.info '[ReactiveView] Installing npm dependencies...'

        Dir.chdir(working_dir) do
          system('npm install --silent') || raise(Error, 'Failed to install npm dependencies')
        end
      end

      # Path to the gem's template directory
      def gem_template_path
        Pathname.new(__dir__).parent.parent.join('template')
      end
    end
  end
end
