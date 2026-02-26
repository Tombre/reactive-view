---
name: debugging
description: Troubleshoots ReactiveView runtime failures across Rails, SSR daemon, and loader data callbacks. Use when requests fail, logs diverge, or generated route/type output is out of sync.
compatibility: opencode
metadata:
  scope: project
  workflow: debugging
---

## What it does

Provides a repeatable triage flow for failures involving Rails, daemon rendering, and loader data endpoints.

## When to use

- Runtime errors in `bin/dev` workflows.
- Token/header or loader data endpoint issues.
- Stale behavior after route/type generation changes.

## Default workflow

1. Reproduce with the smallest failing path.
2. Capture logs from Rails and daemon.
3. Verify generated routes/types are current.
4. Probe loader data endpoint directly.
5. Apply fix and confirm with the same reproduction path.

## Core commands

```bash
tail -f examples/reactive_view_example/log/development.log
bin/rails reactive_view:routes
bin/rails reactive_view:types:generate
curl -v http://localhost:3000/reactive_view/loader_data
```

## Validation loop

1. Reproduce and capture logs.
2. Fix one suspected root cause.
3. Re-run the exact failing path.
4. Repeat until failure is resolved without introducing new errors.

## Guardrails

- Log errors once at boundaries.
- Validate params early with typed shapes.
- Do not leave ad-hoc debug code in committed changes.
- Document recurring failure signatures in `docs/agent/tasks/post-mvp.md` when useful.
