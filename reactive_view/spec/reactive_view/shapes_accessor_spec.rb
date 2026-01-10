# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::ShapesAccessor do
  let(:update_shape) do
    ReactiveView::Types::Hash.schema(
      name: ReactiveView::Types::String,
      email: ReactiveView::Types::String
    )
  end

  let(:settings_shape) do
    ReactiveView::Types::Hash.schema(
      count: ReactiveView::Types::Integer,
      price: ReactiveView::Types::Float,
      enabled: ReactiveView::Types::Boolean
    )
  end

  let(:method_shapes) do
    {
      update: update_shape,
      settings: settings_shape
    }
  end

  subject(:accessor) { described_class.new(method_shapes) }

  describe '#method_missing' do
    context 'with a defined shape' do
      it 'extracts params for the update shape' do
        params = { 'name' => 'John', 'email' => 'john@example.com' }
        result = accessor.update(params)

        expect(result).to eq({ name: 'John', email: 'john@example.com' })
      end

      it 'filters out params not defined in the shape' do
        params = { 'name' => 'John', 'email' => 'john@example.com', 'password' => 'secret', '_csrf' => 'token' }
        result = accessor.update(params)

        expect(result).to eq({ name: 'John', email: 'john@example.com' })
        expect(result).not_to have_key(:password)
        expect(result).not_to have_key(:_csrf)
      end

      it 'symbolizes keys in the result' do
        params = { 'name' => 'John', 'email' => 'john@example.com' }
        result = accessor.update(params)

        expect(result.keys).to all(be_a(Symbol))
      end
    end

    context 'with type coercion' do
      it 'coerces string to integer' do
        params = { 'count' => '42', 'price' => '3.14', 'enabled' => 'true' }
        result = accessor.settings(params)

        expect(result[:count]).to eq(42)
        expect(result[:count]).to be_a(Integer)
      end

      it 'coerces string to float' do
        params = { 'count' => '42', 'price' => '3.14', 'enabled' => 'true' }
        result = accessor.settings(params)

        expect(result[:price]).to eq(3.14)
        expect(result[:price]).to be_a(Float)
      end

      it 'coerces string to boolean' do
        params = { 'count' => '1', 'price' => '0', 'enabled' => 'true' }
        result = accessor.settings(params)

        expect(result[:enabled]).to eq(true)
      end

      it 'handles various truthy boolean values' do
        [['true', true], ['1', true], ['yes', true], ['on', true],
         ['false', false], ['0', false], ['no', false], ['off', false]].each do |value, expected|
          params = { 'count' => '1', 'price' => '1.0', 'enabled' => value }
          result = accessor.settings(params)

          expect(result[:enabled]).to eq(expected), "Expected '#{value}' to coerce to #{expected}"
        end
      end

      it 'preserves already-correct types' do
        params = { 'count' => 42, 'price' => 3.14, 'enabled' => true }
        result = accessor.settings(params)

        expect(result[:count]).to eq(42)
        expect(result[:price]).to eq(3.14)
        expect(result[:enabled]).to eq(true)
      end
    end

    context 'with undefined shape' do
      it 'raises NoMethodError' do
        expect { accessor.unknown_method({}) }.to raise_error(NoMethodError)
      end
    end

    context 'with nil params' do
      before do
        # Disable validation for this test - validation would fail on missing required params
        allow(ReactiveView.configuration).to receive(:should_validate_responses?).and_return(false)
      end

      it 'returns empty hash' do
        result = accessor.update(nil)
        expect(result).to eq({})
      end
    end

    context 'with empty params' do
      before do
        # Disable validation for this test - validation would fail on missing required params
        allow(ReactiveView.configuration).to receive(:should_validate_responses?).and_return(false)
      end

      it 'returns empty hash' do
        result = accessor.update({})
        expect(result).to eq({})
      end
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for defined shapes' do
      expect(accessor.respond_to?(:update)).to be true
      expect(accessor.respond_to?(:settings)).to be true
    end

    it 'returns false for undefined shapes' do
      expect(accessor.respond_to?(:unknown)).to be false
    end
  end

  describe 'with ActionController::Parameters-like object' do
    let(:params_class) do
      Class.new do
        def initialize(hash)
          @hash = hash
        end

        def to_unsafe_h
          @hash
        end
      end
    end

    it 'extracts params using to_unsafe_h' do
      params = params_class.new({ 'name' => 'John', 'email' => 'john@example.com' })
      result = accessor.update(params)

      expect(result).to eq({ name: 'John', email: 'john@example.com' })
    end
  end

  describe 'with empty method_shapes' do
    subject(:accessor) { described_class.new(nil) }

    it 'handles nil method_shapes gracefully' do
      expect { accessor.update({}) }.to raise_error(NoMethodError)
    end
  end

  describe 'with empty shape' do
    let(:empty_shape) do
      ReactiveView::Types::Hash
    end

    let(:method_shapes) { { delete: empty_shape } }

    it 'returns empty hash for shapes with no defined keys' do
      params = { 'id' => '123', '_csrf' => 'token' }
      result = accessor.delete(params)

      expect(result).to eq({})
    end
  end
end
