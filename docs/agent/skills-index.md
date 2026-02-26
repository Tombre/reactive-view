# ReactiveView Agent Skills Index

Use this index to pick the right project-scoped skill quickly.

## Task to skill lookup

| Task | Load this skill |
| --- | --- |
| Fresh setup, reinstalling dependencies, switching contexts | `setup` |
| Syncing routes/types, understanding HMR wrappers, daemon task usage | `automation-hooks` |
| Choosing test scope, command selection, RSpec conventions | `testing` |
| Investigating runtime failures, logs, daemon issues, loader endpoint checks | `debugging` |
| Writing/reviewing SolidJS TSX and preventing React-pattern regressions | `solidjs` |
| Pre-PR validation, docs updates, release-safe checklisting | `pr-checklist` |

## Suggested load patterns

- Setup + test work: `setup`, then `testing`.
- Frontend changes: `solidjs`, then `automation-hooks`, then `testing`.
- Bugfixes: `debugging`, then `testing`, then `pr-checklist`.

## Source of truth

- Keep always-on constraints in `AGENTS.md`.
- Keep long task-specific procedures in `.opencode/skills/*/SKILL.md`.
- If commands change, update both the affected skill and this index in the same PR.
- Validate skill behavior periodically with `docs/agent/skills-evals.md`.
