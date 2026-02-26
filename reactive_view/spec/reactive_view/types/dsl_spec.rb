# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::Types::SignatureBuilder do
  describe '#param' do
    it 'adds a parameter to the schema' do
      builder = described_class.new do
        param :name, ReactiveView::Types::String
      end

      schema = builder.schema
      expect(schema).to have_key(:name)
    end

    it 'supports multiple parameters' do
      builder = described_class.new do
        param :id, ReactiveView::Types::Integer
        param :name, ReactiveView::Types::String
        param :active, ReactiveView::Types::Boolean
      end

      schema = builder.schema
      expect(schema.keys).to contain_exactly(:id, :name, :active)
    end
  end

  describe '#build' do
    it 'returns an empty Hash type when no params defined' do
      builder = described_class.new
      schema = builder.build

      expect(schema).to eq(ReactiveView::Types::Hash)
    end

    it 'returns a Hash schema type with params' do
      builder = described_class.new do
        param :id, ReactiveView::Types::Integer
        param :name, ReactiveView::Types::String
      end

      schema = builder.build

      # Should be able to validate matching data
      result = schema.try({ id: 1, name: 'Test' })
      expect(result.success?).to be true
    end

    it 'validates against mismatched types' do
      builder = described_class.new do
        param :id, ReactiveView::Types::Integer
      end

      schema = builder.build

      # String when Integer expected
      result = schema.try({ id: 'not an integer' })
      expect(result.failure?).to be true
    end
  end

  describe 'symbol type shortcuts' do
    it 'resolves :string to Types::String' do
      builder = described_class.new do
        param :name, :string
      end

      schema = builder.build
      result = schema.try({ name: 'hello' })
      expect(result.success?).to be true
    end

    it 'resolves :integer to Types::Integer' do
      builder = described_class.new do
        param :count, :integer
      end

      schema = builder.build
      result = schema.try({ count: 42 })
      expect(result.success?).to be true

      bad_result = schema.try({ count: 'not_int' })
      expect(bad_result.failure?).to be true
    end

    it 'resolves :float to Types::Float' do
      builder = described_class.new do
        param :price, :float
      end

      schema = builder.build
      result = schema.try({ price: 3.14 })
      expect(result.success?).to be true
    end

    it 'resolves :boolean to Types::Boolean' do
      builder = described_class.new do
        param :active, :boolean
      end

      schema = builder.build
      result = schema.try({ active: true })
      expect(result.success?).to be true
    end

    it 'resolves :bool as alias for :boolean' do
      builder = described_class.new do
        param :active, :bool
      end

      schema = builder.build
      result = schema.try({ active: false })
      expect(result.success?).to be true
    end

    it 'resolves :any to Types::Any' do
      builder = described_class.new do
        param :data, :any
      end

      schema = builder.build
      result = schema.try({ data: 'anything' })
      expect(result.success?).to be true

      result2 = schema.try({ data: 42 })
      expect(result2.success?).to be true
    end

    it 'raises ArgumentError for unknown symbol shortcuts' do
      expect {
        described_class.new do
          param :x, :unknown_type
        end
      }.to raise_error(ArgumentError, /Unknown type shortcut :unknown_type/)
    end
  end

  describe 'default type (nil)' do
    it 'defaults to Types::String when no type is given' do
      builder = described_class.new do
        param :name
      end

      schema = builder.build
      result = schema.try({ name: 'hello' })
      expect(result.success?).to be true

      bad_result = schema.try({ name: 123 })
      expect(bad_result.failure?).to be true
    end
  end

  describe '#collection' do
    it 'defines an array of hashes from a block' do
      builder = described_class.new do
        collection :pets do
          param :name
          param :species
        end
      end

      schema = builder.build
      result = schema.try({ pets: [{ name: 'Fido', species: 'dog' }] })
      expect(result.success?).to be true
    end

    it 'validates elements against the nested schema' do
      builder = described_class.new do
        collection :items do
          param :count, :integer
        end
      end

      schema = builder.build
      result = schema.try({ items: [{ count: 1 }, { count: 2 }] })
      expect(result.success?).to be true

      bad_result = schema.try({ items: [{ count: 'not_int' }] })
      expect(bad_result.failure?).to be true
    end

    it 'rejects non-array values' do
      builder = described_class.new do
        collection :pets do
          param :name
        end
      end

      schema = builder.build
      result = schema.try({ pets: 'not an array' })
      expect(result.failure?).to be true
    end
  end

  describe '#hash' do
    it 'defines a nested hash from a block' do
      builder = described_class.new do
        hash :contact do
          param :email
          param :phone
        end
      end

      schema = builder.build
      result = schema.try({ contact: { email: 'a@b.com', phone: '555-1234' } })
      expect(result.success?).to be true
    end

    it 'validates nested hash fields' do
      builder = described_class.new do
        hash :address do
          param :zip, :integer
        end
      end

      schema = builder.build
      result = schema.try({ address: { zip: 12345 } })
      expect(result.success?).to be true

      bad_result = schema.try({ address: { zip: 'not_int' } })
      expect(bad_result.failure?).to be true
    end

    it 'rejects non-hash values' do
      builder = described_class.new do
        hash :meta do
          param :key
        end
      end

      schema = builder.build
      result = schema.try({ meta: 'not a hash' })
      expect(result.failure?).to be true
    end
  end
