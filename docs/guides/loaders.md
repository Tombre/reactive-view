# Loaders Guide

This guide covers how to use ReactiveView loaders to provide data from Rails to your SolidJS page components.

## Overview

Loaders are the primary mechanism for passing data from Rails to your frontend. Each loader is a Ruby class that extends `ReactiveView::Loader` (which itself extends `ActionController::Base`), meaning loaders are full Rails controllers with access to `params`, `request`, `session`, `before_action` callbacks, and more.

When a page is requested:

1. Rails routes the request to the loader's `call` method
2. The loader forwards the request to the SolidStart daemon for SSR
3. During SSR, SolidStart calls back to Rails to fetch loader data via `LoaderDataController`
4. The loader's `load` method returns data as JSON
5. The page component receives the data through `useLoaderData()`

## Creating a Loader

Loaders live alongside your page files in `app/pages/` with a `.loader.rb` extension:

```
app/pages/
├── users/
│   ├── index.tsx           # Page component
│   ├── index.loader.rb     # Loader for /users
│   ├── [id].tsx            # Page component
│   └── [id].loader.rb     # Loader for /users/:id
└── index.tsx               # Home page (no loader needed if no data)
```

### Naming Convention

Loader class names follow the file path with `Pages::` module prefix:

| File Path | Class Name |
| --- | --- |
| `app/pages/users/index.loader.rb` | `Pages::Users::IndexLoader` |
| `app/pages/users/[id].loader.rb` | `Pages::Users::IdLoader` |
| `app/pages/blog/[...slug].loader.rb` | `Pages::Blog::SlugLoader` |
| `app/pages/(admin)/dashboard.loader.rb` | `Pages::Admin::DashboardLoader` |

Dynamic segments like `[id]` become the capitalized param name (`Id`), route groups like `(admin)` drop the parentheses, and catch-all segments like `[...slug]` use just the param name (`Slug`).

### Basic Example

```ruby
# app/pages/users/index.loader.rb
module Pages
  module Users
    class IndexLoader < ReactiveView::Loader
      shape :load do
        param :users, ReactiveView::Types::Array[
          ReactiveView::Types::Hash.schema(
            id: ReactiveView::Types::Integer,
            name: ReactiveView::Types::String,
            email: ReactiveView::Types::String
          )
        ]
        param :total, ReactiveView::Types::Integer
      end

      def load
        {
          users: User.order(:name).limit(20).map do |user|
            { id: user.id, name: user.name, email: user.email }
          end,
          total: User.count
        }
      end
    end
  end
end
```

### Dynamic Routes

For dynamic routes, access route parameters via `params`:

```ruby
# app/pages/users/[id].loader.rb
module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      shape :load do
        param :user, ReactiveView::Types::Hash.schema(
          id: ReactiveView::Types::Integer,
          name: ReactiveView::Types::String,
          email: ReactiveView::Types::String,
          created_at: ReactiveView::Types::String
        )
      end

      def load
        user = User.find(params[:id])
        {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            created_at: user.created_at.iso8601
          }
        }
      end
    end
  end
end
```

## Shape Definitions

The `shape` DSL defines the type signature for your loader's return value. This serves two purposes:

1. **TypeScript type generation** - Auto-generates typed `useLoaderData()` hooks
2. **Runtime validation** - Validates responses in development/test environments

### Basic Types

```ruby
shape :load do
  param :id, ReactiveView::Types::Integer
  param :name, ReactiveView::Types::String
  param :email, ReactiveView::Types::Optional[ReactiveView::Types::String]
  param :active, ReactiveView::Types::Bool
end
```

### Available Types

| Ruby Type | TypeScript Type | Description |
| --- | --- | --- |
| `ReactiveView::Types::String` | `string` | String values |
| `ReactiveView::Types::Integer` | `number` | Integer values |
| `ReactiveView::Types::Float` | `number` | Floating point values |
| `ReactiveView::Types::Bool` | `boolean` | Boolean values |
| `ReactiveView::Types::Array[T]` | `T[]` | Typed arrays |
| `ReactiveView::Types::Hash.schema(...)` | `{ ... }` | Typed objects |
| `ReactiveView::Types::Optional[T]` | `T \| null` | Nullable values |
| `ReactiveView::Types::Any` | `unknown` | Any type |

### Nested Types

```ruby
shape :load do
  param :user, ReactiveView::Types::Hash.schema(
    id: ReactiveView::Types::Integer,
    name: ReactiveView::Types::String,
    address: ReactiveView::Types::Hash.schema(
      street: ReactiveView::Types::String,
      city: ReactiveView::Types::String,
      zip: ReactiveView::Types::String
    )
  )
  param :tags, ReactiveView::Types::Array[ReactiveView::Types::String]
  param :metadata, ReactiveView::Types::Hash.schema(
    created_at: ReactiveView::Types::String,
    updated_at: ReactiveView::Types::String
  )
end
```

### Implicit :load

When you call `shape` without a method name, it defaults to `:load`:

```ruby
# These are equivalent:
shape :load do
  param :name, ReactiveView::Types::String
end

shape do
  param :name, ReactiveView::Types::String
end
```

### Response Validation

In development and test environments (controlled by `config.validate_responses = true`), loader responses are validated against their shape definitions:

