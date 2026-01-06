# frozen_string_literal: true

module ReactiveView
  # Synchronizes TSX files from app/pages to the SolidStart working directory.
  # In development, watches for changes and syncs automatically.
  class FileSync
    class << self
      # Sync all TSX files from pages to the working directory
      def sync_all
        setup_working_directory
        sync_tsx_files
        sync_loader_types
      end

      # Start watching for file changes (development only)
      def start_watching
        return if @listener

        pages_path = ReactiveView.configuration.pages_absolute_path
        return unless pages_path.exist?

        @listener = Listen.to(pages_path.to_s, only: /\.(tsx|ts)$/) do |modified, added, removed|
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
      def handle_changes(modified, added, removed)
        pages_path = ReactiveView.configuration.pages_absolute_path
        routes_path = ReactiveView.configuration.working_directory_absolute_path.join('src', 'routes')

        # Handle added and modified files
        (modified + added).each do |source|
          next unless source.end_with?('.tsx', '.ts')
          next if source.end_with?('.loader.rb')

          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = routes_path.join(relative)

          FileUtils.mkdir_p(dest.dirname)
          FileUtils.cp(source, dest)

          ReactiveView.logger.debug "[ReactiveView] Synced: #{relative}"
        end

        # Handle removed files
        removed.each do |source|
          next unless source.end_with?('.tsx', '.ts')

          relative = Pathname.new(source).relative_path_from(pages_path)
          dest = routes_path.join(relative)

          next unless dest.exist?

          FileUtils.rm(dest)
          ReactiveView.logger.debug "[ReactiveView] Removed: #{relative}"

          # Clean up empty directories
          cleanup_empty_directories(dest.dirname, routes_path)
        end

        # Regenerate types if any loader files changed
        return unless (modified + added + removed).any? { |f| f.end_with?('.loader.rb') }

        sync_loader_types
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
