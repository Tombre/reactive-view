# Ruby: Internal Endpoints

These endpoints are mounted by the ReactiveView engine at `/_reactive_view`.

## Loader data

- `GET /_reactive_view/loaders/*path/load`
- controller action: `ReactiveView::LoaderDataController#show`
- calls loader `#load`

## Mutations

- `POST|PUT|PATCH|DELETE /_reactive_view/loaders/*path/mutate`
- controller action: `#mutate`
- mutation name from query param `_mutation` (default `mutate`)

## Streaming

- `POST /_reactive_view/loaders/*path/stream`
- controller action: `#stream`
- returns SSE when loader returns `StreamResponse`

## CSRF behavior

- `show` skips forgery protection (read only)
- `mutate` and `stream` verify CSRF token

## Public/Private guidance

Treat these as internal transport APIs. They are safe to inspect and debug, but app code should generally use generated helpers and `@reactive-view/core` rather than hard-coding endpoint calls.
