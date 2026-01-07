# ReactiveView Benchmark Results

Generated: 2026-01-07T10:07:12Z

## Environment

| Property | Value |
|----------|-------|
| Ruby Version | 3.4.3 |
| Rails Version | 8.0.4 |
| Node Version | v20.18.0 |
| ReactiveView Version | 0.1.0 |
| Platform | arm64-darwin24 |
| CPU | Apple M2 |

## Configuration

| Setting | Value |
|---------|-------|
| Iterations | 100 |
| Warm-up | 10 |
| Concurrency Levels | 1, 5, 10 |
| Daemon Port | 3001 |
| Rails Port | 3000 |
| Modes Tested | Development, Production |

---

## Summary (Production Mode)

### Sequential Requests

| Scenario | Mean | Median | P95 | P99 | Min | Max |
|----------|------|--------|-----|-----|-----|-----|
| Static page (no loader) | 3.4ms | 3.4ms | 3.7ms | 4.1ms | 2.8ms | 4.1ms |
| Interactive page with signals | 3.4ms | 3.4ms | 3.7ms | 4.0ms | 2.2ms | 4.2ms |
| List with loader + DB query | 14.3ms | 14.2ms | 14.7ms | 15.5ms | 13.8ms | 19.1ms |
| Dynamic route with loader | 13.8ms | 13.6ms | 14.5ms | 16.0ms | 13.2ms | 16.7ms |

### Concurrent Requests (Throughput)

| Scenario | 1 Thread | 5 Threads | 10 Threads |
|----------|---------|---------|---------|
| static | 291.06 req/s | 610.98 req/s | 568.08 req/s |
| interactive | 293.59 req/s | 616.41 req/s | 558.92 req/s |
| list | 70.39 req/s | 38.49 req/s | 37.03 req/s |
| dynamic | 73.53 req/s | 38.96 req/s | 38.28 req/s |

---

## Mode Comparison

### Development vs Production (Mean Response Time)

| Scenario | Development | Production | Improvement |
|----------|-------------|------------|-------------|
| Static page (no loader) | 3.7ms | 3.4ms | 1.1x faster |
| Interactive page with signals | 4.8ms | 3.4ms | 1.4x faster |
| List with loader + DB query | 15.3ms | 14.3ms | 1.1x faster |
| Dynamic route with loader | 13.9ms | 13.8ms | 1.0x faster |

---

## Detailed Results

### Static page (no loader) - Development

Static page (no loader)

```
Iterations: 100
Mean:       3.7ms
Median:     3.5ms
Std Dev:    0.9ms
P95:        4.3ms
P99:        6.2ms
Min:        2.2ms
Max:        11.3ms

Response Time Distribution:
      <5ms | ██████████████████████████████████████████████████ 97%
    5-10ms | █                                                  2%
   10-15ms | █                                                  1%
   15-20ms |                                                    0%
   20-25ms |                                                    0%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```

### Interactive page with signals - Development

Interactive page with signals

```
Iterations: 100
Mean:       4.8ms
Median:     3.5ms
Std Dev:    11.1ms
P95:        4.3ms
P99:        17.7ms
Min:        2.2ms
Max:        113.5ms

Response Time Distribution:
      <5ms | ██████████████████████████████████████████████████ 96%
    5-10ms | █                                                  2%
   10-15ms |                                                    0%
   15-20ms | █                                                  1%
   20-25ms |                                                    0%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms | █                                                  1%
```

### List with loader + DB query - Development

List with loader + DB query

```
Iterations: 100
Mean:       15.3ms
Median:     14.3ms
Std Dev:    4.2ms
P95:        17.1ms
P99:        35.0ms
Min:        13.7ms
Max:        47.2ms

Response Time Distribution:
      <5ms |                                                    0%
    5-10ms |                                                    0%
   10-15ms | ██████████████████████████████████████████████████ 81%
   15-20ms | █████████                                          15%
   20-25ms | █                                                  1%
   25-50ms | ██                                                 3%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```

### Dynamic route with loader - Development

Dynamic route with loader

```
Iterations: 100
Mean:       13.9ms
Median:     13.5ms
Std Dev:    1.3ms
P95:        14.7ms
P99:        19.2ms
Min:        13.2ms
Max:        24.6ms

Response Time Distribution:
      <5ms |                                                    0%
    5-10ms |                                                    0%
   10-15ms | ██████████████████████████████████████████████████ 96%
   15-20ms | ██                                                 3%
   20-25ms | █                                                  1%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```

### Static page (no loader) - Production

Static page (no loader)

```
Iterations: 100
Mean:       3.4ms
Median:     3.4ms
Std Dev:    0.2ms
P95:        3.7ms
P99:        4.1ms
Min:        2.8ms
Max:        4.1ms

Response Time Distribution:
      <5ms | ██████████████████████████████████████████████████ 100%
    5-10ms |                                                    0%
   10-15ms |                                                    0%
   15-20ms |                                                    0%
   20-25ms |                                                    0%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```

