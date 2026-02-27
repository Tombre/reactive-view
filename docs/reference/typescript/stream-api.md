# TypeScript: Stream API

## `createStream`

```ts
createStream(loaderPath: string, mutationName: string, options?: StreamOptions): StreamState
```

Creates SSE mutation stream state.

## `StreamState`

- `data(): string`
- `streaming(): boolean`
- `error(): Error | null`
- `chunks(): StreamChunk[]`
- `start(params: TParams): void`
- `abort(): void`

`StreamState` is generic in generated loader files, so `start(params)` is typed per mutation.

## Generated hooks

- `useStream("mutation")` returns a stream handle (`StreamState<TParams>`) with:
  - `name`
  - `Form` (stream-bound form component)
- `useForm(stream)` returns the same stream-bound `Form` component

## `StreamChunk`

Fields include:

- `type` (`"text"`, `"json"`, `"error"`, `"done"`, or custom)
- `chunk?`, `data?`, `message?`

## Endpoint

- `POST /_reactive_view/loaders/${loaderPath}/stream?_mutation=${mutationName}`
- uses `text/event-stream`
