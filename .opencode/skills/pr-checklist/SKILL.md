---
name: pr-checklist
description: Applies a consistent pre-PR checklist for tests, docs, generated files, and release-sensitive changes. Use before opening or finalizing ReactiveView pull requests.
compatibility: opencode
metadata:
  scope: project
  workflow: review
---

## What it does

Defines a low-variance PR readiness flow so reviews include reproducible evidence and required documentation updates.

## When to use

- Before creating a PR.
- Before requesting review.
- Before merge on release-sensitive work.

## Default workflow

1. Verify touched-area tests and build commands pass.
2. Confirm docs and API-facing notes are updated.
3. Confirm generated/sensitive files remain untracked.
4. Write PR body with root cause, change summary, and exact verification commands.

## Required checks

1. Tests pass or skips are justified.
2. New loaders/controllers include request or spec coverage.
3. TS changes compile in `reactive_view/template` or generated app context.
4. Public API changes are reflected in `README.md` or `docs/`.
5. Sensitive/generated paths remain untracked (`.env`, credentials, `.reactive_view`, `node_modules`).
6. Significant UI changes include screenshots or recordings.
7. Version bumps stay aligned across gemspec and template `package.json`.
8. Manual follow-up commands are listed.
9. Bugfix PRs include exact reproduction and verification steps.

## Validation loop

1. Run checks.
2. Fix gaps.
3. Re-run failed checks.
4. Finalize PR body only after all checks are complete.

## Pitfalls

- Omitting exact test/build commands from the PR description.
- Shipping API changes without docs updates.
- Accidentally including generated or sensitive files.
