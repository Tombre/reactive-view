# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Syncs page files from app/pages to the SolidStart working directory.
    # Syncs all files except Ruby loader files, allowing Vite to handle
    # any asset type (CSS, SCSS, images, etc.).
    class ComponentSyncer
      # File patterns to exclude from syncing (Ruby server-side files)
      EXCLUDED_EXTENSIONS = %w[.loader.rb].freeze

      class << self
        # Sync all page files to the working directory
        #
        # @return [void]
        def sync_all
          pages_path = ReactiveView.configuration.pages_absolute_path
          return unless pages_path.exist?

          FileUtils.rm_rf(destination_path) if destination_path.exist?
          FileUtils.mkdir_p(destination_path)

          # Sync all files except excluded patterns
          Dir.glob(pages_path.join('**', '*')).each do |source|
            next if File.directory?(source)
            next if excluded?(source)

            relative = Pathname.new(source).relative_path_from(pages_path)
            dest = destination_path.join(relative)

            FileUtils.mkdir_p(dest.dirname)
            FileUtils.cp(source, dest)
          end

          ReactiveView.logger.debug "[ReactiveView] Synced page files to #{destination_path}"
        end

        # Sync a single page file
        #
        # @param source [String] Full path to the source file
        # @param pages_path [Pathname] Base pages directory
        # @return [void]
        def sync_file(source, pages_path)
          return unless File.exist?(source)
          return if excluded?(source)

          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = destination_path.join(relative)

          FileUtils.mkdir_p(dest.dirname)
          FileUtils.cp(source, dest)

          ReactiveView.logger.debug "[ReactiveView] Synced: #{relative}"
        end

        # Remove a synced page file
        #
        # @param relative [Pathname] Relative path from pages directory
        # @return [void]
        def remove_file(relative)
          dest = destination_path.join(relative)
          return unless dest.exist?

          FileUtils.rm(dest)
          cleanup_empty_directories(dest.dirname, destination_path)
        end

        # Path where synced files are stored
        #
        # @return [Pathname]
        def destination_path
          ReactiveView.configuration.working_directory_absolute_path.join('src', 'pages')
        end

        private

        # Check if a file should be excluded from syncing
        #
        # @param path [String] File path to check
        # @return [Boolean] true if file should be excluded
        def excluded?(path)
          EXCLUDED_EXTENSIONS.any? { |ext| path.end_with?(ext) }
        end

        # Remove empty directories up to the base path
        #
        # @param dir [Pathname] Directory to check
        # @param base [Pathname] Base path to stop at
        def cleanup_empty_directories(dir, base)
          return if dir == base || !dir.to_s.start_with?(base.to_s)
          return unless dir.directory? && dir.empty?

          FileUtils.rmdir(dir)
          cleanup_empty_directories(dir.parent, base)
        end
      end
    end
  end
end
