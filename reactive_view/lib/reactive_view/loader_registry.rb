# frozen_string_literal: true

module ReactiveView
  # Registry for managing loader classes discovered from app/pages/*.loader.rb files.
  # Handles manual loading of loaders since Zeitwerk doesn't easily support the
  # unconventional [param].loader.rb naming pattern.
  class LoaderRegistry
    class << self
      # Load all loader files from the pages directory
      def load_all
        return unless pages_path.exist?

        loader_files.each do |file|
          require file
        rescue LoadError => e
          ReactiveView.logger.error "[ReactiveView] Failed to load #{file}: #{e.message}"
        end
      end

      # Find loader files
      def loader_files
        Dir.glob(pages_path.join('**', '*.loader.rb'))
      end

      # Get the loader class for a given path, or return the default Loader
      #
      # @param loader_path [String] The loader path (e.g., "users/[id]")
      # @return [Class] The loader class or ReactiveView::Loader
      def class_for_path(loader_path)
        class_name = path_to_class_name(loader_path)

        begin
          class_name.constantize
        rescue NameError
          ReactiveView::Loader
        end
      end

      # Convert a loader path to its expected class name
      #
      # Examples:
      #   "index" -> "Pages::IndexLoader"
      #   "users/index" -> "Pages::Users::IndexLoader"
      #   "users/[id]" -> "Pages::Users::IdLoader"
      #   "blog/[...slug]" -> "Pages::Blog::SlugLoader"
      #
      # @param loader_path [String] The path from the file system
      # @return [String] The expected class name
      def path_to_class_name(loader_path)
        segments = loader_path.split('/').map do |segment|
          normalize_segment(segment)
        end

        "Pages::#{segments.map(&:camelize).join('::')}Loader"
      end

      # Convert a file path to a loader path
      #
      # @param file_path [Pathname, String] Full path to the .loader.rb file
      # @return [String] The loader path
      def file_to_loader_path(file_path)
        relative = Pathname.new(file_path).relative_path_from(pages_path)
        relative.to_s.sub(/\.loader\.rb$/, '')
      end

      # Get all registered loader paths
      def all_loader_paths
        loader_files.map { |f| file_to_loader_path(f) }
      end

      private

      def pages_path
        ReactiveView.configuration.pages_absolute_path
      end

      # Normalize a path segment to a valid Ruby identifier
      # [id] -> id
      # [...slug] -> slug
      # [[optional]] -> optional
      # (admin) -> admin (grouped routes)
      def normalize_segment(segment)
        segment
          .gsub(/\[\.\.\.(.*?)\]/, '\1') # [...param] -> param
          .gsub(/\[\[(.*?)\]\]/, '\1')     # [[optional]] -> optional
          .gsub(/\[(.*?)\]/, '\1')         # [param] -> param
          .gsub(/\((.*?)\)/, '\1')         # (group) -> group (grouped routes)
      end
    end
  end
end
