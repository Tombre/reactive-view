# frozen_string_literal: true

module ReactiveView
  class FileSync
    # Handles initial setup of the SolidStart working directory.
    # Copies the template from the gem and installs npm dependencies.
    class DirectorySetup
      class << self
        # Setup the SolidStart working directory from the template
        #
        # @return [void]
        def setup
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

        # Path to the gem's template directory
        #
        # @return [Pathname]
        def gem_template_path
          Pathname.new(__dir__).parent.parent.parent.join('template')
        end

        private

        # Install npm dependencies in the working directory
        #
        # @param working_dir [Pathname] The working directory path
        # @raise [ReactiveView::Error] If npm install fails
        def install_dependencies(working_dir)
          ReactiveView.logger.info '[ReactiveView] Installing npm dependencies...'

          Dir.chdir(working_dir) do
            system('npm install --silent') || raise(Error, 'Failed to install npm dependencies')
          end
        end
      end
    end
  end
end
