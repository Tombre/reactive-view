# frozen_string_literal: true

module ReactiveView
  module AutoloadIgnorer
    class << self
      def ignore_pages_paths!(pages_path:, autoloaders:, logger: ReactiveView.logger)
        return { grouped_dirs: [], loader_files: [], guard_files: [] } unless pages_path.exist?

        autoloaders = Array(autoloaders).compact

        grouped_dirs = Dir.glob(pages_path.join('**/*')).select do |path|
          File.directory?(path) && File.basename(path).match?(/^\(.*\)$/)
        end

        loader_files = Dir.glob(pages_path.join('**/*.loader.rb')).select do |path|
          File.file?(path)
        end

        guard_files = Dir.glob(pages_path.join('**/_guard.rb')).select do |path|
          File.file?(path)
        end

        grouped_dirs.each do |dir|
          autoloaders.each { |autoloader| autoloader.ignore(dir) }
          logger.debug "[ReactiveView] Ignoring grouped route directory for autoloading: #{dir}"
        end

        loader_glob = pages_path.join('**/*.loader.rb').to_s
        autoloaders.each { |autoloader| autoloader.ignore(loader_glob) }
        logger.debug "[ReactiveView] Ignoring loader file glob for autoloading: #{loader_glob}"

        guard_glob = pages_path.join('**/_guard.rb').to_s
        autoloaders.each { |autoloader| autoloader.ignore(guard_glob) }
        logger.debug "[ReactiveView] Ignoring guard file glob for autoloading: #{guard_glob}"

        if grouped_dirs.any? || loader_files.any? || guard_files.any?
          logger.info(
            '[ReactiveView] Configured autoloader ignores: ' \
            "#{grouped_dirs.size} grouped route #{grouped_dirs.size == 1 ? 'directory' : 'directories'}, " \
            "#{loader_files.size} loader #{loader_files.size == 1 ? 'file' : 'files'}, " \
            "#{guard_files.size} guard #{guard_files.size == 1 ? 'file' : 'files'}"
          )
        end

        { grouped_dirs: grouped_dirs, loader_files: loader_files, guard_files: guard_files }
      end
    end
  end
end
