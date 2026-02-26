# frozen_string_literal: true

module ReactiveView
  # Value object returned by Loader#render_stream.
  # Wraps a block that will be executed with a StreamWriter
  # when the controller is ready to stream the SSE response.
  #
  # @example
  #   result = render_stream { |out| out << "hello" }
  #   result.is_a?(StreamResponse) # => true
  #   result.block.call(writer)
  class StreamResponse
    attr_reader :block

    # @param block [Proc] Block that receives a StreamWriter
    def initialize(block)
      @block = block
    end
  end
end
