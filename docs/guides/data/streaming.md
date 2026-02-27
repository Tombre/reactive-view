# Streaming

ReactiveView supports SSE streaming for long-running mutation responses.

## Ruby side

Use `render_stream` in a mutation method:

```ruby
def generate
  render_stream do |out|
    out << "Hello "
    out << "world"
    out.json({ usage: { tokens: 2 } })
  end
end
```

`out` is a `ReactiveView::StreamWriter`:

- `out << "text"` emits text chunks
- `out.json(hash)` emits structured payload
- `out.event("name", data)` emits custom event

## TypeScript side

Use generated `useStream("mutationName")` from `#loaders/*`:

```tsx
const stream = useStream("generate");
const StreamForm = useForm(stream);
```

`stream.start(params)` is strongly typed from the mutation params shape.

`stream` state:

- `stream.data()` accumulated text
- `stream.streaming()` active status
- `stream.error()` current error
- `stream.chunks()` all chunks
- `stream.start(params)` programmatic start
- `stream.abort()` cancel

`useForm` supports both mutation names and stream handles:

- `useForm("update")` -> `[Form, submission]`
- `useForm(stream)` -> `StreamForm`

## Endpoint

Streaming mutations POST to `/_reactive_view/loaders/*path/stream`.

See [Stream API Reference](../../reference/typescript/stream-api.md) and [Internal Endpoints](../../reference/ruby/internal-endpoints.md).
