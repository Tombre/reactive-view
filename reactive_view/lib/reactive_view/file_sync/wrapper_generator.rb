# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Generates thin wrapper files in src/routes that re-export page components.
    # This pattern enables HMR to work correctly - edits to page components
    # don't trigger full page reloads because the route files remain unchanged.
    class WrapperGenerator
      class << self
        # Generate route wrappers for all pages
        #
        # @return [void]
        def generate_all
          pages_path = ReactiveView.configuration.pages_absolute_path
          return unless pages_path.exist?

          FileUtils.mkdir_p(routes_path)

          # Clean old wrappers except api directory
          Dir.glob(routes_path.join('*')).each do |path|
            next if File.basename(path) == 'api'

            FileUtils.rm_rf(path)
          end

          Dir.glob(pages_path.join('**', '*.tsx')).each do |source|
            relative = Pathname.new(source).relative_path_from(pages_path)

            # Skip private paths - they don't need route wrappers
            next if FileSync.private_path?(relative)

            generate_wrapper(relative, pages_path)
          end

          ReactiveView.logger.debug "[ReactiveView] Generated route wrappers in #{routes_path}"
        end

        # Generate a wrapper for a single page
        #
        # @param relative_path [Pathname] Relative path to the TSX file
        # @param pages_path [Pathname] Base pages directory
        # @return [Boolean] true if generation succeeded
        def generate_wrapper(relative_path, pages_path)
          dest = routes_path.join(relative_path)
          import_path = calculate_import_path(relative_path)
          component_path = relative_path.to_s.sub(/\.tsx$/, '')
          has_loader = loader_exists?(relative_path, pages_path)

          wrapper_content = if layout?(relative_path, pages_path)
                              layout_wrapper_template(import_path, component_path)
                            else
                              page_wrapper_template(import_path, component_path, has_loader)
                            end

          AtomicWriter.write(dest, wrapper_content)
        rescue SystemCallError => e
          ReactiveView.logger.error "[ReactiveView] Failed to generate wrapper for #{relative_path}: #{e.message}"
          false
        end

        # Remove a wrapper file
        #
        # @param relative [Pathname] Relative path from pages directory
        # @return [void]
        def remove_wrapper(relative)
          dest = routes_path.join(relative)
          return unless dest.exist?

          FileUtils.rm(dest)
          cleanup_empty_directories(dest.dirname, routes_path)
        end

        # Regenerate the parent layout wrapper when children change
        #
        # @param relative_path [Pathname] Path of the changed file
        # @param pages_path [Pathname] Base pages directory
        # @return [void]
        def regenerate_parent_layout(relative_path, pages_path)
          parent = relative_path.dirname
          return if parent.to_s.empty? || parent.to_s == '.'

          layout_candidate = Pathname.new("#{parent}.tsx")
          layout_source = pages_path.join(layout_candidate)
          return unless layout_source.exist?

          generate_wrapper(layout_candidate, pages_path)
        end

        # Path where route wrappers are stored
        #
        # @return [Pathname]
        def routes_path
          ReactiveView.configuration.working_directory_absolute_path.join('src', 'routes')
        end

        private

        # Calculate the import path from a route to its page component
        #
        # In development, uses the ~pages/ Vite alias to import directly from
        # app/pages/ (no file copying needed). In production, uses relative paths
        # to the copied files in .reactive_view/src/pages/.
        #
        # @param relative_path [Pathname] Relative path to the TSX file
        # @return [String] Import path for the component
        def calculate_import_path(relative_path)
          if Rails.env.development?
            # Use Vite alias to resolve directly from app/pages
            path = relative_path.to_s.sub(/\.tsx$/, '')
            "~pages/#{path.tr('\\', '/')}"
          else
            # Production: use relative path to copied files in src/pages
            route_dir = routes_path.join(relative_path).dirname
            page_file = ComponentSyncer.destination_path.join(relative_path)
            path = page_file.relative_path_from(route_dir).to_s
            path = path.sub(/\.tsx$/, '')
            path.tr('\\', '/')
          end
        end

        # Check if a file is a layout (has a folder with the same name)
        #
        # @param relative_path [Pathname] Path to the file
        # @param pages_path [Pathname] Base pages directory
        # @return [Boolean]
        def layout?(relative_path, pages_path)
          dir_name = relative_path.to_s.sub(/\.tsx$/, '')
          pages_path.join(dir_name).directory?
        end

        # Check if a loader file exists for the given route
        #
        # @param relative_path [Pathname] Path to the TSX file
        # @param pages_path [Pathname] Base pages directory
        # @return [Boolean]
        def loader_exists?(relative_path, pages_path)
          loader_path = relative_path.to_s.sub(/\.tsx$/, '.loader.rb')
          pages_path.join(loader_path).exist?
        end

        # Convert a TSX relative path to its loader type import path
        #
        # @param relative_path [Pathname] Path to the TSX file
        # @return [String] Loader type import path
        def loader_type_path(relative_path)
          route_path = relative_path.to_s.sub(/\.tsx$/, '')
          "#loaders/#{route_path}"
        end

        # Remove empty directories up to the base path
        def cleanup_empty_directories(dir, base)
          return if dir == base || !dir.to_s.start_with?(base.to_s)
          return unless dir.directory? && dir.empty?

          FileUtils.rmdir(dir)
          cleanup_empty_directories(dir.parent, base)
        end

        # Template for page wrapper files
        #
        # @param import_path [String] Import path to the component
        # @param component_path [String] Path for comments
        # @param has_loader [Boolean] Whether the page has a loader
        # @return [String] TypeScript wrapper content
        def page_wrapper_template(import_path, component_path, has_loader)
          loader_import = if has_loader
                            Templates.render('wrappers/loader_preload.ts.template',
                                             loader_type_path: loader_type_path(Pathname.new(component_path + '.tsx')))
                          else
                            ''
                          end

          Templates.render('wrappers/page_wrapper.ts.template',
                           component_path: component_path,
                           import_path: import_path,
                           loader_import: loader_import)
        end

        # Template for layout wrapper files
        #
        # @param import_path [String] Import path to the component
        # @param component_path [String] Path for comments
        # @return [String] TypeScript wrapper content
        def layout_wrapper_template(import_path, component_path)
          Templates.render('wrappers/layout_wrapper.ts.template',
                           component_path: component_path,
                           import_path: import_path)
        end
      end
    end
  end
end
