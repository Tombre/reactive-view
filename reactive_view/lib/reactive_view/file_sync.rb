# frozen_string_literal: true

require_relative 'file_sync/directory_setup'
require_relative 'file_sync/component_syncer'
require_relative 'file_sync/wrapper_generator'
require_relative 'file_sync/vite_notifier'
require_relative 'file_sync/file_watcher'

module ReactiveView
  # Facade for file synchronization between Rails app/pages and SolidStart working directory.
  #
  # Delegates to specialized classes:
  # - DirectorySetup: Initial working directory setup and npm install
  # - ComponentSyncer: Syncs TSX/TS files from app/pages to .reactive_view/src/pages
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
      # Syncs all files from app/pages to the SolidStart working directory.
      #
      # This method performs a full sync:
      # 1. Sets up the .reactive_view directory (copies template, runs npm install)
      # 2. Syncs TSX/TS components to .reactive_view/src/pages
      # 3. Generates route wrappers in .reactive_view/src/routes
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
        ComponentSyncer.sync_all
        WrapperGenerator.generate_all
        sync_loader_types
      end

      # Starts watching for file changes in app/pages (development only).
      #
      # When files change:
      # - TSX/TS files are synced to .reactive_view/src/pages
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
