# ReactiveView

ReactiveView is a Ruby on Rails "view framework" gem for creating modern reactive frontends for your Rails application. ReactiveView essentially replaces the view layer of your Rails application - think of it as a rendering engine, a router, and a data loader all in one.

Build your frontend with TSX components (TypeScript + SolidJS), with all data, auth, and business logic still handled by Rails!

## Features

- **SSR with Reactive Interactivity** - Server-side rendered pages that hydrate into fully interactive SolidJS applications
- **Type Safety** - Automatic TypeScript type generation from your Ruby shape definitions
- **Directory-Based Routing** - SolidStart-style file-based routing from `app/pages/`
- **Mutations** - Define data mutations alongside loaders with auto-generated forms, CSRF protection, and typed params
- **Rails Integration** - Use Rails for auth, models, business logic - SolidJS for the UI

## Motivation

There has been an explosion of "frontend-first" JS frameworks (Next.js, Remix, SolidStart, etc.) that have made it easier than ever to build highly reactive frontends. These frameworks do incredible things: loading minimal JavaScript, building in reusable components, and enabling reactive stateful UIs.

Rails has historically opted for simpler frontend tooling to reduce complexity - at the expense of not having modern frontend capabilities. But Rails excels at backend stuff: data models, business logic, and application architecture.

**ReactiveView bridges this gap** - use Rails for what it's great at (backend) and SolidJS for what it's great at (frontend), without the maintenance overhead of two separate services.

## How It Works

ReactiveView coordinates between two components:

1. **Rails Engine** - Handles routing and requests, coordinates with SolidStart
2. **SolidStart Daemon** - Server-side renders TSX components

```
Client Request
      │
      ▼
┌─────────────────────────────────────────┐
│           Rails Application              │
│  ┌────────────────────────────────────┐ │
│  │  ReactiveView::Loader              │ │
│  │  - Auth (before_action)            │ │
│  │  - Generate request token          │ │
│  └────────────────────────────────────┘ │
│                  │                       │
│                  ▼                       │
│  ┌────────────────────────────────────┐ │
│  │  SolidStart Daemon                 │ │
│  │  - SSR render page                 │ │
│  │  - Calls back to Rails for data    │ │
│  └────────────────────────────────────┘ │
│                  │                       │
│                  ▼                       │
│  ┌────────────────────────────────────┐ │
│  │  ReactiveView::LoaderDataController│ │
│  │  - Validates token                 │ │
│  │  - Returns loader data as JSON     │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
      │
      ▼
   HTML Response (SSR + hydration scripts)
```

## Project Structure

```
reactive-view/
├── reactive_view/              # The gem
│   ├── lib/
│   │   └── reactive_view/      # Core Ruby code
│   ├── app/
│   │   └── controllers/        # Engine controllers
│   ├── npm/                    # @reactive-view/core npm package
│   │   └── src/                # TypeScript source
│   ├── template/               # SolidStart template
│   │   └── src/
│   │       ├── pages/          # Synced page components (HMR works here)
│   │       ├── routes/         # Generated route wrappers
│   │       └── routes/api/     # Render endpoint
│   └── spec/                   # Tests
│
├── examples/
│   └── reactive_view_example/  # Example Rails app
│       ├── app/pages/          # ReactiveView pages (source)
│       └── .reactive_view/     # Generated SolidStart project
│           └── src/
│               ├── pages/      # Synced components
│               └── routes/     # Generated wrappers
│
└── docs/
    ├── design/overview.md      # Design document
    ├── guides/                 # User-facing guides
    │   ├── loaders.md          # Loaders guide
    │   ├── mutations.md        # Mutations guide
    │   └── configuration.md    # Configuration guide
    └── agent/tasks/            # Follow-up tasks
```

## Quick Start

### Using the Example App

The fastest way to explore ReactiveView is via the included example:

```bash
# Clone the repository
git clone <repo-url>
cd reactive-view-ai

# Easiest start from repo root (installs deps, prepares DB, runs setup if needed)
bin/start-example

# Or follow the manual steps below

# Navigate to example app
cd examples/reactive_view_example

# Install Ruby dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Setup ReactiveView (creates .reactive_view directory, installs npm packages)
bin/rails reactive_view:setup

# Start development servers
bin/dev
```

