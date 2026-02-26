# Loaders

Loaders are Rails controllers that provide typed data to TSX pages.

## Loader lifecycle

- define `load` in `app/pages/**/*.loader.rb`
- assign `response_shape :load, :shape_name`
- consume with `useLoaderData()` in TSX

## Example

```ruby
module Pages
  module Users
    class IndexLoader < ReactiveView::Loader
      shape :load do
        collection :users do
          param :id, :integer
          param :name
        end
      end

      response_shape :load, :load

      def load
        { users: User.order(:name).map { |u| { id: u.id, name: u.name } } }
      end
    end
  end
end
```

```tsx
import { useLoaderData } from "#loaders/users/index";

export default function UsersPage() {
  const data = useLoaderData();
  return <div>{data()?.users.length} users</div>;
}
```

## Cross-route loading

Use `@reactive-view/core` directly:

```tsx
import { useLoaderData } from "@reactive-view/core";

const users = useLoaderData("users/index");
const user = useLoaderData("users/[id]", { id: "123" });
```

## Preloading

Generated loader modules include `preloadData(params)` for route prefetch.

## Validation

When response validation is enabled in dev/test, output is checked against the assigned response shape.

See [Loader Reference](../../reference/ruby/loader.md) and [Loader TS API](../../reference/typescript/loader-api.md).
