# ReactiveView Example Application

This is an example Rails application demonstrating the ReactiveView gem with Tailwind CSS for styling.

## Prerequisites

- Ruby 3.1+
- Node.js 18+
- npm

## Setup

1. Install dependencies:

```bash
bundle install
```

2. Setup the database:

```bash
bin/rails db:create db:migrate db:seed
```

3. Setup ReactiveView (creates `.reactive_view` directory and installs npm dependencies):

```bash
bin/rails reactive_view:setup
```

## Running the Application

Start the app (installs dependencies, prepares the database, runs setup if needed, then launches Rails):

```bash
bin/start
```

Already set up and just want to launch Rails?

```bash
bin/dev
```

This will start:

- Rails server on http://localhost:3000
- SolidStart daemon managed automatically by Rails in development

If port `3001` is already in use, ReactiveView will try to reclaim stale daemon listeners and otherwise pick the next available port for this Rails process.

For production, you can keep the daemon as a standalone service and point Rails to it with `config.external_daemon` and `config.daemon_host` / `config.daemon_port`.

## Running with Docker

You can run the example app in a single container (Rails + SolidStart daemon).

### Docker Compose (recommended)

From `examples/reactive_view_example/`:

```bash
docker compose up --build
```

Then open http://localhost:3000.

## End-to-End Tests (RSpec + Playwright Ruby)

This example app includes browser E2E tests powered by `playwright-ruby-client` and RSpec.

Run locally:

```bash
bin/e2e
```

Useful options:

```bash
# Run headed browser mode
PLAYWRIGHT_HEADLESS=0 bin/e2e

# Run one file
bin/e2e spec/e2e/smoke_spec.rb
```

Run inside Docker:

```bash
docker compose build
docker compose run --rm app bin/e2e
```

The Docker image installs Chromium and required Playwright OS dependencies at build time.
The E2E runner uses an isolated SQLite database at `tmp/e2e.sqlite3`.

### Plain Docker

From the repository root:

```bash
docker build -f examples/reactive_view_example/Dockerfile -t reactive-view-example .
docker run --rm -p 3000:3000 reactive-view-example
```

Then open http://localhost:3000.

## Demo Pages

The example includes several pages demonstrating ReactiveView features:

| Route        | Description                            |
| ------------ | -------------------------------------- |
| `/`          | Home page with interactive counter     |
| `/about`     | Static about page                      |
| `/counter`   | Advanced counter with SolidJS effects  |
| `/users`     | User list loaded from Rails via loader |
| `/users/:id` | Dynamic user page with loader          |

## Project Structure

```
app/
  pages/                    # ReactiveView pages (TSX components)
    index.tsx               # Home page
    about.tsx               # About page
    counter.tsx             # Counter demo
    users/
      index.tsx             # Users list
      index.loader.rb       # Loader for users list
      [id].tsx              # User detail (dynamic route)
      [id].loader.rb        # Loader for user detail
  models/
    user.rb                 # User model

config/
  initializers/
    reactive_view.rb        # ReactiveView configuration

.reactive_view/             # SolidStart working directory (auto-generated)
```

## Loaders

Loaders are Ruby classes that provide data to your pages. They run on the Rails side and are called by SolidStart during SSR.

Example loader (`app/pages/users/[id].loader.rb`):

```ruby
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
        {
          user: {
            id: user.id,
            name: user.name,
            email: user.email
          }
        }
      end

      private

      def user
        @user ||= User.find(params[:id])
      end
    end
  end
end
```

## Generating TypeScript Types

To generate TypeScript types from your loaders:

```bash
bin/rails reactive_view:types:generate
```

## Styling with Tailwind CSS v4

This example application uses Tailwind CSS v4 for styling. The configuration uses the Vite plugin approach (not PostCSS):

- **`reactive_view.config.ts`**: Includes `@tailwindcss/vite` plugin
- **`app/pages/_styles/tailwind.css`**: Base stylesheet using `@import "tailwindcss"` syntax
- **`@tailwindcss/forms`**: Plugin for better form styling

### Tailwind v4 Changes

Tailwind CSS v4 uses a new syntax:

```css
/* Old v3 syntax (NO LONGER WORKS) */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* New v4 syntax */
@import "tailwindcss";

@theme {
  --font-sans: system-ui, sans-serif;
}
```

### Adding Custom Styles

To add custom styles:

1. Edit `app/pages/_styles/tailwind.css` for global styles
2. Use Tailwind utility classes in your TSX components with `class` attribute (not `className`)
3. Import the stylesheet using: `import "../_styles/tailwind.css"`

### Important Notes

- Tailwind CSS is configured from `reactive_view.config.ts` at Rails root
- Use the `@tailwindcss/vite` plugin, not the PostCSS plugin
- Styles are imported from `app/pages/_styles/`

### Shared Layout Component

The `MainLayout` component (`app/pages/components/MainLayout.tsx`) provides:

- Consistent navigation with active state styling
- Tailwind CSS import
- Responsive design utilities
- Reusable layout structure

### SolidJS vs React Important Notes

**This app uses SolidJS, not React!** Key syntax differences:

- ✅ Use `class="..."` instead of `className="..."`
- ✅ Use `for="..."` instead of `htmlFor="..."`
- ✅ Use `e.target` instead of `e.currentTarget` for events
- ✅ Use `<Show when={condition}>` instead of `{condition && <JSX/>}`
- ✅ Use `<For each={array}>` instead of `{array.map(...)}`

### Correct SolidJS Example

```tsx
import { createSignal, Show, For } from "solid-js";

export default function MyPage() {
  const [items, setItems] = createSignal(["a", "b"]);
  const [visible, setVisible] = createSignal(true);

  return (
    <div class="container mx-auto">
      {" "}
      {/* class not className */}
      <button
        class="px-4 py-2 bg-blue-500 text-white rounded"
        onClick={() => setVisible(!visible())}
      >
        Toggle
      </button>
      <Show when={visible()}>
        {" "}
        {/* SolidJS conditional */}
        <For each={items()}>
          {" "}
          {/* SolidJS list rendering */}
          {(item) => <div>{item}</div>}
        </For>
      </Show>
    </div>
  );
}
```

## Useful Commands

```bash
# Show all ReactiveView routes
bin/rails reactive_view:routes

# Sync TSX files to SolidStart directory
bin/rails reactive_view:sync

# Generate TypeScript types
bin/rails reactive_view:types:generate

# Check daemon status
bin/rails reactive_view:daemon:status

# Run E2E browser tests
bin/e2e
```