Visit http://localhost:3000 to see the example application.

### Example Pages

| Route        | File                        | Description                        |
| ------------ | --------------------------- | ---------------------------------- |
| `/`          | `app/pages/index.tsx`       | Home page with interactive counter |
| `/about`     | `app/pages/about.tsx`       | Static about page                  |
| `/counter`   | `app/pages/counter.tsx`     | SolidJS signals & effects demo     |
| `/users`     | `app/pages/users/index.tsx` | User list (data from loader)       |
| `/users/:id` | `app/pages/users/[id].tsx`  | User detail (dynamic route)        |

### Creating Pages

Pages are TSX files in `app/pages/`:

```tsx
// app/pages/hello.tsx
export default function HelloPage() {
  return <h1>Hello, World!</h1>;
}
```

This creates a route at `/hello`.

### Loading Data

Create a loader file alongside your page:

```ruby
# app/pages/users/[id].loader.rb
module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      shape :load do
        hash :user do
          param :id, :integer
          param :name
        end
      end

      def load
        user = User.find(params[:id])
        { user: { id: user.id, name: user.name } }
      end
    end
  end
end
```

```tsx
// app/pages/users/[id].tsx
import { useLoaderData } from "#loaders/users/[id]";

export default function UserPage() {
  // Types are automatically inferred from the Ruby shape definition!
  const data = useLoaderData();

  return <h1>Hello, {data()?.user.name}</h1>;
}
```

The `#loaders/*` import path maps to auto-generated TypeScript files that provide full type safety based on your Ruby `shape` definitions.

### Authentication

Loaders are regular Rails controllers - use `before_action` for auth:

```ruby
class Pages::Admin::DashboardLoader < ReactiveView::Loader
  before_action :authenticate_admin!

  def load
    { stats: AdminStats.current }
  end

  private

  def authenticate_admin!
    redirect_to login_path unless current_user&.admin?
  end
end
```

## Development

### Prerequisites

- Ruby 3.1+
- Rails 7.0+
- Node.js 18+
- npm

### Working on the Gem

```bash
cd reactive_view

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run specific tests
bundle exec rspec spec/reactive_view/types/
```

### Gem Structure

| File                                   | Purpose                        |
| -------------------------------------- | ------------------------------ |
| `lib/reactive_view.rb`                 | Main entry point               |
| `lib/reactive_view/engine.rb`          | Rails Engine                   |
| `lib/reactive_view/loader.rb`          | Base controller class          |
| `lib/reactive_view/mutation_result.rb` | Mutation response value object |
| `lib/reactive_view/shapes_accessor.rb` | Typed param extraction         |
| `lib/reactive_view/router.rb`          | File-based route generation    |
| `lib/reactive_view/renderer.rb`        | HTTP client to SolidStart      |
| `lib/reactive_view/daemon.rb`          | SolidStart process manager     |
| `lib/reactive_view/request_context.rb` | Token-based auth for callbacks |
| `lib/reactive_view/types/`             | Type system (Dry::Types)       |

### SolidStart Template

The `reactive_view/template/` directory contains the SolidStart project template:

| File                       | Purpose                               |
| -------------------------- | ------------------------------------- |
| `src/pages/`               | Synced page components (HMR-friendly) |
| `src/routes/`              | Generated route wrappers              |
| `src/routes/api/render.ts` | Endpoint Rails calls for SSR          |

### HMR Architecture

ReactiveView uses a wrapper pattern to enable true Hot Module Replacement:

```
app/pages/counter.tsx         → .reactive_view/src/pages/counter.tsx (synced)
                                         ↓
                              .reactive_view/src/routes/counter.tsx (wrapper)
```

- **`src/pages/`** - Contains actual page components synced from `app/pages/`
- **`src/routes/`** - Contains thin wrappers that import from `src/pages/`

When you edit a page, only `src/pages/` changes. Vinxi's router sees no route changes, so Vite can hot-swap the component without a full reload.

