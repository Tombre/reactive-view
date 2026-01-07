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
      # Sync all files from app/pages to the SolidStart working directory.
      # Sets up the directory, syncs components, generates wrappers, and generates types.
      #
      # @return [void]
      def sync_all
        DirectorySetup.setup
        ComponentSyncer.sync_all
        WrapperGenerator.generate_all
        sync_loader_types
      end

      # Start watching for file changes (development only)
      #
      # @return [void]
      def start_watching
        FileWatcher.start
      end

      # Stop the file watcher
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
