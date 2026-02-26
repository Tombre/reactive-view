# Ruby: Shape

`ReactiveView::Shape` validates and coerces hash-like inputs against a Dry::Types schema.

## Class API

- `shape(&block)` define schema
- `dry_schema` return built schema
- `call(input = {})` non-raising result instance
- `call!(input = {})` raises `ReactiveView::ValidationError` on failure

## Instance API

- `data` coerced/validated hash
- `errors` structured field errors
- `valid?`, `success?`, `failure?`

## Validation behavior

- filters unknown keys
- coerces primitives where possible
- reports nested errors with path keys (for example `"user.email"`)

## Typical use in loaders

```ruby
result = shapes.update.call(params)
if result.valid?
  Model.update(result.data)
else
  render_error(result.errors)
end
```