### Working on the Example App

```bash
cd examples/reactive_view_example

# Start both Rails and SolidStart
bin/dev

# Or start them separately:
bin/rails server                    # Rails on :3000
cd .reactive_view && npm run dev    # SolidStart on :3001
```

### Useful Rake Tasks

```bash
# Show all ReactiveView routes
bin/rails reactive_view:routes

# Sync TSX files to .reactive_view
bin/rails reactive_view:sync

# Generate TypeScript types from loaders
bin/rails reactive_view:types:generate

# Daemon management
bin/rails reactive_view:daemon:start
bin/rails reactive_view:daemon:stop
bin/rails reactive_view:daemon:status

# Production build
bin/rails reactive_view:build
```

## Tailwind CSS Setup

ReactiveView ships with Tailwind CSS v4 support through the `@tailwindcss/vite` plugin. To add Tailwind to a new application:

1. Install the dependencies inside your `.reactive_view` directory:

```bash
cd .reactive_view
npm install --save-dev tailwindcss @tailwindcss/vite
```

2. Register the plugin in `reactive_view.config.ts` (Rails root):

```ts
import { defineConfig } from "@reactive-view/core/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  vitePlugins: [tailwindcss()],
});
```

3. Create `app/pages/_styles/tailwind.css`:

```css
@import "tailwindcss" source("../");

@theme {
  --font-sans: system-ui, sans-serif;
}
```

The `source("../")` directive makes Tailwind scan all synced components inside `.reactive_view/src/pages` after `reactive_view:sync` copies files over.

4. Import the stylesheet once (for example in `app/pages/_components/MainLayout.tsx`):

```ts
import "../_styles/tailwind.css";
```

5. Whenever you edit files under `app/pages/`, run `bin/rails reactive_view:sync` so Tailwind sees the changes in `.reactive_view/src`.

This setup keeps Tailwind fully managed by Vite, aligns with Tailwind v4’s CSS-first configuration, and avoids separate PostCSS steps.

## Testing

### Running Gem Tests

```bash
cd reactive_view
bundle exec rspec
```

### Test Coverage

Current tests cover:

- `RequestContext` - Token generation, storage, retrieval, validation
- `Types::SignatureBuilder` - DSL for defining loader signatures
- `Types::Validator` - Response validation against schemas
- `MutationResult` - Success, error, redirect result objects
- `ShapesAccessor` - Typed parameter extraction for mutations
- `LoaderRegistry` - Loader class discovery and mapping

### Testing Your Application

Since loaders are Rails controllers, test them like any controller:

```ruby
RSpec.describe Pages::Users::IndexLoader do
  describe "#load" do
    it "returns users" do
      create(:user, name: "Alice")

      loader = described_class.new
      result = loader.load

      expect(result[:users].first[:name]).to eq("Alice")
    end
  end
end
```

## Configuration

```ruby
# config/initializers/reactive_view.rb
ReactiveView.configure do |config|
  # SolidStart daemon settings
  config.daemon_host = "localhost"
  config.daemon_port = 3001
  config.daemon_timeout = 30

  # Auto-start daemon with Rails (development only)
  config.auto_start_daemon = Rails.env.development?

  # External daemon (production - managed separately)
  config.external_daemon = Rails.env.production?

  # Paths
  config.pages_path = "app/pages"
  config.working_directory = ".reactive_view"

  # Validate loader responses in dev/test
  config.validate_responses = true
end
```

## Routing Conventions

ReactiveView uses SolidStart-style file-based routing:

| File                           | Route                     |
| ------------------------------ | ------------------------- |
| `app/pages/index.tsx`          | `/`                       |
| `app/pages/about.tsx`          | `/about`                  |
| `app/pages/users/index.tsx`    | `/users`                  |
| `app/pages/users/[id].tsx`     | `/users/:id`              |
| `app/pages/blog/[...slug].tsx` | `/blog/*slug`             |
| `app/pages/users/[[id]].tsx`   | `/users(/:id)` (optional) |
| `app/pages/_components/*.tsx`  | (none - private folder)   |
| `app/pages/_helpers.ts`        | (none - private file)     |

