# Ruby: Types DSL

Source: `ReactiveView::Types` and `ReactiveView::Types::SignatureBuilder`.

## Type shortcuts

- `:string`
- `:integer`
- `:float`
- `:boolean` / `:bool`
- `:date`
- `:date_time`
- `:time`
- `:any`

## Core helpers

- `param :name, type`
- `collection :items do ... end`
- `hash :user do ... end`

## Dry type wrappers

- `ReactiveView::Types::Optional[T]`
- `ReactiveView::Types::Array[T]`

## Example

```ruby
shape :load do
  param :id, :integer
  hash :profile do
    param :name
  end
  param :tags, ReactiveView::Types::Array[ReactiveView::Types::String]
end
```
