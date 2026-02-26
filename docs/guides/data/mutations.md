# Mutations

Mutations are write actions on loader classes, backed by typed shape validation and generated TS helpers.

## Define a mutation

```ruby
shape :update do
  param :name
  param :email
end

params_shape :update, :update

def update
  result = shapes.update.call!(params)

  if user.update(result.data)
    render_success(user: { id: user.id, name: user.name })
  else
    render_error(user)
  end
end
```

## Generated TypeScript helpers

After `bin/rails reactive_view:types:generate`, route loader files expose:

- `updateAction`
- `UpdateForm`
- `useForm("update")`
- `useAction`, `useSubmission`, `useSubmissions` re-export

## Response helpers

- `render_success(data = {})`
- `render_error(record_or_errors)`
- `mutation_redirect(path, revalidate: [])`

## Revalidation

Include `revalidate:` in success/redirect payloads to invalidate route caches on the client.

## JSON vs FormData

Use `createMutation()` for form submissions and `createJsonMutation()` for typed JSON programmatic writes.

See [Mutation API Reference](../../reference/typescript/mutation-api.md) and [MutationResult Reference](../../reference/ruby/mutation-result.md).
