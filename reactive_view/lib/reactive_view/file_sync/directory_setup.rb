# frozen_string_literal: true

require 'json'

module ReactiveView
  class FileSync
    # Handles initial setup of the SolidStart working directory.
    # Copies the template from the gem and ensures root npm dependencies exist.
    class DirectorySetup
      EXCLUDED_TEMPLATE_ENTRIES = %w[node_modules .output .vinxi types].freeze

      REQUIRED_DEPENDENCIES = {
        '@reactive-view/core' => nil,
        '@solidjs/router' => '^0.15.3',
        '@solidjs/start' => '^1.0.12',
        'solid-js' => '^1.9.4',
        'vinxi' => '^0.5.3'
      }.freeze

      REQUIRED_DEV_DEPENDENCIES = {
        'typescript' => '^5.7.2'
      }.freeze

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
            copy_template_files(template_dir, working_dir)

            # Ensure generated routes directory exists
            FileUtils.mkdir_p(working_dir.join('src', 'routes'))
          end

          runtime_dependencies = required_runtime_dependencies
          missing_runtime = missing_packages(runtime_dependencies.keys)
          missing_dev = missing_packages(REQUIRED_DEV_DEPENDENCIES.keys)

          return if missing_runtime.empty? && missing_dev.empty?

          install_dependencies(runtime_dependencies, missing_runtime, missing_dev)
        end

        # Path to the gem's template directory
        #
        # @return [Pathname]
        def gem_template_path
          Pathname.new(__dir__).parent.parent.parent.join('template')
        end

        private

        # Install missing npm dependencies at Rails root
        #
        # @param runtime_dependencies [Hash{String => String}] Runtime dependency map
        # @param missing_runtime [Array<String>] Missing runtime package names
        # @param missing_dev [Array<String>] Missing dev package names
        # @raise [ReactiveView::Error] If npm install fails
        def install_dependencies(runtime_dependencies, missing_runtime, missing_dev)
          package_json = Rails.root.join('package.json')
          raise Error, 'Missing package.json at Rails root' unless package_json.exist?

          ReactiveView.logger.info '[ReactiveView] Installing missing root npm dependencies...'

          ensure_package_json_dependencies(package_json, runtime_dependencies, missing_runtime, missing_dev)

          Dir.chdir(Rails.root) do
            system('npm install --silent') ||
              raise(Error, 'Failed to install npm dependencies')
          end
        end

        # Returns missing package names by checking node_modules in Rails root.
        #
        # @param package_names [Enumerable<String>] Package names to verify
        # @return [Array<String>] Packages that are not installed
        def missing_packages(package_names)
          package_names.reject { |name| package_installed?(name) }
        end

        # Check whether a package exists in root node_modules.
        #
        # @param package_name [String] npm package name
        # @return [Boolean]
        def package_installed?(package_name)
          path_segments = package_name.split('/')
          current = Rails.root

          loop do
            return true if current.join('node_modules', *path_segments).exist?

            parent = current.parent
            break if parent == current

            current = parent
          end

          false
        end

        def required_runtime_dependencies
          REQUIRED_DEPENDENCIES.merge('@reactive-view/core' => reactive_view_core_version)
        end

        def reactive_view_core_version
          local_package = Pathname.new(__dir__).parent.parent.parent.join('npm')

          if local_package.exist?
            "file:#{local_package}"
          else
            "^#{ReactiveView::VERSION}"
          end
        end

        def ensure_package_json_dependencies(package_json_path, runtime_dependencies, missing_runtime, missing_dev)
          package_json = JSON.parse(package_json_path.read)
          updated = false

          package_json['dependencies'] ||= {}
          missing_runtime.each do |name|
            next if package_json['dependencies'].key?(name)

            package_json['dependencies'][name] = runtime_dependencies.fetch(name)
            updated = true
          end

          package_json['devDependencies'] ||= {}
          missing_dev.each do |name|
            next if package_json['devDependencies'].key?(name)

            package_json['devDependencies'][name] = REQUIRED_DEV_DEPENDENCIES.fetch(name)
            updated = true
          end

          return unless updated

          package_json_path.write(JSON.pretty_generate(package_json) + "\n")
        end

        def copy_template_files(template_dir, working_dir)
          Dir.children(template_dir).each do |entry|
            next if EXCLUDED_TEMPLATE_ENTRIES.include?(entry)

            FileUtils.cp_r(template_dir.join(entry), working_dir)
          end
        end
      end
    end
  end
end
