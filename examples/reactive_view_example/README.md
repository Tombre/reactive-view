# ReactiveView Example Application

This is an example Rails application demonstrating the ReactiveView gem.

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

Start both Rails and the SolidStart daemon:

```bash
bin/dev
```

This will start:
- Rails server on http://localhost:3000
- SolidStart daemon on http://localhost:3001

## Demo Pages

The example includes several pages demonstrating ReactiveView features:

| Route | Description |
|-------|-------------|
| `/` | Home page with interactive counter |
| `/about` | Static about page |
| `/counter` | Advanced counter with SolidJS effects |
| `/users` | User list loaded from Rails via loader |
| `/users/:id` | Dynamic user page with loader |

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
      loader_sig do
        param :user, ReactiveView::Types::Hash.schema(
          id: ReactiveView::Types::Integer,
          name: ReactiveView::Types::String,
          email: ReactiveView::Types::String
        )
      end

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
```
