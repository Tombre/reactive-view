# Ruby: File Sync

`ReactiveView::FileSync` coordinates workspace generation, wrappers, and type generation.

## Facade methods

- `sync_all`
- `start_watching`
- `stop_watching`
- `private_path?(path)`

## Internal components

- `DirectorySetup`: creates/maintains `.reactive_view`
- `ComponentSyncer`: copies page files for non-dev/prod build workflows
- `WrapperGenerator`: generates route wrapper files in `.reactive_view/src/routes`
- `FileWatcher`: listens for file changes in `app/pages`
- `ViteNotifier`: POST invalidation events to daemon Vite middleware

## Dev vs production

- development: wrappers generated; Vite imports from `~pages`
- production: pages copied into `.reactive_view/src/pages` for self-contained build

## Internal stability

These classes are documented for debugging but considered internal and subject to change.
