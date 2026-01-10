# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Syncs page files from app/pages to the SolidStart working directory.
    # Syncs all files except Ruby loader files, allowing Vite to handle
    # any asset type (CSS, SCSS, images, etc.).
    #
    # File operations are wrapped in error handling to ensure that sync failures
    # don't crash the application. Errors are logged but the app continues.
    class ComponentSyncer
      # File patterns to exclude from syncing (Ruby server-side files)
      EXCLUDED_EXTENSIONS = %w[.loader.rb].freeze

      class << self
        # Sync all page files to the working directory.
        #
        # This performs a full sync by removing the destination directory
        # and copying all files fresh. Individual file errors are logged
        # but don't abort the overall sync.
        #
        # @return [void]
        def sync_all
          pages_path = ReactiveView.configuration.pages_absolute_path
          return unless pages_path.exist?

          begin
            FileUtils.rm_rf(destination_path) if destination_path.exist?
            FileUtils.mkdir_p(destination_path)
          rescue SystemCallError => e
            ReactiveView.logger.error "[ReactiveView] Failed to prepare destination directory: #{e.message}"
            return
          end

          # Sync all files except excluded patterns
          Dir.glob(pages_path.join('**', '*')).each do |source|
            next if File.directory?(source)
            next if excluded?(source)

            relative = Pathname.new(source).relative_path_from(pages_path)
            dest = destination_path.join(relative)

            copy_file(source, dest, relative)
          end

          ReactiveView.logger.debug "[ReactiveView] Synced page files to #{destination_path}"
        end

        # Sync a single page file.
        #
        # @param source [String] Full path to the source file
        # @param pages_path [Pathname] Base pages directory
        # @return [Boolean] true if sync succeeded, false otherwise
        def sync_file(source, pages_path)
          return false unless File.exist?(source)
          return false if excluded?(source)

          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = destination_path.join(relative)

          copy_file(source, dest, relative)
        end

        # Remove a synced page file.
        #
        # @param relative [Pathname] Relative path from pages directory
        # @return [Boolean] true if removal succeeded, false otherwise
        def remove_file(relative)
          dest = destination_path.join(relative)
          return true unless dest.exist?

          begin
            FileUtils.rm(dest)
            cleanup_empty_directories(dest.dirname, destination_path)
            true
          rescue SystemCallError => e
            ReactiveView.logger.error "[ReactiveView] Failed to remove #{relative}: #{e.message}"
            false
          end
        end

        # Path where synced files are stored.
        #
        # @return [Pathname]
        def destination_path
          ReactiveView.configuration.working_directory_absolute_path.join('src', 'pages')
        end

        private

        # Copy a source file to destination with error handling.
        #
        # @param source [String] Source file path
        # @param dest [Pathname] Destination file path
        # @param relative [Pathname] Relative path for logging
        # @return [Boolean] true if copy succeeded, false otherwise
        def copy_file(source, dest, relative)
          FileUtils.mkdir_p(dest.dirname)
          FileUtils.cp(source, dest)
          ReactiveView.logger.debug "[ReactiveView] Synced: #{relative}"
          true
        rescue SystemCallError => e
          ReactiveView.logger.error "[ReactiveView] Failed to sync #{relative}: #{e.message}"
          false
        end

        # Check if a file should be excluded from syncing.
        #
        # @param path [String] File path to check
        # @return [Boolean] true if file should be excluded
        def excluded?(path)
          EXCLUDED_EXTENSIONS.any? { |ext| path.end_with?(ext) }
        end

        # Remove empty directories up to the base path.
        #
        # Walks up the directory tree removing empty directories until
        # it reaches the base path or finds a non-empty directory.
        #
        # @param dir [Pathname] Directory to check
        # @param base [Pathname] Base path to stop at
        def cleanup_empty_directories(dir, base)
          return if dir == base || !dir.to_s.start_with?(base.to_s)
          return unless dir.directory?
          return unless dir.empty?

          FileUtils.rmdir(dir)
          cleanup_empty_directories(dir.parent, base)
        rescue Errno::ENOENT
          # Directory was already removed (race condition) - that's fine
        rescue Errno::ENOTEMPTY
          # Directory is not empty - stop climbing
        rescue SystemCallError => e
          ReactiveView.logger.warn "[ReactiveView] Could not remove directory #{dir}: #{e.message}"
        end
      end
    end
  end
end
