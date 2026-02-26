# TypeScript: Vite Plugin API (`@reactive-view/core/vite-plugin`)

## `reactiveViewPlugin(options?)`

Options:

- `debug?: boolean`
- `pagesPath?: string` (absolute path to Rails `app/pages`)

## Responsibilities

- resolve `#loaders/*` imports to generated files in `.reactive_view/types/loaders/*`
- add dev middleware endpoint `POST /__reactive_view/invalidate-loader`
- emit custom HMR event `reactive-view:loader-update`
- normalize HMR websocket path for non-root base paths
- register `~pages` alias in dev when `pagesPath` is provided

## Helper export

- `invalidateLoaders(server, routes, type = "modified")`
