# frozen_string_literal: true

require_relative 'file_sync/atomic_writer'
require_relative 'file_sync/directory_setup'
require_relative 'file_sync/wrapper_generator'
require_relative 'file_sync/vite_notifier'
require_relative 'file_sync/file_watcher'

module ReactiveView
  # Facade for file synchronization between Rails app/pages and SolidStart working directory.
  #
  # Vite reads source files directly from app/pages via the ~pages alias in both
  # development and production builds, so only route wrappers and TypeScript
  # types are generated.
  #
  # Delegates to specialized classes:
  # - DirectorySetup: Initial working directory setup and npm install
  # - WrapperGenerator: Generates route wrappers in .reactive_view/src/routes
  # - FileWatcher: Watches for file changes in development
  # - ViteNotifier: Notifies Vite of loader changes for HMR
  #
  # @example Full sync (typically called once at startup)
  #   ReactiveView::FileSync.sync_all
  #
  # @example Start watching for changes (development)
  #   ReactiveView::FileSync.start_watching
  #
  class FileSync
    class << self
      # Check if a path is private (any segment starts with underscore).
      #
      # Private paths are synced to the SolidStart bundle (so they can be imported)
      # but do NOT generate routes or route wrappers. Use this convention to colocate
      # components, utilities, and styles alongside your pages.
      #
      # @param path [String, Pathname] Path to check (relative to pages directory)
      # @return [Boolean] true if path contains a private segment (underscore prefix)
      #
      # @example Private folder
      #   private_path?("_components/Button.tsx") # => true
      #
      # @example Private file
      #   private_path?("_helpers.ts") # => true
      #
      # @example Nested private folder
      #   private_path?("users/_partials/Card.tsx") # => true
      #
      # @example Regular route
      #   private_path?("users/index.tsx") # => false
      def private_path?(path)
        path.to_s.split('/').any? { |segment| segment.start_with?('_') }
      end

      # Sets up the SolidStart working directory and generates route wrappers and types.
      #
      # Sync behavior:
      # 1. Sets up the .reactive_view directory (copies template files)
      # 2. Ensures required root npm dependencies are installed
      # 3. Generates route wrappers in .reactive_view/src/routes (with ~pages alias imports)
      # 4. Generates TypeScript types from loader signatures
      #
      # @return [void]
      #
      # @example Manual sync via rake task
      #   # From command line:
      #   bin/rails reactive_view:sync
      #
      # @example Programmatic sync
      #   ReactiveView::FileSync.sync_all
      def sync_all
        DirectorySetup.setup
        WrapperGenerator.generate_all
        sync_loader_types
      end

      # Starts watching for file changes in app/pages (development only).
      #
      # When files change:
      # - Route wrappers are regenerated as needed
      # - Loader changes trigger TypeScript type regeneration and Vite HMR
      #
      # @return [void]
      #
      # @example Starting the watcher (typically done by the Engine)
      #   ReactiveView::FileSync.start_watching
      def start_watching
        FileWatcher.start
      end

      # Stops the file watcher.
      #
      # @return [void]
      def stop_watching
        FileWatcher.stop
      end

      private

      # Generate TypeScript types from loader signatures
      def sync_loader_types
        Types::TypescriptGenerator.generate
      rescue StandardError => e
        ReactiveView.logger.warn "[ReactiveView] Failed to generate types: #{e.message}"
      end
    end
  end
end
