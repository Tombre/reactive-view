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
      expect(result.errors).to eq({})
    end

    it 'returns failure result with structured errors for invalid data' do
      validator = described_class.new(schema)
      invalid_data = { id: 'wrong', name: 123 }

      result = validator.validate(invalid_data)

      expect(result.failure?).to be true
      expect(result.errors).to be_a(Hash)
      expect(result.errors).not_to be_empty
    end

    it 'returns field-level errors keyed by field name' do
      validator = described_class.new(schema)
      invalid_data = { id: 'wrong', name: 123 }

      result = validator.validate(invalid_data)

      # Errors should be keyed by field paths (strings)
      expect(result.errors.keys).to all(be_a(String))
      # Each value should be an array of error messages
      expect(result.errors.values).to all(be_an(Array))
    end

    it 'provides backward-compatible .error method returning first message' do
      validator = described_class.new(schema)
      invalid_data = { id: 'wrong', name: 123 }

      result = validator.validate(invalid_data)

      expect(result.error).to be_a(String)
    end

    it 'returns nil .error for valid data' do
      validator = described_class.new(schema)
      data = { id: 1, name: 'Bob' }

      result = validator.validate(data)

      expect(result.error).to be_nil
    end

    context 'with nil schema' do
      it 'returns success result' do
        validator = described_class.new(nil)
        result = validator.validate({ anything: 'goes' })

        expect(result.success?).to be true
        expect(result.errors).to eq({})
      end
    end

    context 'with nested schema' do
      let(:nested_schema) do
        ReactiveView::Types::Hash.schema(
          user: ReactiveView::Types::Hash.schema(
            id: ReactiveView::Types::Integer,
            name: ReactiveView::Types::String
          )
        )
      end

      it 'returns failure for invalid nested data' do
        validator = described_class.new(nested_schema)
        invalid_data = { user: { id: 'bad', name: 123 } }

        result = validator.validate(invalid_data)

        expect(result.failure?).to be true
        expect(result.errors).not_to be_empty
      end

      it 'returns success for valid nested data' do
        validator = described_class.new(nested_schema)
        valid_data = { user: { id: 1, name: 'Alice' } }

        result = validator.validate(valid_data)

        expect(result.success?).to be true
        expect(result.errors).to eq({})
      end
    end
  end
end

RSpec.describe ReactiveView::Types::ValidationResult do
  describe '#success?' do
    it 'returns true for successful validation' do
      result = described_class.new(true, { id: 1 }, {})
      expect(result.success?).to be true
    end

    it 'returns false for failed validation' do
      result = described_class.new(false, {}, { 'name' => ['is missing'] })
      expect(result.success?).to be false
    end
  end

  describe '#failure?' do
    it 'returns false for successful validation' do
      result = described_class.new(true, {}, {})
      expect(result.failure?).to be false
    end

    it 'returns true for failed validation' do
      result = described_class.new(false, {}, { 'name' => ['is missing'] })
      expect(result.failure?).to be true
    end
  end

  describe '#data' do
    it 'returns the validated data' do
      result = described_class.new(true, { id: 1, name: 'Alice' }, {})
      expect(result.data).to eq({ id: 1, name: 'Alice' })
    end
  end

  describe '#errors' do
    it 'returns structured errors hash' do
      errors = { 'name' => ['is missing'], 'email' => ['is invalid'] }
      result = described_class.new(false, {}, errors)

      expect(result.errors).to eq(errors)
    end

    it 'returns empty hash for successful validation' do
      result = described_class.new(true, {}, {})
      expect(result.errors).to eq({})
    end
  end

  describe '#error (backward compat)' do
    it 'returns nil when no errors' do
      result = described_class.new(true, {}, {})
      expect(result.error).to be_nil
    end

    it 'returns first error message from structured errors' do
      errors = { 'name' => ['is missing', 'is too short'], 'email' => ['is invalid'] }
      result = described_class.new(false, {}, errors)

      expect(result.error).to eq('is missing')
    end

    it 'handles empty errors hash' do
      result = described_class.new(false, {}, {})
      expect(result.error).to be_nil
    end
  end
end
