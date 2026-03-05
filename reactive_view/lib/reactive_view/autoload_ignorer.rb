# frozen_string_literal: true

module ReactiveView
  module AutoloadIgnorer
    class << self
      def ignore_pages_paths!(pages_path:, autoloader:, logger: ReactiveView.logger)
        return { grouped_dirs: [], loader_files: [] } unless pages_path.exist?

        grouped_dirs = Dir.glob(pages_path.join('**/*')).select do |path|
          File.directory?(path) && File.basename(path).match?(/^\(.*\)$/)
        end

        loader_files = Dir.glob(pages_path.join('**/*.loader.rb')).select do |path|
          File.file?(path)
        end

        grouped_dirs.each do |dir|
          autoloader.ignore(dir)
          logger.debug "[ReactiveView] Ignoring grouped route directory for autoloading: #{dir}"
        end

        loader_files.each do |file|
          autoloader.ignore(file)
          logger.debug "[ReactiveView] Ignoring loader file for autoloading: #{file}"
        end

        if grouped_dirs.any? || loader_files.any?
          logger.info(
            '[ReactiveView] Configured autoloader ignores: ' \
            "#{grouped_dirs.size} grouped route #{grouped_dirs.size == 1 ? 'directory' : 'directories'}, " \
            "#{loader_files.size} loader #{loader_files.size == 1 ? 'file' : 'files'}"
          )
        end

        { grouped_dirs: grouped_dirs, loader_files: loader_files }
      end
    end
  end
end
