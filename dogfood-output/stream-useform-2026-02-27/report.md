# Dogfood Report: ReactiveView Example (AI Chat)

| Field | Value |
|-------|-------|
| **Date** | 2026-02-27 |
| **App URL** | http://127.0.0.1:3000/ai/chat |
| **Session** | stream-useform |
| **Scope** | Streaming UX regression check for new `useStream` + `useForm(stream)` integration |

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| **Total** | **0** |

## Issues

No issues found during this dogfood pass.

## Coverage Notes

- Verified initial page render and stream form wiring at desktop viewport.
- Submitted prompts via button click and Enter key; both produced streamed assistant responses and token metadata.
- Repeated submissions behaved correctly and did not produce console/page errors.
- Verified mobile viewport (`390x844`) with successful prompt submission and rendered stream response.
- Captured evidence screenshots:
  - `screenshots/initial.png`
  - `screenshots/before-submit.png`
  - `screenshots/after-stream.png`
  - `screenshots/second-stream.png`
  - `screenshots/mobile-view.png`
  - `screenshots/mobile-after-submit.png`
