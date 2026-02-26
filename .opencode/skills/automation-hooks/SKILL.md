---
name: automation-hooks
description: Runs ReactiveView sync, type generation, route inspection, and daemon management commands. Use after loader/route changes or when HMR and generated output diverge.
compatibility: opencode
metadata:
  scope: project
  workflow: automation
---

## What it does

Provides the exact command sequence for keeping routes, generated TS types, and daemon state in sync.

## When to use

- After editing `app/pages/*.tsx` or `*.loader.rb` files.
- After changing loader `shape` definitions.
- When HMR behaves unexpectedly.

## Default workflow

1. Sync page files and wrappers:

```bash
bin/rails reactive_view:sync
```

2. Regenerate loader types:

```bash
bin/rails reactive_view:types:generate
```

3. Inspect generated routing:

```bash
bin/rails reactive_view:routes
```

4. If daemon is managed manually:

```bash
bin/rails reactive_view:daemon:status
```

## Validation loop

1. Run `sync` then `types:generate`.
2. Verify expected route output.
3. Boot `bin/dev` and confirm edited page hot-reloads.
4. If mismatch remains, rerun `sync` and re-check routes/types.

## Guardrails

- Do not edit generated route wrappers directly.
- Treat `.reactive_view` as generated output.
- In `reactive_view/`, use `bundle exec rails` and `bundle exec rake` for gem-scoped commands.
