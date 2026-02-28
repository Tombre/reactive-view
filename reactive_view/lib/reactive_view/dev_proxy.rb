# frozen_string_literal: true

require 'faraday'
require 'uri'

module ReactiveView
  # Rack middleware that proxies development asset requests to the Vinxi dev server.
  # In development, Vinxi serves assets from /_build/* paths which need to be
  # forwarded from Rails to the Vinxi server.
  #
  # Proxied paths:
  #   /_build/* - Vite/Vinxi build assets
  #   /@vite/*  - Vite HMR and client
  #   /@fs/*    - Vite filesystem access
  #
  # Note: WebSocket connections for HMR are NOT proxied through Rails.
  # Instead, Vite is configured to connect directly to port 3001 for WebSocket HMR.
  # This is more reliable than proxying WebSockets through Rack middleware.
  #
  class DevProxy
    # Paths that should be proxied to the Vite dev server
    PROXY_PATHS = %r{^/(_build|@vite|@fs)/}

    def initialize(app)
      @app = app
      @connection = nil
    end

    def call(env)
      request_path = env['PATH_INFO']

      if should_proxy?(request_path)
        proxy_request(env)
      else
        @app.call(env)
      end
    end

    private

    def should_proxy?(path)
      path.match?(PROXY_PATHS)
    end

    def proxy_request(env)
      daemon_url = ReactiveView.configuration.daemon_url
      request_path = env['PATH_INFO']
      query_string = env['QUERY_STRING']

      # URI-encode the path to handle special characters like square brackets in [id].tsx
      # We encode individual path segments to preserve the path structure
      encoded_path = encode_path(request_path)
      target_url = "#{daemon_url}#{encoded_path}"

      # Parse query string to preserve duplicate keys (e.g., pick=default&pick=$css)
      # Faraday doesn't handle duplicate query params correctly when passed in URL
      query_params = query_string && !query_string.empty? ? Rack::Utils.parse_query(query_string) : {}

      begin
        response = make_request(connection, env, target_url, query_params)

        build_response(response)
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        ReactiveView.logger.error "[ReactiveView] DevProxy connection failed: #{e.message}"
        [502, { 'Content-Type' => 'text/plain' }, ["ReactiveView: Unable to connect to dev server at #{daemon_url}"]]
      rescue StandardError => e
        ReactiveView.logger.error "[ReactiveView] DevProxy error: #{e.message}"
        [500, { 'Content-Type' => 'text/plain' }, ["ReactiveView: Proxy error - #{e.message}"]]
      end
    end

    def connection
      @connection ||= Faraday.new do |f|
        f.options.timeout = 30
        f.options.open_timeout = 5
        f.adapter Faraday.default_adapter
      end
    end

    def make_request(connection, env, target_url, query_params = {})
      method = env['REQUEST_METHOD'].downcase.to_sym

      connection.run_request(method, target_url, nil, {}) do |req|
        # Set query params separately to preserve duplicate keys
        req.params = query_params unless query_params.empty?

        # Forward relevant headers
        forward_headers(env, req)

        # Forward request body for POST/PUT/PATCH
        if %i[post put patch].include?(method)
          req.body = env['rack.input'].read
          env['rack.input'].rewind
        end
      end
    end

    def forward_headers(env, req)
      # Standard headers to forward
      %w[
        HTTP_ACCEPT
        HTTP_ACCEPT_ENCODING
        HTTP_ACCEPT_LANGUAGE
        HTTP_CACHE_CONTROL
        HTTP_COOKIE
        HTTP_HOST
        HTTP_REFERER
        HTTP_USER_AGENT
        CONTENT_TYPE
        CONTENT_LENGTH
      ].each do |header|
        next unless env[header]

        # Convert rack header format to HTTP header format
        http_header = header.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
        http_header = 'Content-Type' if header == 'CONTENT_TYPE'
        http_header = 'Content-Length' if header == 'CONTENT_LENGTH'

        req.headers[http_header] = env[header]
      end
    end

    def build_response(response)
      status = response.status
      headers = filter_response_headers(response.headers)
      body = [response.body]

      # Fix MIME types for JavaScript modules
      # Vite/Vinxi sometimes returns text/html for JS files incorrectly
      headers = fix_content_type(headers, body.first)

      [status, headers, body]
    end

    # Fix Content-Type for JavaScript modules that Vite incorrectly serves as text/html
    #
    # @param headers [Hash] Response headers
    # @param body [String] Response body
    # @return [Hash] Headers with corrected Content-Type if needed
    def fix_content_type(headers, body)
      content_type = headers['content-type'] || headers['Content-Type']

      # If Content-Type is text/html but body looks like JavaScript module, fix it
      if content_type&.include?('text/html') && body.is_a?(String)
        # Check if body starts with JavaScript patterns
        trimmed = body.lstrip
        if trimmed.start_with?('import ', 'export ', 'const ', 'let ', 'var ', 'function ', 'class ', '//', '/*')
          headers = headers.dup
          headers['content-type'] = 'application/javascript'
          headers.delete('Content-Type')
        end
      end

      headers
    end

    def filter_response_headers(headers)
      # Filter out hop-by-hop headers that shouldn't be proxied
      hop_by_hop = %w[
        connection
        keep-alive
        proxy-authenticate
        proxy-authorization
        te
        trailers
        transfer-encoding
        upgrade
      ]

      headers.to_h.reject { |k, _| hop_by_hop.include?(k.downcase) }
    end

    # Encode path segments to handle special characters like square brackets
    # in dynamic route files (e.g., [id].tsx)
    #
    # Note: We preserve '@' symbols as Vite uses them for special paths:
    # - @vite/client - Vite HMR client
    # - @fs/* - Filesystem access
    def encode_path(path)
      path.split('/').map do |segment|
        # Encode the segment but restore @ symbols which Vite requires unencoded
        URI.encode_www_form_component(segment).gsub('%40', '@')
      end.join('/')
    end
  end
end
