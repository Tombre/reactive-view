# frozen_string_literal: true

module ReactiveView
  # Writer for SSE (Server-Sent Events) streaming responses.
  # Yielded to the block passed to Loader#render_stream.
  #
  # Wraps an ActionController::Live response stream and formats
  # data as SSE events (data: JSON\n\n).
  #
  # @example Sending text chunks (AI tokens)
  #   render_stream do |out|
  #     out << "Hello "
  #     out << "world!"
  #   end
  #
  # @example Sending structured JSON
  #   render_stream do |out|
  #     out << "Response text"
  #     out.json({ usage: { tokens: 42 } })
  #   end
  #
  # @example Sending custom named events
  #   render_stream do |out|
  #     out.event("progress", { percent: 50 })
  #     out.event("progress", { percent: 100 })
  #   end
  class StreamWriter
    # @param stream [ActionController::Live::Buffer] The response stream
    # @param validator [ReactiveView::Types::Validator, nil] Optional validator for streamed JSON payloads
    # @param enforced_chunk_type [Symbol, nil] Optional enforced chunk type (:json or :text)
    def initialize(stream, validator: nil, enforced_chunk_type: nil)
      @stream = stream
      @closed = false
      @validator = validator
      @enforced_chunk_type = enforced_chunk_type
      @chunk_type = nil
    end

    # Send a plain text chunk. This is the primary method for AI token streaming.
    # Each call emits one SSE event with type "text".
    #
    # @param text [String] The text chunk to send
    # @return [self] For chaining: out << "hello " << "world"
    def <<(value)
      if value.is_a?(String)
        write_stream_chunk(:text)
        write_event(type: 'text', chunk: value)
      elsif value.is_a?(Hash)
        write_stream_chunk(:json)
        @validator&.validate!(value)
        write_event(type: 'json', data: value)
      else
        raise ArgumentError, "Stream chunks must be String or Hash, got #{value.class}"
      end

      self
    end

    # Send a structured JSON data event.
    # Use this for metadata, progress info, or any structured payload.
    #
    # @param data [Hash, Array] The data to send
    # @return [void]
    def json(data)
      write_stream_chunk(:json)
      @validator&.validate!(data)
      write_event(type: 'json', data: data)
    end

    # Send a custom named event.
    # Use this for application-specific event types.
    #
    # @param name [String] The event type name
    # @param data [Hash] Additional event data (merged into the payload)
    # @return [void]
    def event(name, data = {})
      write_event(**{ type: name.to_s }.merge(data))
    end

    # Close the stream. Sends a "done" event first if not already closed.
    # This is called automatically by the controller's ensure block,
    # but can be called explicitly for early termination.
    #
    # @return [void]
    def close
      return if @closed

      write_event(type: 'done')
      @stream.close
      @closed = true
    end

    # @return [Boolean] Whether the stream has been closed
    def closed?
      @closed
    end

    private

    # Write a single SSE event line.
    #
    # @param payload [Hash] The event payload, serialized as JSON
    # @raise [RuntimeError] If the stream is already closed
    def write_event(**payload)
      raise 'Stream already closed' if @closed

      @stream.write("data: #{payload.to_json}\n\n")
    end

    def write_stream_chunk(chunk_type)
      if @enforced_chunk_type && @enforced_chunk_type != chunk_type
        raise ArgumentError,
              "This stream only accepts #{@enforced_chunk_type} chunks, got #{chunk_type}"
      end

      if @chunk_type && @chunk_type != chunk_type
        raise ArgumentError,
              "Cannot mix #{chunk_type} chunks into a #{@chunk_type} stream"
      end

      @chunk_type ||= chunk_type
    end
  end
end
