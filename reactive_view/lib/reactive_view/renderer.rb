# frozen_string_literal: true

module ReactiveView
  # HTTP client that communicates with the SolidStart daemon.
  # Requests page renders and returns the HTML.
  class Renderer
    RENDER_PATH = '/api/render'

    def initialize(host: nil, port: nil, timeout: nil)
      @host = host || ReactiveView.configuration.daemon_host
      @port = port || ReactiveView.configuration.daemon_port
      @timeout = timeout || ReactiveView.configuration.daemon_timeout
    end

    # Render a page via the SolidStart daemon
    #
    # @param path [String] The URL path to render
    # @param request_token [String] Token for SolidStart to fetch loader data
    # @param rails_base_url [String] URL for SolidStart to call back to Rails
    # @return [String] Rendered HTML
    # @raise [DaemonUnavailableError] If the daemon is not responding
    # @raise [RenderError] If rendering fails
    def render(path:, request_token:, rails_base_url:)
      response = connection.post(RENDER_PATH) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'text/html'
        req.body = {
          path: path,
          request_token: request_token,
          rails_base_url: rails_base_url
        }.to_json
      end

      handle_response(response)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise DaemonUnavailableError, "SolidStart daemon is not available: #{e.message}"
    end

    # Check if the daemon is healthy
    #
    # @return [Boolean]
    def healthy?
      response = connection.get(RENDER_PATH)
      response.success?
    rescue Faraday::Error
      false
    end

    private

    def connection
      @connection ||= Faraday.new(url: daemon_url) do |f|
        f.options.timeout = @timeout
        f.options.open_timeout = 5
        f.adapter Faraday.default_adapter
      end
    end

    def daemon_url
      "http://#{@host}:#{@port}"
    end

    def handle_response(response)
      case response.status
      when 200
        # Check if response is HTML or JSON error
        content_type = response.headers['content-type'] || ''

        if content_type.include?('text/html')
          response.body
        elsif content_type.include?('application/json')
          # JSON response usually means an error
          error_data = JSON.parse(response.body)
          raise RenderError, error_data['error'] || 'Unknown render error'
        else
          response.body
        end
      when 404
        raise RenderError, "Page not found: #{response.body}"
      when 500
        handle_error_response(response)
      else
        raise RenderError, "Unexpected response status: #{response.status}"
      end
    end

    def handle_error_response(response)
      error_info = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { 'error' => response.body }
      end

      message = error_info['error'] || 'Internal server error'
      details = error_info['details'] || error_info['message']

      full_message = details ? "#{message}: #{details}" : message

      raise RenderError, full_message
    end
  end
end
