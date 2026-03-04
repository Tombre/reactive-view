# frozen_string_literal: true

require 'json'
require 'open3'

module ReactiveView
  class Doctor
    CORE_PACKAGE = '@reactive-view/core'
    MINIMUM_NODE_MAJOR = 18

    def initialize(rails_root: Rails.root, configuration: ReactiveView.configuration)
      @rails_root = Pathname.new(rails_root)
      @configuration = configuration
    end

    def diagnose
      checks = []

      node_check = check_node
      checks << node_check

      package_json_check = check_package_json
      checks << package_json_check

      package_json = package_json_check[:data]
      if package_json
        checks << check_core_dependency(package_json)
        checks << check_core_install(package_json)
      end

      working_dir_check = check_working_directory
      checks << working_dir_check
      checks << check_working_directory_config if working_dir_check[:ok]

      {
        checks: checks,
        ok: checks.all? { |check| check[:ok] }
      }
    end

    def report(io: $stdout)
      result = diagnose

      io.puts 'ReactiveView doctor'
      io.puts '-------------------'

      result[:checks].each do |check|
        label = check[:ok] ? 'OK  ' : 'FAIL'
        io.puts "[#{label}] #{check[:name]}: #{check[:message]}"
        io.puts "       Fix: #{check[:fix]}" if check[:fix]
      end

      if result[:ok]
        io.puts 'All checks passed.'
      else
        failures = result[:checks].count { |check| !check[:ok] }
        io.puts "Found #{failures} issue#{failures == 1 ? '' : 's'}."
      end

      result
    end

    private

    attr_reader :rails_root, :configuration

    def check_node
      output, status = capture_command('node', '-v')
      unless status
        return failed_check('Node.js', 'Node.js is not installed.',
                            'Install Node.js 18+ and ensure `node` is on PATH.')
      end

      major = output.to_s[/\d+/].to_i
      if major < MINIMUM_NODE_MAJOR
        return failed_check('Node.js', "Node.js #{output.strip} is too old.",
                            "Upgrade Node.js to #{MINIMUM_NODE_MAJOR}+.")
      end

      successful_check('Node.js', "Detected #{output.strip}.")
    end

    def check_package_json
      path = rails_root.join('package.json')
      unless path.exist?
        return failed_check('package.json', "Missing #{path}.",
                            'Create package.json at the Rails root and run npm install.')
      end

      successful_check('package.json', "Found #{path}.", data: JSON.parse(path.read))
    rescue JSON::ParserError => e
      failed_check('package.json', "Could not parse #{path}: #{e.message}",
                   'Fix package.json syntax and run the doctor again.')
    end

    def check_core_dependency(package_json)
      dependencies = package_json.fetch('dependencies', {}).merge(package_json.fetch('devDependencies', {}))
      version = dependencies[CORE_PACKAGE]

      unless version
        return failed_check(CORE_PACKAGE, "#{CORE_PACKAGE} is not declared in package.json.",
                            "Add #{CORE_PACKAGE} to dependencies and run npm install.")
      end

      successful_check(CORE_PACKAGE, "Dependency declared as #{version}.", data: version)
    end

    def check_core_install(package_json)
      dependencies = package_json.fetch('dependencies', {}).merge(package_json.fetch('devDependencies', {}))
      version = dependencies[CORE_PACKAGE]
      unless version
        return failed_check('Core package install', "#{CORE_PACKAGE} dependency is missing.",
                            "Add #{CORE_PACKAGE} to dependencies and run npm install.")
      end

      if version.start_with?('file:')
        local_path = rails_root.join(version.delete_prefix('file:')).expand_path
        cli_dist = local_path.join('dist', 'cli.js')

        unless cli_dist.exist?
          return failed_check('Local core build', "Missing built CLI at #{cli_dist}.",
                              "Run npm run build --prefix #{local_path}.")
        end

        return successful_check('Local core build', "Found built CLI at #{cli_dist}.")
      end

      installed_package = rails_root.join('node_modules', '@reactive-view', 'core', 'dist', 'cli.js')
      unless installed_package.exist?
        return failed_check('Installed core build', "Missing #{installed_package}.",
                            'Run npm install at the Rails root.')
      end

      successful_check('Installed core build', "Found built CLI at #{installed_package}.")
    end

    def check_working_directory
      working_dir = configuration.working_directory_absolute_path

      unless working_dir.exist?
        return failed_check('Working directory', "Missing #{working_dir}.",
                            'Run bin/rails reactive_view:setup.')
      end

      successful_check('Working directory', "Found #{working_dir}.")
    end

    def check_working_directory_config
      config_file = configuration.working_directory_absolute_path.join('app.config.ts')

      unless config_file.exist?
        return failed_check('Working directory config', "Missing #{config_file}.",
                            'Run bin/rails reactive_view:setup to regenerate the working directory.')
      end

      successful_check('Working directory config', "Found #{config_file}.")
    end

    def capture_command(*command)
      output, status = Open3.capture2e(*command)
      [output, status.success?]
    rescue Errno::ENOENT
      ['', false]
    end

    def successful_check(name, message, data: nil)
      {
        name: name,
        ok: true,
        message: message,
        fix: nil,
        data: data
      }
    end

    def failed_check(name, message, fix)
      {
        name: name,
        ok: false,
        message: message,
        fix: fix,
        data: nil
      }
    end
  end
end
