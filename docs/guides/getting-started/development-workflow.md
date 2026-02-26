# Development Workflow

This is the standard local loop for ReactiveView projects.

## Start services

```bash
bin/dev
```

or separately:

```bash
bin/rails server
cd .reactive_view && npm run dev -- --port 3001
```

## Edit pages and loaders

- Edit TSX in `app/pages/**`
- Edit loader Ruby in `app/pages/**/*.loader.rb`

In development:

- route wrappers are generated in `.reactive_view/src/routes`
- Vite reads source pages via `~pages` alias from `app/pages`
- loader changes trigger type regeneration + HMR invalidation

## Useful commands

```bash
bin/rails reactive_view:routes
bin/rails reactive_view:sync
bin/rails reactive_view:types:generate
bin/rails reactive_view:daemon:status
```

## When to run sync manually

`reactive_view:sync` is usually automatic in development, but run it if:

- route wrappers look stale
- you changed a lot of route files quickly
- you changed setup/config and want a clean refresh

## Build check

Before release:

```bash
bin/rails reactive_view:build
```

For production builds, page files are copied into `.reactive_view/src/pages` for a self-contained build artifact.
