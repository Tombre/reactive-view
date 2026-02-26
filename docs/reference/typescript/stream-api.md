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
- `start(params: Record<string, unknown>): void`
- `abort(): void`

## `StreamChunk`

Fields include:

- `type` (`"text"`, `"json"`, `"error"`, `"done"`, or custom)
- `chunk?`, `data?`, `message?`

## Endpoint

- `POST /_reactive_view/loaders/${loaderPath}/stream?_mutation=${mutationName}`
- uses `text/event-stream`