### Private Folders and Files

Files and folders prefixed with underscore (`_`) are **private** - they are included in the SolidStart bundle (so you can import them) but do NOT become routes.

Use this for colocating:

- Shared components: `_components/Button.tsx`
- Utility functions: `_utils/formatDate.ts`
- Styles: `_styles/variables.css`
- Route-specific partials: `users/_partials/UserCard.tsx`

```
app/pages/
├── _components/           # Private - no routes generated
│   ├── Button.tsx
│   └── Navigation.tsx
├── _styles/               # Private - no routes generated
│   └── variables.css
├── users/
│   ├── _partials/         # Nested private folder
│   │   └── UserCard.tsx
│   ├── index.tsx          # Route: /users
│   └── [id].tsx           # Route: /users/:id
├── index.tsx              # Route: /
└── about.tsx              # Route: /about
```

Import private files like any other module:

```tsx
// app/pages/users/index.tsx
import { Button } from "../_components/Button";
import { UserCard } from "./_partials/UserCard";
```

### Nested Layouts

Create a file with the same name as a folder to make it a layout:

```
app/pages/
├── blog.tsx              # Layout for /blog/*
└── blog/
    ├── article-1.tsx     # /blog/article-1
    └── article-2.tsx     # /blog/article-2
```

```tsx
// app/pages/blog.tsx
import { RouteSectionProps } from "@solidjs/router";

export default function BlogLayout(props: RouteSectionProps) {
  return (
    <div class="blog-layout">
      <nav>Blog Navigation</nav>
      {props.children}
    </div>
  );
}
```

## Type System

