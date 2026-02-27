# Streaming

ReactiveView supports SSE streaming for long-running mutation responses.

## Ruby side

Declare a streamed response shape and stream objects that match it:

```ruby
shape :generate do
  param :prompt, ReactiveView::Types::String
end

shape :generate_response do
  param :word, ReactiveView::Types::String
end

params_shape :generate, :generate
response_shape :generate_response, :generate, mode: :stream

def generate
  render_stream do |out|
    "Hello world".split(" ").each_with_index do |word, i|
      separator = i < 1 ? " " : ""
      out << { word: "#{word}#{separator}" }
    end
  end
end
```

`out` is a `ReactiveView::StreamWriter`:

- `out << "text"` emits text chunks
- `out << { ... }` emits JSON chunks
- a single stream cannot mix text and JSON chunk types

## TypeScript side

Use generated `useStream("mutationName")` from `#loaders/*`:

```tsx
const stream = useStream("generate");
const StreamForm = useForm(stream);

// Fully typed from response_shape(..., mode: :stream)
const words = stream.messages();
```

`stream.start(params)` is strongly typed from the mutation params shape.
`stream.messages()` is strongly typed from the stream response shape.

`stream` state:

- `stream.streaming()` active status
- `stream.error()` current error
- `stream.chunks()` all chunks
- `stream.messages()` typed streamed objects for this request
- `stream.start(params)` programmatic start
- `stream.retry(params?)` retry (uses last params by default)
- `stream.end()` await completion
- `stream.abort()` cancel

Streams are strict about completion: if the connection closes before a `done` chunk, the stream fails.

`useForm` supports both mutation names and stream handles:

- `useForm("update")` -> `[Form, submission]`
- `useForm(stream)` -> `StreamForm`

## Endpoint

Streaming mutations POST to `/_reactive_view/loaders/*path/stream`.

See [Stream API Reference](../../reference/typescript/stream-api.md) and [Internal Endpoints](../../reference/ruby/internal-endpoints.md).
