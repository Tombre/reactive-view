# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Loader streaming' do
  describe '#render_stream' do
    it 'returns a StreamResponse' do
      loader_class = Class.new(ReactiveView::Loader) do
        def generate
          render_stream do |out|
            out << 'hello'
          end
        end
      end

      loader = loader_class.new
      result = loader.generate
      expect(result).to be_a(ReactiveView::StreamResponse)
      expect(result.block).to be_a(Proc)
    end

    it 'raises ArgumentError without a block' do
      loader = ReactiveView::Loader.new
      expect { loader.send(:render_stream) }.to raise_error(ArgumentError, /requires a block/)
    end

    it 'stores a block that can send text via StreamWriter' do
      loader_class = Class.new(ReactiveView::Loader) do
        def generate
          render_stream do |out|
            out << 'hello '
            out << 'world'
          end
        end
      end

      loader = loader_class.new
      result = loader.generate

      # Simulate what the controller does
      mock_stream = StringIO.new
      writer = ReactiveView::StreamWriter.new(mock_stream)
      result.block.call(writer)

      expect(mock_stream.string).to include('"chunk":"hello "')
      expect(mock_stream.string).to include('"chunk":"world"')
    end

    it 'stores a block that can send JSON object chunks via StreamWriter' do
      loader_class = Class.new(ReactiveView::Loader) do
        def generate
          render_stream do |out|
            out << { word: 'hello' }
            out << { word: 'world' }
          end
        end
      end

      loader = loader_class.new
      result = loader.generate

      mock_stream = StringIO.new
      writer = ReactiveView::StreamWriter.new(mock_stream)
      result.block.call(writer)

      expect(mock_stream.string).to include('"type":"json"')
      expect(mock_stream.string).to include('"word":"hello"')
      expect(mock_stream.string).to include('"word":"world"')
    end

    it 'stores a block that can send custom events via StreamWriter' do
      loader_class = Class.new(ReactiveView::Loader) do
        def generate
          render_stream do |out|
            out.event('progress', percent: 50)
            out.event('progress', percent: 100)
          end
        end
      end

      loader = loader_class.new
      result = loader.generate

      mock_stream = StringIO.new
      writer = ReactiveView::StreamWriter.new(mock_stream)
      result.block.call(writer)

      expect(mock_stream.string).to include('"type":"progress"')
      expect(mock_stream.string).to include('"percent":50')
      expect(mock_stream.string).to include('"percent":100')
    end
  end
end
