# Type Generation

ReactiveView generates TS files from Ruby loader shapes.

## Command

```bash
bin/rails reactive_view:types:generate
```

## Output

- `.reactive_view/types/loaders/**` per-route modules
- `.reactive_view/types/loader-data.d.ts` central cross-route type map

## Per-route modules include

- `LoaderData` interface
- `useLoaderData()` and `preloadData()`
- mutation interfaces/actions/forms for mutation shapes
- `useForm()` helper
- `useStream()` helper for streaming mutations

## When to regenerate

Regenerate after:

- editing any `shape` blocks
- changing `params_shape`/`response_shape` assignments
- adding/removing loaders or mutation methods

In development, loader file changes also trigger regeneration automatically via the file watcher.

See [Generated Loader Files Reference](../../reference/typescript/generated-loader-files.md).
