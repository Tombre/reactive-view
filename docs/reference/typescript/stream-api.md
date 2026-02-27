# TypeScript: Stream API

## `createStream`

```ts
createStream(loaderPath: string, mutationName: string, options?: StreamOptions): StreamState
```

Creates SSE mutation stream state.

## `StreamState`

- `data(): string`
- `streaming(): boolean`
- `status(): "idle" | "streaming" | "done" | "error" | "aborted"`
- `error(): Error | null`
- `chunks(): StreamChunk[]`
- `lastParams(): TParams | null`
- `start(params: TParams): void`
- `retry(params?: TParams): void`
- `end(): Promise<void>`
- `abort(): void`

`StreamState` is generic in generated loader files, so `start(params)` is typed per mutation.
Streams complete successfully only after a `done` chunk. If the connection closes early, the stream fails with `StreamIncompleteError`.

## Generated hooks

- `useStream("mutation")` returns a stream handle (`StreamState<TParams>`) with:
  - `name`
  - `Form` (stream-bound form component)
- `useForm(stream)` returns the same stream-bound `Form` component

## `useStreamData(stream, options?)`

Higher-level helper for chat-style streaming UIs.

- `messages()` returns typed stream messages
- `state()` and `error()` expose stream lifecycle status
- `send(params)` starts a stream and appends a user + assistant message
- `retry(params?)` retries with last params by default
- `reset()` clears helper-managed messages

Optional `options`:

- `getUserContent(params)`
- `parseJsonChunk(chunk)`
- `extractMeta(events)`

## `StreamChunk`

Fields include:

- `type` (`"text"`, `"json"`, `"error"`, `"done"`, or custom)
- `chunk?`, `data?`, `message?`

## Endpoint

- `POST /_reactive_view/loaders/${loaderPath}/stream?_mutation=${mutationName}`
- uses `text/event-stream`
