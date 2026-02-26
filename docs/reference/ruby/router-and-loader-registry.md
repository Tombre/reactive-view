# Ruby: Router and LoaderRegistry

## Router (`ReactiveView::Router`)

Primary API:

- `ReactiveView::Router.draw(router)`

Behavior:

- mounts engine at `/_reactive_view`
- scans `app/pages/**/*.tsx`
- ignores private `_` paths
- maps file routes to loader classes and `Loader#call`
- sorts route priority (static before dynamic/optional/catch-all)

## LoaderRegistry (`ReactiveView::LoaderRegistry`)

Primary API:

- `load_all`
- `loader_files`
- `class_for_path(loader_path)`
- `path_to_class_name(loader_path)`
- `file_to_loader_path(file_path)`
- `all_loader_paths`

Behavior:

- manually loads `*.loader.rb` files
- maps route-like loader paths (`users/[id]`) to class names (`Pages::Users::IdLoader`)
- falls back to `ReactiveView::Loader` when class missing