### Interactive page with signals - Production

Interactive page with signals

```
Iterations: 100
Mean:       3.4ms
Median:     3.4ms
Std Dev:    0.3ms
P95:        3.7ms
P99:        4.0ms
Min:        2.2ms
Max:        4.2ms

Response Time Distribution:
      <5ms | ██████████████████████████████████████████████████ 100%
    5-10ms |                                                    0%
   10-15ms |                                                    0%
   15-20ms |                                                    0%
   20-25ms |                                                    0%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```

### List with loader + DB query - Production

List with loader + DB query

```
Iterations: 100
Mean:       14.3ms
Median:     14.2ms
Std Dev:    0.6ms
P95:        14.7ms
P99:        15.5ms
Min:        13.8ms
Max:        19.1ms

Response Time Distribution:
      <5ms |                                                    0%
    5-10ms |                                                    0%
   10-15ms | ██████████████████████████████████████████████████ 97%
   15-20ms | ██                                                 3%
   20-25ms |                                                    0%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```

### Dynamic route with loader - Production

Dynamic route with loader

```
Iterations: 100
Mean:       13.8ms
Median:     13.6ms
Std Dev:    0.5ms
P95:        14.5ms
P99:        16.0ms
Min:        13.2ms
Max:        16.7ms

Response Time Distribution:
      <5ms |                                                    0%
    5-10ms |                                                    0%
   10-15ms | ██████████████████████████████████████████████████ 97%
   15-20ms | ██                                                 3%
   20-25ms |                                                    0%
   25-50ms |                                                    0%
  50-100ms |                                                    0%
    >100ms |                                                    0%
```


---

## Concurrent Performance Details

### 1 Concurrent Thread - Development

| Scenario | Req/s | Mean | P95 | P99 |
|----------|-------|------|-----|-----|
| static | 284.55 | 3.5ms | 4.2ms | 7.3ms |
| interactive | 299.45 | 3.3ms | 3.6ms | 4.1ms |
| list | 70.91 | 14.1ms | 14.8ms | 15.3ms |
| dynamic | 73.77 | 13.6ms | 14.4ms | 15.1ms |

### 5 Concurrent Threads - Development

| Scenario | Req/s | Mean | P95 | P99 |
|----------|-------|------|-----|-----|
| static | 613.67 | 8.0ms | 9.7ms | 10.6ms |
| interactive | 573.14 | 8.6ms | 11.8ms | 18.8ms |
| list | 38.47 | 128.5ms | 156.5ms | 165.4ms |
| dynamic | 39.64 | 124.9ms | 151.4ms | 153.6ms |

### 10 Concurrent Threads - Development

| Scenario | Req/s | Mean | P95 | P99 |
|----------|-------|------|-----|-----|
| static | 619.77 | 15.4ms | 17.8ms | 18.7ms |
| interactive | 615.18 | 15.6ms | 17.6ms | 18.4ms |
| list | 38.39 | 252.1ms | 302.0ms | 306.0ms |
| dynamic | 38.89 | 249.0ms | 304.7ms | 310.9ms |

### 1 Concurrent Thread - Production

| Scenario | Req/s | Mean | P95 | P99 |
|----------|-------|------|-----|-----|
| static | 291.06 | 3.4ms | 4.0ms | 4.3ms |
| interactive | 293.59 | 3.4ms | 4.0ms | 4.0ms |
| list | 70.39 | 14.2ms | 14.8ms | 15.0ms |
| dynamic | 73.53 | 13.6ms | 14.2ms | 14.4ms |

### 5 Concurrent Threads - Production

| Scenario | Req/s | Mean | P95 | P99 |
|----------|-------|------|-----|-----|
| static | 610.98 | 8.0ms | 9.7ms | 10.0ms |
| interactive | 616.41 | 8.0ms | 9.6ms | 10.8ms |
| list | 38.49 | 128.5ms | 154.9ms | 155.2ms |
| dynamic | 38.96 | 126.9ms | 155.1ms | 161.3ms |

### 10 Concurrent Threads - Production

| Scenario | Req/s | Mean | P95 | P99 |
|----------|-------|------|-----|-----|
| static | 568.08 | 16.9ms | 25.1ms | 27.4ms |
| interactive | 558.92 | 17.1ms | 26.9ms | 28.5ms |
| list | 37.03 | 261.4ms | 324.7ms | 364.6ms |
| dynamic | 38.28 | 253.1ms | 310.4ms | 315.9ms |


---

## Notes

- All times are in milliseconds (ms)
- Benchmarks run on a single machine; network latency is minimal (~0.1ms)
- Production mode uses `npm run build` + `npm run start` (optimized Vinxi bundle)
- Development mode uses `npm run dev` (Vite dev server with HMR)
- Database queries are included in loader scenarios
- Results may vary based on hardware, system load, and database size
- Warm-up iterations allow JIT compilation and cache warming before measurement
