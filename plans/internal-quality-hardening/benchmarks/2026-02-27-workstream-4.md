# Workstream 4 Microbench Notes (2026-02-27)

This document captures lightweight reproducible checks for the two internal performance changes in this slice.

## Commands

Run from repository root:

```bash
(cd reactive_view && bundle exec ruby script/benchmark_dev_proxy.rb)
npm run bench:stream --prefix reactive_view/npm
```

Optional tuning:

- `ITERATIONS` and `WARMUP` for the Ruby benchmark (defaults: `20000`, `1000`)
- `RUNS` for the Node benchmark (default: `5`)

## Expected Output Shape

`benchmark_dev_proxy.rb` should print:

- request throughput and mean latency for proxy middleware call path
- `unique_connection_objects=1` to confirm connection reuse

`bench:stream` should print, for each chunk size (`1000`, `5000`, `10000`):

- old vs new message derivation timings
- old vs new SSE draining timings
- computed speedup ratios

## Sample Notes

- Dev proxy sample run:
  - `iterations=20000 warmup=1000`
  - `elapsed=0.0975s req/s=205115.58 mean=0.0049ms`
  - `unique_connection_objects=1`
- Stream sample run (`RUNS=5`):
  - `chunks=1000` message speedup `~60.37x`, SSE draining speedup `~1.25x`
  - `chunks=5000` message speedup `~692.08x`, SSE draining speedup `~1.54x`
  - `chunks=10000` message speedup `~1592.47x`, SSE draining speedup `~1.57x`
