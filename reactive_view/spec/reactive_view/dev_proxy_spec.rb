# frozen_string_literal: true

require 'spec_helper'
require 'rack/mock'

RSpec.describe ReactiveView::DevProxy do
  let(:app) { ->(_env) { [200, { 'Content-Type' => 'text/html' }, ['Original App']] } }
  let(:middleware) { described_class.new(app) }

  before do
    ReactiveView.configure do |config|
      config.daemon_host = 'localhost'
      config.daemon_port = 3001
    end
  end

  describe '#call' do
    context 'when path does not match proxy paths' do
      it 'passes through to the app for regular routes' do
        env = Rack::MockRequest.env_for('/users')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['Original App'])
      end

      it 'passes through to the app for root path' do
        env = Rack::MockRequest.env_for('/')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['Original App'])
      end

      it 'passes through to the app for API routes' do
        env = Rack::MockRequest.env_for('/api/data')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['Original App'])
      end
    end

    context 'when path matches proxy paths' do
      before do
        stub_request(:get, 'http://localhost:3001/_build/@vite/client')
          .to_return(status: 200, body: 'vite client code', headers: { 'Content-Type' => 'application/javascript' })

        stub_request(:get, 'http://localhost:3001/_build/@fs/path/to/file.js')
          .to_return(status: 200, body: 'file content', headers: { 'Content-Type' => 'application/javascript' })

        stub_request(:get, 'http://localhost:3001/@vite/client')
          .to_return(status: 200, body: 'vite hmr', headers: { 'Content-Type' => 'application/javascript' })

        stub_request(:get, 'http://localhost:3001/@fs/some/file.ts')
          .to_return(status: 200, body: 'typescript', headers: { 'Content-Type' => 'application/typescript' })
      end

      it 'proxies /_build/@vite/* requests' do
        env = Rack::MockRequest.env_for('/_build/@vite/client')
        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['vite client code'])
      end

      it 'proxies /_build/@fs/* requests' do
        env = Rack::MockRequest.env_for('/_build/@fs/path/to/file.js')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['file content'])
      end

      it 'proxies /@vite/* requests' do
        env = Rack::MockRequest.env_for('/@vite/client')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['vite hmr'])
      end

      it 'proxies /@fs/* requests' do
        env = Rack::MockRequest.env_for('/@fs/some/file.ts')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['typescript'])
      end
    end

    context 'when query strings are present' do
      before do
        stub_request(:get, 'http://localhost:3001/_build/@vite/client?t=123456')
          .to_return(status: 200, body: 'cached response', headers: {})
      end

      it 'forwards query strings to the daemon' do
        env = Rack::MockRequest.env_for('/_build/@vite/client?t=123456')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['cached response'])
      end
    end

    context 'when query strings have duplicate keys' do
      before do
        # Vinxi uses pick=default&pick=$css for lazy route loading
        stub_request(:get, 'http://localhost:3001/_build/@fs/src/routes/index.tsx')
          .with(query: { 'pick' => %w[default $css] })
          .to_return(status: 200, body: 'export default Component', headers: { 'Content-Type' => 'text/javascript' })
      end

      it 'preserves duplicate query parameters' do
        env = Rack::MockRequest.env_for('/_build/@fs/src/routes/index.tsx?pick=default&pick=$css')
        status, _, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(['export default Component'])
      end
    end

    context 'when daemon is unavailable' do
      before do
        stub_request(:get, 'http://localhost:3001/_build/@vite/client')
          .to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'returns a 502 error with helpful message' do
        env = Rack::MockRequest.env_for('/_build/@vite/client')
        status, _, body = middleware.call(env)

        expect(status).to eq(502)
        expect(body.first).to include('Unable to connect to dev server')
      end
    end

    context 'when daemon times out' do
      before do
        stub_request(:get, 'http://localhost:3001/_build/@vite/client')
          .to_raise(Faraday::TimeoutError.new('timeout'))
      end

      it 'returns a 502 error' do
        env = Rack::MockRequest.env_for('/_build/@vite/client')
        status, = middleware.call(env)

        expect(status).to eq(502)
      end
    end
  end

  describe 'PROXY_PATHS regex' do
    it 'matches /_build/ paths' do
      expect('/_build/something').to match(ReactiveView::DevProxy::PROXY_PATHS)
      expect('/_build/@vite/client').to match(ReactiveView::DevProxy::PROXY_PATHS)
    end

    it 'matches /@vite/ paths' do
      expect('/@vite/client').to match(ReactiveView::DevProxy::PROXY_PATHS)
    end

    it 'matches /@fs/ paths' do
      expect('/@fs/path/to/file').to match(ReactiveView::DevProxy::PROXY_PATHS)
    end

    it 'does not match regular paths' do
      expect('/users').not_to match(ReactiveView::DevProxy::PROXY_PATHS)
      expect('/').not_to match(ReactiveView::DevProxy::PROXY_PATHS)
      expect('/api/render').not_to match(ReactiveView::DevProxy::PROXY_PATHS)
    end
  end
end
