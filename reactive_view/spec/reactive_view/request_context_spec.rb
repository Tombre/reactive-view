# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe ReactiveView::RequestContext do
  let(:mock_request) do
    OpenStruct.new(
      params: { 'id' => '123', 'controller' => 'pages', 'action' => 'show' }
    )
  end

  describe '.store' do
    it 'returns a token string' do
      token = described_class.store(mock_request, 'users/[id]')

      expect(token).to be_a(String)
      expect(token).to include('.')
    end

    it 'generates unique tokens for each call' do
      token1 = described_class.store(mock_request, 'users/[id]')
      token2 = described_class.store(mock_request, 'users/[id]')

      expect(token1).not_to eq(token2)
    end

    it 'stores the loader path in context' do
      token = described_class.store(mock_request, 'users/[id]')
      context = described_class.retrieve(token)

      expect(context[:loader_path]).to eq('users/[id]')
    end

    it 'stores sanitized params (without controller/action)' do
      token = described_class.store(mock_request, 'users/[id]')
      context = described_class.retrieve(token)

      expect(context[:params]).to eq({ 'id' => '123' })
      expect(context[:params]).not_to include('controller', 'action')
    end

    it 'stores the loader class name when provided' do
      loader_class = Class.new
      stub_const('TestLoader', loader_class)

      token = described_class.store(mock_request, 'test', TestLoader)
      context = described_class.retrieve(token)

      expect(context[:loader_class]).to eq('TestLoader')
    end
  end

  describe '.retrieve' do
    it 'returns the stored context' do
      token = described_class.store(mock_request, 'users/[id]')
      context = described_class.retrieve(token)

      expect(context).to be_a(Hash)
      expect(context[:loader_path]).to eq('users/[id]')
    end

    it 'deletes the context after retrieval (single use)' do
      token = described_class.store(mock_request, 'users/[id]')

      described_class.retrieve(token)

      expect { described_class.retrieve(token) }.to raise_error(ReactiveView::InvalidTokenError)
    end

    it 'raises InvalidTokenError for invalid tokens' do
      expect { described_class.retrieve('invalid.token') }.to raise_error(ReactiveView::InvalidTokenError)
    end

    it 'raises InvalidTokenError for malformed tokens' do
      expect { described_class.retrieve('malformed') }.to raise_error(ReactiveView::InvalidTokenError)
    end

    it 'raises InvalidTokenError for tokens with invalid signatures' do
      valid_token = described_class.store(mock_request, 'test')
      parts = valid_token.split('.')
      tampered_token = "#{parts[0]}.invalidsignature"

      expect { described_class.retrieve(tampered_token) }.to raise_error(ReactiveView::InvalidTokenError)
    end
  end

  describe '.exists?' do
    it 'returns true for stored tokens' do
      token = described_class.store(mock_request, 'test')

      expect(described_class.exists?(token)).to be true
    end

    it 'returns false for unknown tokens' do
      # Generate a properly formatted but non-existent token
      token = described_class.store(mock_request, 'test')
      described_class.retrieve(token) # consume it

      expect(described_class.exists?(token)).to be false
    end
  end
end
