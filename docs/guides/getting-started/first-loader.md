# Your First Loader

Loaders let Rails provide data to your SolidJS page.

## 1) Create the loader

```ruby
# app/pages/users/[id].loader.rb
module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      shape :load do
        hash :user do
          param :id, :integer
          param :name
          param :email
        end
      end

      response_shape :load, :load

      def load
        user = User.find(params[:id])
        { user: { id: user.id, name: user.name, email: user.email } }
      end
    end
  end
end
```

## 2) Generate types

```bash
bin/rails reactive_view:types:generate
```

## 3) Use typed loader data in TSX

```tsx
// app/pages/users/[id].tsx
import { useLoaderData } from "#loaders/users/[id]";

export default function UserPage() {
  const data = useLoaderData();
  return <h1>{data()?.user.name}</h1>;
}
```

## 4) Add auth with Rails callbacks

Because loaders are controllers, you can use `before_action`:

```ruby
before_action :authenticate_user!
```

Next: [Loaders Guide](../data/loaders.md)
