# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::StreamWriter do
  let(:mock_stream) { StringIO.new }
  let(:writer) { described_class.new(mock_stream) }

  describe '#<<' do
    it 'writes a text event in SSE format' do
      writer << 'hello'
      expect(mock_stream.string).to include('data: {"type":"text","chunk":"hello"}')
    end

    it 'appends double newline after each event' do
      writer << 'hello'
      expect(mock_stream.string).to end_with("\n\n")
    end

    it 'returns self for chaining' do
      result = writer << 'hello'
      expect(result).to eq(writer)
    end

    it 'supports chained calls' do
      writer << 'hello ' << 'world'
      expect(mock_stream.string).to include('"chunk":"hello "')
      expect(mock_stream.string).to include('"chunk":"world"')
    end

    it 'writes hash payloads as json chunks' do
      writer << { word: 'hello' }
      expect(mock_stream.string).to include('"type":"json"')
      expect(mock_stream.string).to include('"data":{"word":"hello"}')
    end

    it 'raises for unsupported chunk types' do
      expect { writer << 42 }.to raise_error(ArgumentError, /String or Hash/)
    end
  end

  describe '#json' do
    it 'writes a json event in SSE format' do
      writer.json({ count: 42 })
      expect(mock_stream.string).to include('"type":"json"')
      expect(mock_stream.string).to include('"data":{"count":42}')
    end

    it 'handles nested data structures' do
      writer.json({ usage: { tokens: 10, model: 'test' } })
      expect(mock_stream.string).to include('"usage":{"tokens":10,"model":"test"}')
    end

    it 'handles array data' do
      writer.json([1, 2, 3])
      expect(mock_stream.string).to include('"data":[1,2,3]')
    end
  end

  describe '#event' do
    it 'writes a custom event' do
      writer.event('progress', percent: 50)
      expect(mock_stream.string).to include('"type":"progress"')
      expect(mock_stream.string).to include('"percent":50')
    end

    it 'converts event name to string' do
      writer.event(:status, active: true)
      expect(mock_stream.string).to include('"type":"status"')
    end

    it 'works without additional data' do
      writer.event('ping')
      expect(mock_stream.string).to include('"type":"ping"')
    end
  end

  describe '#close' do
    it 'writes a done event and closes the stream' do
      allow(mock_stream).to receive(:close)
      writer.close
      expect(mock_stream.string).to include('"type":"done"')
      expect(mock_stream).to have_received(:close)
    end

    it 'is idempotent' do
      allow(mock_stream).to receive(:close)
      writer.close
      writer.close
      expect(mock_stream).to have_received(:close).once
    end

    it 'marks the writer as closed' do
      allow(mock_stream).to receive(:close)
      expect(writer.closed?).to be false
      writer.close
      expect(writer.closed?).to be true
    end
  end

  describe '#closed?' do
    it 'returns false for new writer' do
      expect(writer.closed?).to be false
    end

    it 'returns true after close' do
      allow(mock_stream).to receive(:close)
      writer.close
      expect(writer.closed?).to be true
    end
  end

  describe 'writing after close' do
    before do
      allow(mock_stream).to receive(:close)
      writer.close
    end

    it 'raises an error for << after close' do
      expect { writer << 'hello' }.to raise_error(RuntimeError, /closed/)
    end

    it 'raises an error for json after close' do
      expect { writer.json({}) }.to raise_error(RuntimeError, /closed/)
    end

    it 'raises an error for event after close' do
      expect { writer.event('test') }.to raise_error(RuntimeError, /closed/)
    end
  end

  describe 'SSE format compliance' do
    it "formats events as 'data: JSON\\n\\n'" do
      writer << 'test'
      lines = mock_stream.string.split("\n\n")
      expect(lines.first).to start_with('data: ')
      json = JSON.parse(lines.first.sub('data: ', ''))
      expect(json['type']).to eq('text')
      expect(json['chunk']).to eq('test')
    end

    it 'produces valid JSON in each event' do
      writer << { key: 'hello' }
      writer.json({ key: 'value' })
      writer.event('custom', data: 123)

      mock_stream.string.scan(/data: (.+)/).each do |match|
        expect { JSON.parse(match.first) }.not_to raise_error
      end
    end
  end

  describe 'chunk mode enforcement' do
    it 'does not allow mixing text and json chunk types' do
      writer << 'hello'
      expect { writer << { word: 'world' } }.to raise_error(ArgumentError, /Cannot mix/)
    end

    it 'can enforce json-only streams' do
      writer = described_class.new(mock_stream, enforced_chunk_type: :json)
      expect { writer << 'hello' }.to raise_error(ArgumentError, /only accepts json chunks/)
    end
  end
end
