# frozen_string_literal: true

require 'spec_helper'

# Load the renderer
require 'reactive_view/renderer'

RSpec.describe ReactiveView::Renderer do
  let(:renderer) { described_class.new }

  before do
    ReactiveView.configure do |config|
      config.daemon_host = 'localhost'
      config.daemon_port = 3001
      config.daemon_timeout = 30
    end
  end

  describe '#render' do
    let(:render_params) do
      {
        path: '/users/123',
        loader_path: 'users/[id]',
        rails_base_url: 'http://localhost:3000',
        cookies: 'session=abc123'
      }
    end

    context 'when daemon returns HTML successfully' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_return(
            status: 200,
            body: '<html><body>Hello World</body></html>',
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'returns the HTML body' do
        result = renderer.render(**render_params)

        expect(result).to eq('<html><body>Hello World</body></html>')
      end
    end

    context 'when daemon returns JSON error with 200 status' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_return(
            status: 200,
            body: { error: 'Component failed to render' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises RenderError with the error message' do
        expect { renderer.render(**render_params) }
          .to raise_error(ReactiveView::RenderError, 'Component failed to render')
      end
    end

    context 'when daemon returns 404' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_return(status: 404, body: 'Page not found')
      end

      it 'raises RenderError with page not found message' do
        expect { renderer.render(**render_params) }
          .to raise_error(ReactiveView::RenderError, /Page not found/)
      end
    end

    context 'when daemon returns 500 with JSON error' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_return(
            status: 500,
            body: { error: 'Internal error', details: 'Stack trace here' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises RenderError with error and details' do
        expect { renderer.render(**render_params) }
          .to raise_error(ReactiveView::RenderError, 'Internal error: Stack trace here')
      end
    end

    context 'when daemon returns 500 with plain text' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_return(status: 500, body: 'Something went wrong')
      end

      it 'raises RenderError with the plain text message' do
        expect { renderer.render(**render_params) }
          .to raise_error(ReactiveView::RenderError, 'Something went wrong')
      end
    end

    context 'when daemon is unavailable' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'raises DaemonUnavailableError' do
        expect { renderer.render(**render_params) }
          .to raise_error(ReactiveView::DaemonUnavailableError, /Connection refused/)
      end
    end

    context 'when daemon times out' do
      before do
        stub_request(:post, 'http://localhost:3001/api/render')
          .to_raise(Faraday::TimeoutError.new('timeout'))
      end

      it 'raises DaemonUnavailableError' do
        expect { renderer.render(**render_params) }
          .to raise_error(ReactiveView::DaemonUnavailableError, /timeout/)
      end
    end
  end

  describe '#healthy?' do
    context 'when daemon responds successfully' do
      before do
        stub_request(:get, 'http://localhost:3001/api/render')
          .to_return(status: 200)
      end

      it 'returns true' do
        expect(renderer.healthy?).to be true
      end
    end

    context 'when daemon is unavailable' do
      before do
        stub_request(:get, 'http://localhost:3001/api/render')
          .to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'returns false' do
        expect(renderer.healthy?).to be false
      end
    end

    context 'when daemon returns an error status' do
      before do
        stub_request(:get, 'http://localhost:3001/api/render')
          .to_return(status: 500)
      end

      it 'returns false' do
        expect(renderer.healthy?).to be false
      end
    end
  end
end
