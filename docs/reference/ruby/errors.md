# Ruby: Errors

Top-level custom errors under `ReactiveView`:

- `ReactiveView::Error`
- `ReactiveView::ConfigurationError`
- `ReactiveView::RenderError`
- `ReactiveView::DaemonUnavailableError`
- `ReactiveView::ValidationError`
- `ReactiveView::LoaderNotFoundError`
- `ReactiveView::BenchmarkError`

## Common sources

- render transport failures -> `DaemonUnavailableError`
- daemon returned render error -> `RenderError`
- shape validation failures -> `ValidationError`
- invalid loader path resolution -> `LoaderNotFoundError`

In development/test, internal controller responses include richer error payloads for debugging.
