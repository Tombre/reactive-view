# Installation

This guide installs ReactiveView into a Rails app and starts the development stack.

## Prerequisites

- Ruby 3.1+
- Rails 7+
- Node.js 18+
- npm

## 1) Add the gem

```ruby
# Gemfile
gem "reactive_view", path: "../reactive_view"
```

Then install:

```bash
bundle install
```

## 2) Run the install generator

```bash
bin/rails generate reactive_view:install
```

The generator sets up:

- `app/pages/`
- `config/initializers/reactive_view.rb`
- `reactive_view.config.ts`
- `.reactive_view/` SolidStart workspace
- `tsconfig.json`
- `bin/dev` and `Procfile.dev`

## 3) Install frontend dependencies in `.reactive_view`

```bash
cd .reactive_view && npm install
```

## 4) Start development

```bash
bin/dev
```

Default ports:

- Rails: `http://localhost:3000`
- SolidStart daemon: `http://localhost:3001`

## 5) Verify routing and type generation

```bash
bin/rails reactive_view:routes
bin/rails reactive_view:types:generate
```

Next: [Your First Page](first-page.md)
