# frozen_string_literal: true

module ReactiveView
  # Registry for folder-level guard classes discovered from app/pages/**/_guard.rb files.
  class GuardRegistry
    class << self
      # Load all guard files from the pages directory.
      def load_all
        return unless pages_path.exist?

        guard_files.each do |file|
          require file
        rescue LoadError => e
          ReactiveView.logger.error "[ReactiveView] Failed to load #{file}: #{e.message}"
        end
      end

      # Find all guard files.
      #
      # @return [Array<String>]
      def guard_files
        Dir.glob(pages_path.join('**', '_guard.rb'))
      end

      # Resolve all guard classes that apply to a loader path.
      #
      # @param loader_path [String]
      # @return [Array<Class>]
      def classes_for_loader_path(loader_path)
        guard_paths_for_loader_path(loader_path).filter_map do |guard_path|
          class_for_guard_path(guard_path)
        end
      end

      # Convert a guard file path to a guard path.
      #
      # @param file_path [Pathname, String]
      # @return [String] empty string means root guard
      def file_to_guard_path(file_path)
        relative = Pathname.new(file_path).relative_path_from(pages_path)
        relative.to_s.sub(%r{/_guard\.rb$}, '').sub(/^_guard\.rb$/, '')
      end

      # Resolve a guard path to its class.
      #
      # @param guard_path [String] empty string means root guard
      # @return [Class, nil]
      def class_for_guard_path(guard_path)
        class_name = path_to_class_name(guard_path)
        klass = class_name.constantize
        return klass if klass <= ReactiveView::RouteGuard

        ReactiveView.logger.warn "[ReactiveView] Ignoring #{class_name} because it is not a ReactiveView::RouteGuard"
        nil
      rescue NameError
        nil
      end

      # Convert a guard path to class name.
      #
      # Examples:
      #   "" -> "Pages::Guard"
      #   "users" -> "Pages::Users::Guard"
      #   "(admin)/dashboard" -> "Pages::Admin::Dashboard::Guard"
      #
      # @param guard_path [String]
      # @return [String]
      def path_to_class_name(guard_path)
        normalized = guard_path.to_s.sub(%r{^/+|/+$}, '')
        return 'Pages::Guard' if normalized.empty?

        segments = normalized.split('/').map { |segment| normalize_segment(segment) }
        "Pages::#{segments.map(&:camelize).join('::')}::Guard"
      end

      private

      def pages_path
        ReactiveView.configuration.pages_absolute_path
      end

      def guard_paths_for_loader_path(loader_path)
        normalized_loader_path = loader_path.to_s.sub(%r{^/+|/+$}, '')
        return [''] if normalized_loader_path.empty?

        file_parent = File.dirname(normalized_loader_path)
        file_parent = '' if file_parent == '.'

        guard_paths = ancestor_paths(file_parent)

        loader_path_as_directory = pages_path.join(normalized_loader_path)
        guard_paths |= ancestor_paths(normalized_loader_path) if loader_path_as_directory.directory?

        guard_paths.sort_by do |path|
          depth = path.empty? ? 0 : path.split('/').length
          [depth, path]
        end
      end

      def ancestor_paths(path)
        normalized = path.to_s.sub(%r{^/+|/+$}, '')
        return [''] if normalized.empty?

        segments = normalized.split('/')
        [''] + (1..segments.length).map { |idx| segments.first(idx).join('/') }
      end

      # Normalize a path segment to a valid Ruby identifier
      # [id] -> id
      # [...slug] -> slug
      # [[optional]] -> optional
      # (admin) -> admin (grouped routes)
      def normalize_segment(segment)
        segment
          .gsub(/\[\.\.\.(.*?)\]/, '\\1')
          .gsub(/\[\[(.*?)\]\]/, '\\1')
          .gsub(/\[(.*?)\]/, '\\1')
          .gsub(/\((.*?)\)/, '\\1')
      end
    end
  end
end
