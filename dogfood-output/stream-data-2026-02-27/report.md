# Dogfood Report: ReactiveView Example (AI Chat)

| Field | Value |
|-------|-------|
| **Date** | 2026-02-27 |
| **App URL** | http://127.0.0.1:3000/ai/chat |
| **Session** | stream-data-dogfood |
| **Scope** | Validate strict stream completion, `useStreamData`, failed-message state, and retry UX |

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| **Total** | **0** |

## Issues

No issues found.

## Coverage Notes

- Verified baseline stream success and token metadata render.
- Forced network failure (offline submit) and confirmed strict failure behavior:
  - assistant message marked failed
  - global error surfaced (`Failed to fetch`)
  - retry button shown
- Verified `Retry` successfully starts a new assistant message and completes stream.
- Captured evidence:
  - `screenshots/initial.png`
  - `screenshots/success-after-helper-fix.png`
  - `screenshots/offline-failure.png`
  - `screenshots/retry-success.png`