ReactiveView uses [Dry::Types](https://dry-rb.org/gems/dry-types/) for type definitions. Use the `shape` method to define named type signatures, then assign them to actions with `params_shape` and `response_shape`:

```ruby
shape :load do
  param :id, :integer
  param :name                                                    # defaults to String
  param :email, ReactiveView::Types::Optional[Types::String]     # explicit Dry type
  param :tags, ReactiveView::Types::Array[Types::String]         # simple typed array
  hash :metadata do                                              # nested hash
    param :created_at
    param :updated_at
  end
end

response_shape :load, :load
```

The `shape` method registers a named shape definition. Use `response_shape` to assign a shape as the response type for an action, and `params_shape` to assign it as the params type for a mutation. Symbol shortcuts (`:integer`, `:string`, `:boolean`, `:float`, `:date`, `:date_time`, `:time`, `:any`) and the `collection`/`hash` DSL helpers make definitions concise:

```ruby
# Response shape for the load action
shape :load do
  collection :users do    # array of hashes
    param :id, :integer
    param :name
  end
end
response_shape :load, :load

# Mutation shapes
shape :update do
  param :name
  param :email
end
params_shape :update, :update

shape :delete do
end
params_shape :delete, :delete
```

### Response Validation

In development and test modes, loader responses are validated against their shape definitions:

```ruby
def load
  { id: "not an integer" }  # ValidationError: id must be Integer
end
```

### TypeScript Generation

Generate TypeScript types from your loaders:

```bash
bin/rails reactive_view:types:generate
```

This creates:

1. **Per-route loader files** in `.reactive_view/types/loaders/` - auto-typed `useLoaderData()` hooks, plus mutation actions and Form components when mutations are defined
2. **Central route map** in `.reactive_view/types/loader-data.d.ts` - for cross-route loading

## TypeScript & Editor Setup

ReactiveView provides full TypeScript support for your TSX pages. After running `rails reactive_view:install`, your project will have:

- `package.json` - with `@reactive-view/core` and SolidJS dependencies
- `tsconfig.json` - configured for SolidJS JSX and `#loaders/*` path resolution

### Installation

```bash
# After adding reactive_view to your Gemfile and running bundle install
rails reactive_view:install

# This creates package.json and tsconfig.json at your project root
# Then install npm dependencies:
npm install

# Generate TypeScript types for your loaders
bin/rails reactive_view:types:generate
```

### Editor Support

Your editor (VSCode, etc.) should now:

- Recognize TSX files in `app/pages/`
- Provide autocomplete for SolidJS primitives
- Show fully-typed `useLoaderData()` with automatic type inference

### Loading Data - Two Approaches

#### 1. Auto-typed Imports (Recommended)

Import from the route-specific loader path. Types are automatically inferred:

```tsx
// app/pages/users/index.tsx
import { useLoaderData } from "#loaders/users/index";

export default function UsersPage() {
  const data = useLoaderData(); // Fully typed!
  return <div>{data()?.total} users</div>;
}
```

#### 2. Cross-Route Loading

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

### SolidJS Primitives

ReactiveView uses SolidJS TSX, not React JSX.

For SolidJS primitives, import directly from `solid-js`:

```tsx
import { createSignal, createEffect, For, Show } from "solid-js";
import { A, useParams } from "@solidjs/router";
```

### Mutations

Define data mutations alongside your loaders in `.loader.rb` files. Mutations use `shape` to define their params, then `params_shape` to assign:

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

      shape :update do
        param :name
        param :email
      end

      # Assign shapes to actions
      response_shape :load, :load
      params_shape :update, :update

      def load
        { user: { id: user.id, name: user.name, email: user.email } }
      end

      def update
        result = shapes.update.call!(params)

        if user.update(result.data)
          render_success(user: { id: user.id, name: user.name, email: user.email })
        else
          render_error(user)
        end
      end

      private

      def user
        @user ||= User.find(params[:id])
      end
    end
  end
end
```

The `shapes.update` call returns the Shape **class** (not validated data). Call `.call!(params)` for raising validation or `.call(params)` for non-raising. The result is a Shape instance with `.valid?`, `.data`, and `.errors`:

```ruby
# Raising — raises ReactiveView::ValidationError on failure
result = shapes.update.call!(params)
result.data  # => { name: "Alice", email: "alice@example.com" }

# Non-raising — check .valid? / .errors
result = shapes.update.call(params)
if result.valid?
  user.update(result.data)
else
  render json: { errors: result.errors }, status: :unprocessable_entity
end
```

After running `rails reactive_view:types:generate`, ReactiveView auto-generates typed actions and Form components:

```tsx
// app/pages/users/[id].tsx
import { Show } from "solid-js";
import {
  useLoaderData,
  UpdateForm,
  updateAction,
  useSubmission,
} from "#loaders/users/[id]";

export default function UserPage() {
  const data = useLoaderData();
  const submission = useSubmission(updateAction);

  return (
    <div>
      <h1>{data()?.user.name}</h1>

      <UpdateForm>
        <input name="name" value={data()?.user.name} />
        <input name="email" value={data()?.user.email} />
        <button type="submit" disabled={submission.pending}>
          {submission.pending ? "Saving..." : "Save"}
        </button>
      </UpdateForm>

      <Show when={submission.result?.errors}>
        <p>Error: {JSON.stringify(submission.result?.errors)}</p>
      </Show>
    </div>
  );
}
```

For the full guide on mutations including response helpers, programmatic submissions, CSRF handling, and error patterns, see [docs/guides/mutations.md](docs/guides/mutations.md).

For a detailed guide on data loading, see [docs/guides/loaders.md](docs/guides/loaders.md).

## Current Limitations (MVP)

This is an MVP implementation. Known limitations:

1. **Client-side navigation** - After hydration, client navigation needs manual data fetching setup
2. **Zeitwerk incompatibility** - Loader files are manually loaded due to `[param].loader.rb` naming
3. **Basic error handling** - No error boundary components yet

See [docs/agent/tasks/post-mvp.md](docs/agent/tasks/post-mvp.md) for the full roadmap.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`bundle exec rspec`)
4. Commit your changes (`git commit -am 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [SolidJS](https://www.solidjs.com/) - The reactive UI library powering the frontend
- [SolidStart](https://start.solidjs.com/) - The meta-framework providing SSR and routing
- [Dry::Types](https://dry-rb.org/gems/dry-types/) - The type system for Ruby
- [Ruby on Rails](https://rubyonrails.org/) - The web framework that makes it all possible
