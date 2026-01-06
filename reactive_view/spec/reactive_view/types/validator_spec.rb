# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::Types::Validator do
  let(:schema) do
    ReactiveView::Types::Hash.schema(
      id: ReactiveView::Types::Integer,
      name: ReactiveView::Types::String
    )
  end

  describe '#validate!' do
    context 'with valid data' do
      it 'returns the data unchanged' do
        validator = described_class.new(schema)
        data = { id: 1, name: 'Alice' }

        result = validator.validate!(data)

        expect(result).to eq(data)
      end
    end

    context 'with invalid data' do
      it 'raises ValidationError for type mismatch' do
        validator = described_class.new(schema)
        invalid_data = { id: 'not an integer', name: 'Alice' }

        expect { validator.validate!(invalid_data) }.to raise_error(ReactiveView::ValidationError)
      end

      it 'raises ValidationError for missing required fields' do
        validator = described_class.new(schema)
        incomplete_data = { id: 1 }

        expect { validator.validate!(incomplete_data) }.to raise_error(ReactiveView::ValidationError)
      end
    end

    context 'with nil schema' do
      it 'returns data without validation' do
        validator = described_class.new(nil)
        data = { anything: 'goes' }

        result = validator.validate!(data)

        expect(result).to eq(data)
      end
    end
  end

  describe '#validate' do
    it 'returns success result for valid data' do
      validator = described_class.new(schema)
      data = { id: 1, name: 'Bob' }

      result = validator.validate(data)

      expect(result.success?).to be true
      expect(result.data).to eq(data)
      expect(result.error).to be_nil
    end

    it 'returns failure result for invalid data' do
      validator = described_class.new(schema)
      invalid_data = { id: 'wrong', name: 123 }

      result = validator.validate(invalid_data)

      expect(result.failure?).to be true
      expect(result.error).to be_a(String)
    end
  end
end

RSpec.describe ReactiveView::Types::ValidationResult do
  describe '#success?' do
    it 'returns true for successful validation' do
      result = described_class.new(true, {}, nil)
      expect(result.success?).to be true
    end

    it 'returns false for failed validation' do
      result = described_class.new(false, {}, 'error')
      expect(result.success?).to be false
    end
  end

  describe '#failure?' do
    it 'returns false for successful validation' do
      result = described_class.new(true, {}, nil)
      expect(result.failure?).to be false
    end

    it 'returns true for failed validation' do
      result = described_class.new(false, {}, 'error')
      expect(result.failure?).to be true
    end
  end
end
