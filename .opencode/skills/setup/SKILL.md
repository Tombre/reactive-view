---
name: setup
description: Sets up ReactiveView development environments across gem, example app, and template. Use when bootstrapping, switching contexts, or recovering dependency and generated-artifact drift.
compatibility: opencode
metadata:
  scope: project
  workflow: setup
---

## What it does

Provides the default setup sequence for `reactive_view/`, `examples/reactive_view_example/`, and `reactive_view/template/`.

## When to use

- Fresh clone or first local run.
- Switching between gem and example app work.
- Recovering from lockfile or generated `.reactive_view` drift.

## Default workflow

1. Gem context (`reactive_view/`):

```bash
bundle install
bundle exec rake -T
```

2. Example app (`examples/reactive_view_example/`):

```bash
bundle install
bin/rails db:prepare
bin/rails reactive_view:setup
bin/dev
```

3. Template context (`reactive_view/template/`):

```bash
npm install
npm run dev -- --port 3001
```

## Validation loop

1. Run setup commands for the active context.
2. Verify startup (`bundle exec rake -T`, `bin/dev`, or `npm run dev -- --port 3001`).
3. If setup fails, fix dependencies or generated artifacts.
4. Re-run the same validation command.

## Guardrails

- Use `bundle exec` for gem-scoped Rails/Rake commands.
- Re-run installs after dependency changes in each context.
- Re-run `bin/rails reactive_view:setup` after gem changes that affect generated frontend files.
- Keep generated `.reactive_view` artifacts untracked.
