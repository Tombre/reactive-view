# frozen_string_literal: true

module ReactiveView
  # Helper module for reading and rendering template files.
  # Templates use %{variable} syntax for string interpolation.
  module Templates
    TEMPLATES_PATH = Pathname.new(__dir__).join('templates')

    class << self
      # Read a template file and optionally interpolate variables
      #
      # @param path [String] Relative path to the template file
      # @param variables [Hash] Variables to interpolate into the template
      # @return [String] The template content with variables interpolated
      #
      # @example
      #   Templates.render('error_pages/daemon_unavailable.html',
      #     error_message: 'Connection refused',
      #     working_directory: '.reactive_view'
      #   )
      def render(path, variables = {})
        template = read(path)
        return template if variables.empty?

        template % variables
      end

      # Read a raw template file without interpolation
      #
      # @param path [String] Relative path to the template file
      # @return [String] The raw template content
      def read(path)
        template_path = TEMPLATES_PATH.join(path)
        template_path.read
      end
    end
  end
end
