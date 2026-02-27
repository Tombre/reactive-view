# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::Loader do
  # Create fresh subclasses for each test to avoid class_attribute leakage
  let(:loader_class) { Class.new(described_class) }

  describe '.shape' do
    it 'registers a shape with a block DSL' do
      loader_class.shape :load do
        param :id, :integer
        param :name
      end

      expect(loader_class._shapes).to have_key(:load)
      expect(loader_class._shapes[:load]).to be < ReactiveView::Shape
    end

    it 'registers multiple named shapes' do
      loader_class.shape :load do
        param :id, :integer
      end

      loader_class.shape :update do
        param :name
        param :email
      end

      expect(loader_class._shapes.keys).to contain_exactly(:load, :update)
    end

    it 'accepts a Shape class directly' do
      shape_class = Class.new(ReactiveView::Shape) do
        shape do
          param :id, :integer
        end
      end

      loader_class.shape :load, shape_class

      expect(loader_class._shapes[:load]).to eq(shape_class)
    end

    it 'raises ArgumentError for non-Shape class' do
      expect do
        loader_class.shape :load, String
      end.to raise_error(ArgumentError, /ReactiveView::Shape subclass/)
    end

    it 'raises ArgumentError when neither class nor block provided' do
      expect do
        loader_class.shape :load
      end.to raise_error(ArgumentError, /requires either a Shape class or a block/)
    end

    it 'creates an anonymous Shape subclass that has a dry_schema' do
      loader_class.shape :load do
        param :id, :integer
        param :name
      end

      shape_class = loader_class._shapes[:load]
      schema = shape_class.dry_schema

      expect(schema).to respond_to(:keys)
      expect(schema.keys.map(&:name)).to contain_exactly(:id, :name)
    end
  end

  describe '.params_shape' do
    it 'assigns a symbol reference for an action' do
      loader_class.shape :update do
        param :name
      end

      loader_class.params_shape :update, :update

      expect(loader_class._params_shapes[:update]).to eq(:update)
    end

    it 'assigns a Shape class directly for an action' do
      shape_class = Class.new(ReactiveView::Shape) do
        shape do
          param :name
        end
      end

      loader_class.params_shape :update, shape_class

      expect(loader_class._params_shapes[:update]).to eq(shape_class)
    end
  end

  describe '.response_shape' do
    it 'assigns a symbol reference for an action' do
      loader_class.shape :load do
        param :id, :integer
      end

      loader_class.response_shape :load, :load

      expect(loader_class._response_shapes[:load]).to eq(:load)
    end

    it 'assigns a Shape class directly for an action' do
      shape_class = Class.new(ReactiveView::Shape) do
        shape do
          param :id, :integer
        end
      end

      loader_class.response_shape :load, shape_class

      expect(loader_class._response_shapes[:load]).to eq(shape_class)
    end

    it 'supports response_shape in shape-first order' do
      loader_class.shape :stream_chunk do
        param :word, :string
      end

      loader_class.response_shape :stream_chunk, :generate, mode: :stream

      expect(loader_class._response_shapes[:generate]).to eq(:stream_chunk)
      expect(loader_class.response_shape_mode(:generate)).to eq(:stream)
    end

    it 'defaults response mode to :single' do
      loader_class.shape :load do
        param :id, :integer
      end

      loader_class.response_shape :load, :load

      expect(loader_class.response_shape_mode(:load)).to eq(:single)
    end

    it 'raises for unsupported response mode' do
      expect do
        loader_class.response_shape :load, :load, mode: :invalid
      end.to raise_error(ArgumentError, /mode must be :single or :stream/)
    end
  end

  describe '.resolve_shape' do
    it 'resolves a symbol key to its Shape class' do
      loader_class.shape :update do
        param :name
      end

      resolved = loader_class.resolve_shape(:update)
      expect(resolved).to eq(loader_class._shapes[:update])
      expect(resolved).to be < ReactiveView::Shape
    end

    it 'passes through a Shape class directly' do
      shape_class = Class.new(ReactiveView::Shape) do
        shape do
          param :id, :integer
        end
      end

      resolved = loader_class.resolve_shape(shape_class)
      expect(resolved).to eq(shape_class)
    end

    it 'returns nil for unknown symbol key' do
      expect(loader_class.resolve_shape(:nonexistent)).to be_nil
    end

    it 'returns nil for non-Shape class' do
      expect(loader_class.resolve_shape(String)).to be_nil
    end

    it 'returns nil for other types' do
      expect(loader_class.resolve_shape(42)).to be_nil
    end
  end

  describe '.resolve_params_shape' do
    it 'resolves params shape for an action via symbol' do
      loader_class.shape :update do
        param :name
      end
      loader_class.params_shape :update, :update

      resolved = loader_class.resolve_params_shape(:update)
      expect(resolved).to eq(loader_class._shapes[:update])
    end

    it 'resolves params shape for an action via class' do
      shape_class = Class.new(ReactiveView::Shape) do
        shape do
          param :name
        end
      end
      loader_class.params_shape :update, shape_class

      resolved = loader_class.resolve_params_shape(:update)
      expect(resolved).to eq(shape_class)
    end

    it 'returns nil for action without params_shape' do
      expect(loader_class.resolve_params_shape(:update)).to be_nil
    end
  end

  describe '.resolve_response_shape' do
    it 'resolves response shape for an action via symbol' do
      loader_class.shape :load do
        param :id, :integer
      end
      loader_class.response_shape :load, :load

      resolved = loader_class.resolve_response_shape(:load)
      expect(resolved).to eq(loader_class._shapes[:load])
    end

    it 'resolves response shape for an action via class' do
      shape_class = Class.new(ReactiveView::Shape) do
        shape do
          param :id, :integer
        end
      end
      loader_class.response_shape :load, shape_class

      resolved = loader_class.resolve_response_shape(:load)
      expect(resolved).to eq(shape_class)
    end

    it 'returns nil for action without response_shape' do
      expect(loader_class.resolve_response_shape(:load)).to be_nil
    end
  end

  describe 'class_attribute isolation' do
    it 'does not leak shapes between different loader subclasses' do
      loader_a = Class.new(described_class)
      loader_b = Class.new(described_class)

      loader_a.shape :load do
        param :id, :integer
      end

      expect(loader_a._shapes).to have_key(:load)
      expect(loader_b._shapes).not_to have_key(:load)
    end

    it 'does not leak params_shapes between subclasses' do
      loader_a = Class.new(described_class)
      loader_b = Class.new(described_class)

      loader_a.shape :update do
        param :name
      end
      loader_a.params_shape :update, :update

      expect(loader_a._params_shapes).to have_key(:update)
      expect(loader_b._params_shapes).not_to have_key(:update)
    end

    it 'does not leak response_shapes between subclasses' do
      loader_a = Class.new(described_class)
      loader_b = Class.new(described_class)

      loader_a.shape :load do
        param :id, :integer
      end
      loader_a.response_shape :load, :load

      expect(loader_a._response_shapes).to have_key(:load)
      expect(loader_b._response_shapes).not_to have_key(:load)
    end

    it 'does not leak response_shape_modes between subclasses' do
      loader_a = Class.new(described_class)
      loader_b = Class.new(described_class)

      loader_a.shape :chunk do
        param :word, :string
      end
      loader_a.response_shape :chunk, :generate, mode: :stream

      expect(loader_a.response_shape_mode(:generate)).to eq(:stream)
      expect(loader_b.response_shape_mode(:generate)).to eq(:single)
    end
  end

  describe 'full integration: shape + params_shape + response_shape' do
    it 'supports a typical loader pattern with load and mutation shapes' do
      loader = Class.new(described_class)

      loader.shape :load do
        param :id, :integer
        param :name
      end

      loader.shape :update do
        param :name
        param :email
      end

      loader.response_shape :load, :load
      loader.params_shape :update, :update

      # Verify the load shape is accessible via response_shape resolution
      load_shape = loader.resolve_response_shape(:load)
      expect(load_shape).not_to be_nil
      expect(load_shape.dry_schema.keys.map(&:name)).to contain_exactly(:id, :name)

      # Verify the update shape is accessible via params_shape resolution
      update_shape = loader.resolve_params_shape(:update)
      expect(update_shape).not_to be_nil
      expect(update_shape.dry_schema.keys.map(&:name)).to contain_exactly(:name, :email)

      # Verify the shapes can actually validate data
      result = update_shape.call(name: 'Alice', email: 'alice@example.com')
      expect(result.valid?).to be true
      expect(result.data).to eq({ name: 'Alice', email: 'alice@example.com' })
    end

    it 'supports using standalone Shape classes' do
      user_response = Class.new(ReactiveView::Shape) do
        shape do
          param :id, :integer
          param :name
        end
      end

      update_params = Class.new(ReactiveView::Shape) do
        shape do
          param :name
          param :email
        end
      end

      loader = Class.new(described_class)
      loader.response_shape :load, user_response
      loader.params_shape :update, update_params

      expect(loader.resolve_response_shape(:load)).to eq(user_response)
      expect(loader.resolve_params_shape(:update)).to eq(update_params)
    end
  end
end
