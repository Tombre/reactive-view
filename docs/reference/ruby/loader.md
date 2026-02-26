# Ruby: Loader

`ReactiveView::Loader < ActionController::Base`

## Purpose

- entry controller for page requests (`#call`)
- data provider (`#load`)
- mutation host methods (`#update`, `#delete`, etc.)

## Class-level API

- `shape(name, klass = nil, &block)`
- `params_shape(action, shape_ref)`
- `response_shape(action, shape_ref)`
- `resolve_shape(ref)`
- `resolve_params_shape(action)`
- `resolve_response_shape(action)`

## Instance API

- `call` (SSR render through daemon)
- `load` (default `{}`)
- `shapes` -> `ShapesAccessor`
- `render_success(data = {})` -> `MutationResult`
- `render_error(record_or_errors)` -> `MutationResult`
- `mutation_redirect(path, revalidate: [])` -> `MutationResult`
- `render_stream { |writer| ... }` -> `StreamResponse`

## Notes

- supports `before_action` and other controller features
- `call` forwards cookies and CSRF token to daemon renderer
