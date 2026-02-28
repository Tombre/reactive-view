# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Watches for file changes in the pages directory and triggers syncing.
    # Watches all files and syncs everything except .loader.rb files.
    #
    # Features:
    # - Thread-safe start/stop operations
    # - Debounced change processing to batch rapid file changes
    # - Separate handling for asset files (TSX, CSS, etc.) vs loader files
    class FileWatcher
      # Debounce delay in seconds - wait this long after last change before processing
      DEBOUNCE_DELAY = 0.1

      class << self
        # Start watching for file changes (development only).
        #
        # Thread-safe: can be called from multiple threads.
        #
        # @return [void]
        def start
          listener_mutex.synchronize do
            return if @listener

            pages_path = ReactiveView.configuration.pages_absolute_path
            return unless pages_path.exist?

            initialize_state

            # Watch all files in pages directory
            @listener = Listen.to(pages_path.to_s) do |modified, added, removed|
              queue_changes(modified, added, removed)
            end

            @listener.start
            ReactiveView.logger.info "[ReactiveView] File watcher started for #{pages_path}"
          end
        end

        # Stop the file watcher.
        #
        # Thread-safe: can be called from multiple threads.
        #
        # @return [void]
        def stop
          listener_mutex.synchronize do
            stop_internal
          end
        end

        private

        # Mutex for protecting @listener access
        def listener_mutex
          @listener_mutex ||= Mutex.new
        end

        # Mutex for protecting pending changes
        def pending_mutex
          @pending_mutex ||= Mutex.new
        end

        # Initialize internal state for change tracking
        def initialize_state
          @pending = { modified: [], added: [], removed: [] }
          @debounce_thread = nil
        end

        # Stop listener without acquiring mutex (for internal use)
        def stop_internal
          # Stop debounce thread if running
          @debounce_thread&.kill if @debounce_thread&.alive?
          @debounce_thread = nil

          return unless @listener

          @listener.stop
          @listener = nil
          @pending = nil
          ReactiveView.logger.info '[ReactiveView] File watcher stopped'
        end

        # Queue changes for debounced processing.
        #
        # This collects changes and schedules processing after DEBOUNCE_DELAY.
        # If new changes come in before processing, the timer resets.
        #
        # @param modified [Array<String>] Paths of modified files
        # @param added [Array<String>] Paths of added files
        # @param removed [Array<String>] Paths of removed files
        def queue_changes(modified, added, removed)
          pending_mutex.synchronize do
            return unless @pending

            @pending[:modified] += modified
            @pending[:added] += added
            @pending[:removed] += removed
          end

          schedule_processing
        end

        # Schedule debounced processing of queued changes.
        #
        # Cancels any existing scheduled processing and starts a new timer.
        def schedule_processing
          pending_mutex.synchronize do
            # Cancel existing scheduled processing
            @debounce_thread&.kill if @debounce_thread&.alive?

            @debounce_thread = Thread.new do
              Thread.current.name = 'reactive_view_file_watcher_debounce'
              sleep debounce_delay
              process_pending_changes
            end
          end
        end

        # Process all pending changes.
        #
        # Collects pending changes atomically, then processes them.
        def process_pending_changes
          changes = pending_mutex.synchronize do
            return unless @pending

            result = @pending.dup
            @pending = { modified: [], added: [], removed: [] }
            result
          end

          # Deduplicate
          changes[:modified].uniq!
          changes[:added].uniq!
          changes[:removed].uniq!

          # Remove items that were both added and removed (net no-op)
          net_removed = changes[:removed] - changes[:added]
          net_added = changes[:added] - changes[:removed]
          # Modified files that were also removed should be ignored
          net_modified = changes[:modified] - changes[:removed]

          handle_changes(net_modified, net_added, net_removed)
        rescue StandardError => e
          ReactiveView.logger.error "[ReactiveView] Error processing file changes: #{e.message}"
        end

        # Handle file change events.
        #
        # @param modified [Array<String>] Paths of modified files
        # @param added [Array<String>] Paths of added files
        # @param removed [Array<String>] Paths of removed files
        def handle_changes(modified, added, removed)
          return if modified.empty? && added.empty? && removed.empty?

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

        # Sync asset files and update wrappers for TSX files.
        #
        # In development, file copying is skipped — Vite reads directly from
        # app/pages via the ~pages alias. Only wrapper generation/removal is needed
        # for added/removed TSX files.
        #
        # @param modified [Array<String>] Modified file paths
        # @param added [Array<String>] Added file paths
        # @param removed [Array<String>] Removed file paths
        # @param pages_path [Pathname] Source pages directory
        def handle_asset_changes(modified, added, removed, pages_path)
          # In development, Vite watches app/pages directly — no file copying needed.
          # In other environments, sync files to the working directory.
          unless Rails.env.development?
            modified.each do |source|
              ComponentSyncer.sync_file(source, pages_path)
            end
          end

          added.each do |source|
            relative = Pathname.new(source).relative_path_from(pages_path)
            ComponentSyncer.sync_file(source, pages_path) unless Rails.env.development?

            # Only generate wrappers for TSX files NOT in private paths
            if relative.extname == '.tsx' && !FileSync.private_path?(relative)
              WrapperGenerator.generate_wrapper(relative, pages_path)
              WrapperGenerator.regenerate_parent_layout(relative, pages_path)
            end

            ReactiveView.logger.info "[ReactiveView] Added: #{relative}"
          end

          removed.each do |source|
            relative = Pathname.new(source).relative_path_from(pages_path)
            ComponentSyncer.remove_file(relative) unless Rails.env.development?

            # Only remove wrappers for TSX files NOT in private paths
            if relative.extname == '.tsx' && !FileSync.private_path?(relative)
              WrapperGenerator.remove_wrapper(relative)
              WrapperGenerator.regenerate_parent_layout(relative, pages_path)
            end

            ReactiveView.logger.info "[ReactiveView] Removed: #{relative}"
          end
        end

        # Handle loader file changes - regenerate types and notify Vite for HMR.
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

        # Generate TypeScript types from loader signatures.
        def sync_loader_types
          Types::TypescriptGenerator.generate
        rescue StandardError => e
          ReactiveView.logger.warn "[ReactiveView] Failed to generate types: #{e.message}"
        end

        def debounce_delay
          DEBOUNCE_DELAY
        end
      end
    end
  end
end
