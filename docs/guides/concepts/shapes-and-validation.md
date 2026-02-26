# Shapes and Validation

ReactiveView shapes define data contracts between Ruby loaders and TypeScript consumers.

## What a shape does

- declares structure and types for params/response
- generates TS interfaces and typed helpers
- validates and coerces data (especially in dev/test)

## Basic shape

```ruby
shape :load do
  param :id, :integer
  param :name
  param :active, :boolean
end

response_shape :load, :load
```

## Assigning shapes to actions

- `response_shape :load, :load` validates loader output
- `params_shape :update, :update` validates mutation input

The `shape` call only registers the definition; assignment happens separately.

## Nested objects and arrays

```ruby
shape :load do
  hash :user do
    param :id, :integer
    param :name
  end

  collection :items do
    param :sku
    param :qty, :integer
  end
end
```

## Non-raising vs raising validation

```ruby
result = shapes.update.call(params)
result.valid?
result.errors

result = shapes.update.call!(params)
result.data
```

`call!` raises `ReactiveView::ValidationError` on invalid input.

## Coercion behavior

Incoming request params are often strings. `ReactiveView::Shape` coerces common primitives (integer/float/bool/array/hash) before schema validation.

For API details, see:

- [Shape Reference](../../reference/ruby/shape.md)
- [Types DSL Reference](../../reference/ruby/types-dsl.md)
