# HMR and File Sync

ReactiveView uses a wrapper route architecture to preserve Hot Module Replacement.

## Why wrappers exist

Vinxi route-file changes can trigger full reload. ReactiveView avoids this by keeping route wrapper files stable and hot-reloading page source files.

## Development behavior

- wrappers are generated in `.reactive_view/src/routes`
- wrappers import pages from `~pages/*` alias (pointing to `app/pages/*`)
- file watcher handles additions/removals and loader updates

## Production behavior

For production builds, source files are copied to `.reactive_view/src/pages` so build artifacts are self-contained.

## Loader-file HMR

When `*.loader.rb` changes in development:

1. TS types regenerate
2. Rails notifies Vite at `POST /__reactive_view/invalidate-loader`
3. Vite broadcasts `reactive-view:loader-update`
4. active `useLoaderData()` hooks refetch

This refreshes data without a hard page reload.

See [File Sync Reference](../../reference/ruby/file-sync.md) and [Vite Plugin Reference](../../reference/typescript/vite-plugin-api.md).
