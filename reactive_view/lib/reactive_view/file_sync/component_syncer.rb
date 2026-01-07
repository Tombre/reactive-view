# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Syncs TSX/TS page components from app/pages to the SolidStart working directory.
    # Handles copying, updating, and removing synced files.
    class ComponentSyncer
      class << self
        # Sync all page components to the working directory
        #
        # @return [void]
        def sync_all
          pages_path = ReactiveView.configuration.pages_absolute_path
          return unless pages_path.exist?

          FileUtils.rm_rf(destination_path) if destination_path.exist?
          FileUtils.mkdir_p(destination_path)

          Dir.glob(pages_path.join('**', '*.{ts,tsx}')).each do |source|
            relative = Pathname.new(source).relative_path_from(pages_path)
            dest = destination_path.join(relative)

            FileUtils.mkdir_p(dest.dirname)
            FileUtils.cp(source, dest)
          end

          ReactiveView.logger.debug "[ReactiveView] Synced page components to #{destination_path}"
        end

        # Sync a single page file
        #
        # @param source [String] Full path to the source file
        # @param pages_path [Pathname] Base pages directory
        # @return [void]
        def sync_file(source, pages_path)
          return unless File.exist?(source)

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

        # Path where synced components are stored
        #
        # @return [Pathname]
        def destination_path
          ReactiveView.configuration.working_directory_absolute_path.join('src', 'pages')
        end

        private

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
