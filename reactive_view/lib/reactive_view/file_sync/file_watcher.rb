# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Watches for file changes in the pages directory and triggers syncing.
    # Watches all files and syncs everything except .loader.rb files.
    class FileWatcher
      class << self
        # Start watching for file changes (development only)
        #
        # @return [void]
        def start
          return if @listener

          pages_path = ReactiveView.configuration.pages_absolute_path
          return unless pages_path.exist?

          # Watch all files in pages directory
          @listener = Listen.to(pages_path.to_s) do |modified, added, removed|
            handle_changes(modified, added, removed)
          end

          @listener.start
          ReactiveView.logger.info "[ReactiveView] File watcher started for #{pages_path}"
        end

        # Stop the file watcher
        #
        # @return [void]
        def stop
          return unless @listener

          @listener.stop
          @listener = nil
          ReactiveView.logger.info '[ReactiveView] File watcher stopped'
        end

        private

        # Handle file change events
        #
        # @param modified [Array<String>] Paths of modified files
        # @param added [Array<String>] Paths of added files
        # @param removed [Array<String>] Paths of removed files
        def handle_changes(modified, added, removed)
          pages_path = ReactiveView.configuration.pages_absolute_path

          asset_modified = []
          asset_added = []
          asset_removed = []
          loader_changes = { modified: [], added: [], removed: [] }

          # Categorize changes
          (modified + added).each do |source|
            if source.end_with?('.loader.rb')
              type = modified.include?(source) ? :modified : :added
              loader_changes[type] << source
            elsif modified.include?(source)
              # All other files are assets to sync
              asset_modified << source
            else
              asset_added << source
            end
          end

          removed.each do |source|
            if source.end_with?('.loader.rb')
              loader_changes[:removed] << source
            else
              asset_removed << source
            end
          end

          # Handle asset file changes - sync to working directory
          handle_asset_changes(asset_modified, asset_added, asset_removed, pages_path)

          # Handle loader file changes - regenerate types and notify Vite
          handle_loader_changes(loader_changes, pages_path)
        end

        # Sync asset files and update wrappers for TSX files
        #
        # @param modified [Array<String>] Modified file paths
        # @param added [Array<String>] Added file paths
        # @param removed [Array<String>] Removed file paths
        # @param pages_path [Pathname] Source pages directory
        def handle_asset_changes(modified, added, removed, pages_path)
          modified.each do |source|
            ComponentSyncer.sync_file(source, pages_path)
          end

          added.each do |source|
            relative = Pathname.new(source).relative_path_from(pages_path)
            ComponentSyncer.sync_file(source, pages_path)

            # Only generate wrappers for TSX files
            if relative.extname == '.tsx'
              WrapperGenerator.generate_wrapper(relative, pages_path)
              WrapperGenerator.regenerate_parent_layout(relative, pages_path)
            end

            ReactiveView.logger.info "[ReactiveView] Added: #{relative}"
          end

          removed.each do |source|
            relative = Pathname.new(source).relative_path_from(pages_path)
            ComponentSyncer.remove_file(relative)

            # Only remove wrappers for TSX files
            if relative.extname == '.tsx'
              WrapperGenerator.remove_wrapper(relative)
              WrapperGenerator.regenerate_parent_layout(relative, pages_path)
            end

            ReactiveView.logger.info "[ReactiveView] Removed: #{relative}"
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
          routes = all_changes.map { |path| ViteNotifier.loader_path_to_route(path, pages_path) }.compact

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
          ViteNotifier.notify(routes, type)
        end

        # Generate TypeScript types from loader signatures
        def sync_loader_types
          Types::TypescriptGenerator.generate
        rescue StandardError => e
          ReactiveView.logger.warn "[ReactiveView] Failed to generate types: #{e.message}"
        end
      end
    end
  end
end
