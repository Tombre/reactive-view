# frozen_string_literal: true

module ReactiveView
  # HTTP client that communicates with the SolidStart daemon for server-side rendering.
  #
  # The Renderer sends render requests to the SolidStart daemon, which:
  # 1. Receives the request with path and loader information
  # 2. Calls back to Rails to fetch loader data
  # 3. Renders the SolidJS component to HTML
  # 4. Returns the HTML to be sent to the browser
  #
  # @example Basic usage (typically called by Loader#call)
  #   renderer = ReactiveView::Renderer.new
  #   html = renderer.render(
  #     path: '/users/123',
  #     loader_path: 'users/[id]',
  #     rails_base_url: 'http://localhost:3000',
  #     cookies: request.headers['Cookie']
  #   )
  #
  # @example Checking daemon health
  #   renderer = ReactiveView::Renderer.new
  #   if renderer.healthy?
  #     # Daemon is running
  #   end
  #
  class Renderer
    # @return [String] The API endpoint path for render requests
    RENDER_PATH = '/api/render'

    # Creates a new Renderer instance.
    #
    # @param host [String, nil] Daemon host (defaults to configuration)
    # @param port [Integer, nil] Daemon port (defaults to configuration)
    # @param timeout [Integer, nil] Request timeout in seconds (defaults to configuration)
    def initialize(host: nil, port: nil, timeout: nil)
      @host = host || ReactiveView.configuration.daemon_host
      @port = port || ReactiveView.configuration.daemon_port
      @timeout = timeout || ReactiveView.configuration.daemon_timeout
    end

    # Render a page via the SolidStart daemon
    #
    # @param path [String] The URL path to render
    # @param loader_path [String] The loader path (e.g., "users/index")
    # @param rails_base_url [String] URL for SolidStart to call back to Rails
    # @param cookies [String, nil] Cookie header to forward for authenticated requests
    # @param csrf_token [String, nil] CSRF token to inject into rendered HTML for mutations
    # @return [String] Rendered HTML
    # @raise [DaemonUnavailableError] If the daemon is not responding
    # @raise [RenderError] If rendering fails
    def render(path:, loader_path:, rails_base_url:, cookies: nil, csrf_token: nil)
      response = connection.post(RENDER_PATH) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Accept'] = 'text/html'
        req.body = {
          path: path,
          loader_path: loader_path,
          rails_base_url: rails_base_url,
          cookies: cookies,
          csrf_token: csrf_token
        }.to_json
      end

      handle_response(response)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise DaemonUnavailableError, "SolidStart daemon is not available: #{e.message}"
    end

    # Checks if the SolidStart daemon is running and healthy.
    #
    # @return [Boolean] true if daemon responds successfully, false otherwise
    #
    # @example
    #   renderer = ReactiveView::Renderer.new
    #   renderer.healthy? # => true
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
          error_data = parse_json_body(response.body)
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
      error_info = parse_json_body(response.body, fallback: { 'error' => response.body })

      message = error_info['error'] || 'Internal server error'
      details = error_info['details'] || error_info['message']

      full_message = details ? "#{message}: #{details}" : message

      raise RenderError, full_message
    end

    def parse_json_body(body, fallback: nil)
      JSON.parse(body)
    rescue JSON::ParserError
      return fallback if fallback

      raise RenderError, 'Invalid JSON response from SolidStart daemon'
    end
  end
end