```ruby
def load
  { id: "not an integer" }  # Raises ValidationError: id must be Integer
end
```

This helps catch type mismatches early. Validation is skipped in production for performance.

## Using Loader Data in Components

### Auto-typed Imports (Recommended)

Import `useLoaderData` from the route-specific generated loader file for full type safety:

```tsx
// app/pages/users/index.tsx
import { useLoaderData } from "#loaders/users/index";

export default function UsersPage() {
  const data = useLoaderData(); // Fully typed as LoaderData!

  return (
    <div>
      <h1>Users ({data()?.total})</h1>
      <ul>
        {data()?.users.map((user) => (
          <li>{user.name} - {user.email}</li>
        ))}
      </ul>
    </div>
  );
}
```

The `#loaders/*` import path maps to auto-generated TypeScript files in `.reactive_view/types/loaders/`. These are generated by running:

```bash
bin/rails reactive_view:types:generate
```

### Cross-Route Loading

Load data from a different route by specifying the route path:

```tsx
import { useLoaderData } from "@reactive-view/core";

export default function DashboardPage() {
  // Load users data from the users/index route
  const usersData = useLoaderData("users/index");

  // Load a specific user with params
  const userData = useLoaderData("users/[id]", { id: "123" });

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Total users: {usersData()?.total}</p>
      <p>Featured user: {userData()?.user.name}</p>
    </div>
  );
}
```

Cross-route types are powered by the central route map generated at `.reactive_view/types/loader-data.d.ts`.

### Manual Typing

You can also provide explicit type parameters:

```tsx
import { useLoaderData } from "@reactive-view/core";

interface MyData {
  name: string;
  count: number;
}

export default function MyPage() {
  const data = useLoaderData<MyData>();
  return <div>{data()?.name}: {data()?.count}</div>;
}
```

## Authentication

Since loaders extend `ActionController::Base`, use standard Rails `before_action` callbacks for authentication and authorization:

```ruby
# app/pages/(admin)/dashboard.loader.rb
module Pages
  module Admin
    class DashboardLoader < ReactiveView::Loader
      before_action :authenticate_admin!

      shape :load do
        param :stats, ReactiveView::Types::Hash.schema(
          total_users: ReactiveView::Types::Integer,
          active_users: ReactiveView::Types::Integer
        )
      end

      def load
        { stats: { total_users: User.count, active_users: User.where(active: true).count } }
      end

      private

      def authenticate_admin!
        redirect_to "/login" unless current_user&.admin?
      end
    end
  end
end
```

Authentication works during both SSR and client-side navigation because cookies are forwarded to the loader in both cases.

## Preloading Data

The generated loader files include a `preloadData` function for prefetching data before navigation:

```tsx
// In your generated loader file (.reactive_view/types/loaders/users/index.ts):
// export function preloadData(params: Record<string, string> = {}): void;

// Use it in a navigation component:
import { preloadData } from "#loaders/users/index";
import { A } from "@solidjs/router";

function Nav() {
  return (
    <A href="/users" onMouseEnter={() => preloadData()}>
      Users
    </A>
  );
}
```

Preloading uses Solid Router's `query()` for automatic caching, so data is available instantly when the user navigates.

## HMR Support

During development, when you edit a `.loader.rb` file, the data automatically refreshes without a full page reload. ReactiveView broadcasts a `reactive-view:loader-update` event through Vite's HMR system, which triggers all active `useLoaderData()` hooks to refetch.

## Testing Loaders

Since loaders are Rails controllers, test them like any controller:

```ruby
RSpec.describe Pages::Users::IndexLoader do
  describe "#load" do
    it "returns users" do
      create(:user, name: "Alice")

      loader = described_class.new
      result = loader.load

      expect(result[:users].first[:name]).to eq("Alice")
      expect(result[:total]).to eq(1)
    end
  end
end
```

For loaders that use `params`, set them up via `ActionController::Parameters`:

```ruby
RSpec.describe Pages::Users::IdLoader do
  describe "#load" do
    it "returns the user" do
      user = create(:user, name: "Alice")

      loader = described_class.new
      loader.params = ActionController::Parameters.new(id: user.id.to_s)
      result = loader.load

      expect(result[:user][:name]).to eq("Alice")
    end
  end
end
```

## Architecture: How Loaders Work Internally

Understanding the request flow helps with debugging:

```
1. Browser requests /users/123
2. Rails Router → Pages::Users::IdLoader#call
3. Loader#call → Renderer.render (HTTP POST to SolidStart daemon)
4. SolidStart SSR → calls GET /_reactive_view/loaders/users/[id]/load?id=123
5. LoaderDataController#show → instantiates IdLoader, calls #load
6. JSON response → SolidStart injects data into component → HTML response
7. Browser hydrates → useLoaderData() has data immediately
```

For client-side navigation (after initial page load):
```
1. Client-side router navigates to /users/123
2. useLoaderData() fetches GET /_reactive_view/loaders/users/[id]/load?id=123
3. LoaderDataController#show → instantiates IdLoader, calls #load
4. JSON response → component updates reactively
```

## Loader Files and Mutations

Loader files can also define mutations. See the [Mutations Guide](mutations.md) for details on how to add create, update, and delete operations alongside your loader data.
