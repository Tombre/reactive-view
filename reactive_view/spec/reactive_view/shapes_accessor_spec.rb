# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::ShapesAccessor do
  let(:update_shape) do
    Class.new(ReactiveView::Shape) do
      shape do
        param :name
        param :email
      end
    end
  end

  let(:settings_shape) do
    Class.new(ReactiveView::Shape) do
      shape do
        param :count, :integer
        param :price, :float
        param :enabled, :boolean
      end
    end
  end

  let(:shapes) do
    {
      update: update_shape,
      settings: settings_shape
    }
  end

  subject(:accessor) { described_class.new(shapes) }

  describe '#method_missing' do
    context 'with a defined shape' do
      it 'returns the Shape class for a known shape name' do
        expect(accessor.update).to eq(update_shape)
      end

      it 'returns different Shape classes for different names' do
        expect(accessor.update).to eq(update_shape)
        expect(accessor.settings).to eq(settings_shape)
      end

      it 'returns a class that responds to .call' do
        expect(accessor.update).to respond_to(:call)
      end

      it 'returns a class that responds to .call!' do
        expect(accessor.update).to respond_to(:call!)
      end
    end

    context 'using the returned Shape class' do
      it 'validates and coerces params via .call' do
        result = accessor.update.call('name' => 'John', 'email' => 'john@example.com')

        expect(result).to be_a(ReactiveView::Shape)
        expect(result.valid?).to be true
        expect(result.data).to eq({ name: 'John', email: 'john@example.com' })
      end

      it 'filters out params not defined in the shape' do
        result = accessor.update.call(
          'name' => 'John', 'email' => 'john@example.com',
          'password' => 'secret', '_csrf' => 'token'
        )

        expect(result.valid?).to be true
        expect(result.data.keys).to contain_exactly(:name, :email)
        expect(result.data).not_to have_key(:password)
        expect(result.data).not_to have_key(:_csrf)
      end

      it 'symbolizes keys in the result data' do
        result = accessor.update.call('name' => 'John', 'email' => 'john@example.com')
        expect(result.data.keys).to all(be_a(Symbol))
      end
    end

    context 'with type coercion via Shape.call' do
      it 'coerces string to integer' do
        result = accessor.settings.call('count' => '42', 'price' => '3.14', 'enabled' => 'true')

        expect(result.data[:count]).to eq(42)
        expect(result.data[:count]).to be_a(Integer)
      end

      it 'coerces string to float' do
        result = accessor.settings.call('count' => '42', 'price' => '3.14', 'enabled' => 'true')

        expect(result.data[:price]).to eq(3.14)
        expect(result.data[:price]).to be_a(Float)
      end

      it 'coerces string to boolean' do
        result = accessor.settings.call('count' => '1', 'price' => '0', 'enabled' => 'true')
        expect(result.data[:enabled]).to eq(true)
      end

      it 'handles various truthy boolean values' do
        [['true', true], ['1', true], ['yes', true], ['on', true],
         ['false', false], ['0', false], ['no', false], ['off', false]].each do |value, expected|
          result = accessor.settings.call('count' => '1', 'price' => '1.0', 'enabled' => value)

          expect(result.data[:enabled]).to eq(expected), "Expected '#{value}' to coerce to #{expected}"
        end
      end

      it 'preserves already-correct types' do
        result = accessor.settings.call('count' => 42, 'price' => 3.14, 'enabled' => true)

        expect(result.data[:count]).to eq(42)
        expect(result.data[:price]).to eq(3.14)
        expect(result.data[:enabled]).to eq(true)
      end
    end

    context 'raising validation via .call!' do
      it 'returns a valid Shape instance for valid data' do
        result = accessor.update.call!('name' => 'John', 'email' => 'john@example.com')
        expect(result.valid?).to be true
        expect(result.data[:name]).to eq('John')
      end

      it 'raises ValidationError for invalid data' do
        expect {
          accessor.update.call!('name' => 123, 'email' => 456)
        }.to raise_error(ReactiveView::ValidationError)
      end
    end

    context 'with undefined shape' do
      it 'raises NoMethodError' do
        expect { accessor.unknown_method }.to raise_error(NoMethodError)
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

    it 'extracts params using to_unsafe_h via Shape.call' do
      params = params_class.new({ 'name' => 'John', 'email' => 'john@example.com' })
      result = accessor.update.call(params)

      expect(result.valid?).to be true
      expect(result.data).to eq({ name: 'John', email: 'john@example.com' })
    end
  end

  describe 'with nil shapes' do
    subject(:accessor) { described_class.new(nil) }

    it 'handles nil shapes gracefully' do
      expect { accessor.update }.to raise_error(NoMethodError)
    end
  end
end
