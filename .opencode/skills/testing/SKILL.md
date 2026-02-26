---
name: testing
description: Selects and runs ReactiveView test commands by change scope with fast feedback loops and reproducible evidence. Use for validating gem, example app, and template changes.
compatibility: opencode
metadata:
  scope: project
  workflow: testing
---

## What it does

Maps code-change scope to the smallest reliable test commands, then scales to broader verification when needed.

## When to use

- Any code change before handoff.
- Test failures that need focused reproduction.
- PR prep requiring exact verification commands.

## Default workflow

1. Run targeted tests first.
2. Fix failures.
3. Re-run the same targeted tests.
4. Run broader coverage only after targeted checks pass.

## Command matrix

Gem/root:

```bash
bundle install
bundle exec rspec spec/reactive_view/request_context_spec.rb:42
bundle exec rspec spec/reactive_view/request_context_spec.rb
bundle exec rspec
bundle exec rubocop
```

Example app (`examples/reactive_view_example/`):

```bash
bundle install
bin/rails db:prepare
bin/rails test test/models/user_test.rb:12
bin/rails test
```

Template (`reactive_view/template/`):

```bash
npm install
npm run build
```

## Validation loop

1. Start with a path:line or single-file command.
2. If failing, fix code and re-run the same command.
3. When green, expand to suite-level command for that area.
4. Record exact commands used for reproducibility.

## Guardrails

- Keep tests deterministic; avoid flaky integration additions.
- Mirror source paths in `spec/` and use `described_class` where practical.
- For loader changes, test auth callbacks, params validation, and response shape behavior.
