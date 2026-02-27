# Dogfood Report: ReactiveView Example (AI Chat)

| Field | Value |
|-------|-------|
| **Date** | 2026-02-27 |
| **App URL** | http://127.0.0.1:3000/ai/chat |
| **Session** | stream-shape-final |
| **Scope** | Verify stream-shape DX (`response_shape ... mode: :stream`), strict completion, and retry UX |

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

- Verified standard stream flow on `/ai/chat`: submit prompt, observe streaming assistant output, and final completion.
- Verified strict error handling by forcing network offline before submit:
  - assistant bubble transitions to failed state
  - error banner appears with `Failed to fetch`
  - retry button is rendered
- Verified retry flow restores successful streaming once network reconnects.
- Captured evidence:
  - `screenshots/initial.png`
  - `screenshots/success.png`
  - `screenshots/offline-failure.png`
  - `screenshots/retry-success.png`
