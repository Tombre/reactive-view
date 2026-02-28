# Internal Quality Hardening Benchmark Playbook

This playbook is the concrete execution guide for the benchmark requirements in `plans/internal-quality-hardening/PLAN.md`.

## 1) Baseline capture commands

Run benchmark commands from `examples/reactive_view_example/` (Rails app context).

### 1.1 Capture baseline suite (production)

```bash
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
bin/rails reactive_view:benchmark:production
cp ../../BENCHMARKS.md "../../plans/internal-quality-hardening/bench-baseline-production-${STAMP}.md"
```

### 1.2 Capture targeted route baselines (microbench via existing route task)

Use route benchmarks for the path you touched. Common routes in this repo:

- `/about` (static SSR)
- `/users` (loader + query)
- `/users/1` (dynamic loader)
- `/ai/chat` (streaming/chat page)

```bash
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
bin/rails "reactive_view:benchmark:route[/users,200]"
cp ../../BENCHMARKS.md "../../plans/internal-quality-hardening/bench-baseline-users-${STAMP}.md"

bin/rails "reactive_view:benchmark:route[/ai/chat,200]"
cp ../../BENCHMARKS.md "../../plans/internal-quality-hardening/bench-baseline-ai-chat-${STAMP}.md"
```

### 1.3 Capture type generation runtime (if type generator was touched)

Run this from `examples/reactive_view_example/`:

```bash
/usr/bin/time -l bin/rails reactive_view:types:generate
```

Record elapsed time and memory/allocation signals from `time` output in the run template.

### 1.4 Capture environment metadata for reproducibility

```bash
ruby -v
node -v
uname -a
```

And from `examples/reactive_view_example/`:

```bash
bin/rails -v
bin/rails -T reactive_view:benchmark
```

## 2) Before/after comparison table (required)

Use this table in each perf PR. Lower is better for `mean`, `p95`, `p99`; higher is better for `req/s`.

| Scenario | Command | Mean Before (ms) | Mean After (ms) | Mean Delta % | P95 Before (ms) | P95 After (ms) | P95 Delta % | P99 Before (ms) | P99 After (ms) | P99 Delta % | Req/s Before | Req/s After | Req/s Delta % |
|----------|---------|------------------|-----------------|--------------|-----------------|----------------|-------------|-----------------|----------------|-------------|--------------|-------------|---------------|
| example: `/users` | `bin/rails "reactive_view:benchmark:route[/users,200]"` | 14.2 | 12.8 | -9.9% | 14.8 | 13.7 | -7.4% | 15.0 | 14.1 | -6.0% | 70.4 | 76.9 | +9.2% |

## 3) Reproducibility controls

Use these controls for both baseline and after runs:

1. Fixed benchmark settings:
   - `reactive_view:benchmark:production` uses fixed `iterations: 100`, `warmup: 10`, `concurrency: [1, 5, 10]`.
   - Route microbench command should use a fixed iteration count (recommend `200` for targeted checks).
2. Same machine and runtime:
   - Run baseline and after on the same host.
   - Do not change Ruby, Node, or Rails versions between runs.
3. Stable local load:
   - Close unrelated heavy workloads during runs.
   - Avoid running additional test/build jobs in parallel.
4. Multiple samples for noisy paths:
   - Run each targeted route benchmark at least 2 times and keep both artifacts.
   - Use the median delta when runs disagree materially.

## 4) Acceptance thresholds (from plan)

A performance PR in this plan is acceptable only when all checks pass:

1. No touched path regresses by more than 5% at p95.
2. At least one targeted hotspot improves by 10% or more in mean latency or throughput (`req/s`).
3. Memory/allocation behavior does not worsen materially in the related microbench scenario.

## 5) Reporting checklist for each perf PR

1. Link baseline artifact(s) under `plans/internal-quality-hardening/`.
2. Link after artifact(s) under `plans/internal-quality-hardening/`.
3. Include the before/after table with mean/p95/p99/req/s.
4. Include command list and environment summary.
5. State pass/fail against all acceptance thresholds.

Use `plans/internal-quality-hardening/benchmark-run-template.md` for a ready-to-fill report skeleton.