end

RSpec.describe ReactiveView::Types::Signature do
  let(:schema) do
    ReactiveView::Types::Hash.schema(
      id: ReactiveView::Types::Integer,
      name: ReactiveView::Types::String,
      active: ReactiveView::Types::Optional[ReactiveView::Types::Boolean]
    )
  end

  let(:signature) { described_class.new(schema) }

  describe '#param_names' do
    it 'returns the list of parameter names' do
      expect(signature.param_names).to contain_exactly(:id, :name, :active)
    end

    it 'returns empty array for empty schema' do
      empty_sig = described_class.new(ReactiveView::Types::Hash)
      expect(empty_sig.param_names).to eq([])
    end
  end

  describe '#type_for' do
    it 'returns the type for a given parameter' do
      expect(signature.type_for(:id)).to eq(ReactiveView::Types::Integer)
    end

    it 'returns nil for unknown parameter' do
      expect(signature.type_for(:unknown)).to be_nil
    end
  end

  describe '#empty?' do
    it 'returns false when schema has keys' do
      expect(signature.empty?).to be false
    end

    it 'returns true when schema has no keys' do
      empty_sig = described_class.new(ReactiveView::Types::Hash)
      expect(empty_sig.empty?).to be true
    end
  end
end

RSpec.describe ReactiveView::Types do
  describe 'primitive types' do
    it 'provides String type' do
      expect(ReactiveView::Types::String['hello']).to eq('hello')
      expect { ReactiveView::Types::String[123] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'provides Integer type' do
      expect(ReactiveView::Types::Integer[42]).to eq(42)
      expect { ReactiveView::Types::Integer['not int'] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'provides Boolean type' do
      expect(ReactiveView::Types::Boolean[true]).to eq(true)
      expect(ReactiveView::Types::Boolean[false]).to eq(false)
      expect { ReactiveView::Types::Boolean['yes'] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'provides Float type' do
      expect(ReactiveView::Types::Float[3.14]).to eq(3.14)
      expect { ReactiveView::Types::Float['pi'] }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'compound types' do
    it 'supports Optional types' do
      optional_string = ReactiveView::Types::Optional[ReactiveView::Types::String]

      expect(optional_string['hello']).to eq('hello')
      expect(optional_string[nil]).to be_nil
    end

    it 'supports Array types' do
      string_array = ReactiveView::Types::Array[ReactiveView::Types::String]

      expect(string_array[%w[a b c]]).to eq(%w[a b c])
      expect { string_array[[1, 2, 3]] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'supports Hash schema types' do
      user_type = ReactiveView::Types::Hash.schema(
        id: ReactiveView::Types::Integer,
        name: ReactiveView::Types::String
      )

      valid_data = { id: 1, name: 'Alice' }
      expect(user_type[valid_data]).to eq(valid_data)
    end
  end
end
