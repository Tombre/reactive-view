# Benchmark Run Template (Internal Quality Hardening)

## Run metadata

- Date (UTC):
- Author:
- Branch/commit:
- Change scope (files/paths touched):

## Environment

- Ruby:
- Rails:
- Node:
- Host/OS:

## Commands executed

Run from `examples/reactive_view_example/` unless noted otherwise.

```bash
# baseline
bin/rails reactive_view:benchmark:production
bin/rails "reactive_view:benchmark:route[/users,200]"

# after
bin/rails reactive_view:benchmark:production
bin/rails "reactive_view:benchmark:route[/users,200]"
```

If type generation performance is in scope, also run (from `examples/reactive_view_example/`):

```bash
/usr/bin/time -l bin/rails reactive_view:types:generate
```

## Before vs After

| Scenario | Command | Mean Before (ms) | Mean After (ms) | Mean Delta % | P95 Before (ms) | P95 After (ms) | P95 Delta % | P99 Before (ms) | P99 After (ms) | P99 Delta % | Req/s Before | Req/s After | Req/s Delta % |
|----------|---------|------------------|-----------------|--------------|-----------------|----------------|-------------|-----------------|----------------|-------------|--------------|-------------|---------------|
|          |         |                  |                 |              |                 |                |             |                 |                |             |              |             |               |

## Acceptance threshold check

- [ ] No touched path regressed by more than 5% at p95.
- [ ] At least one targeted hotspot improved by 10%+ in mean latency or req/s.
- [ ] Memory/allocation behavior did not worsen materially.

## Artifacts

- Baseline artifact(s):
- After artifact(s):
- Notes on run variance/noise:
