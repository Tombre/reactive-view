# Ruby: MutationResult

`ReactiveView::MutationResult` is a value object used by loader mutation methods.

## Constructors

- `MutationResult.success(data = {})`
- `MutationResult.error(errors_or_record)`
- `MutationResult.redirect(path, revalidate: [])`

## Attributes

- `type` (`:success`, `:error`, `:redirect`)
- `data`
- `errors`
- `redirect_path`
- `revalidate`
- `status`

## Predicates

- `success?`
- `error?`
- `redirect?`

## Serialization

`to_json_hash` output shape:

- success: `{ success: true, ...data, revalidate?: [...] }`
- error: `{ success: false, errors: ... }`
- redirect: `{ _redirect: "/path", _revalidate: [...] }`
