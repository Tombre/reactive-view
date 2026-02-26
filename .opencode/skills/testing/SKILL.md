---
name: testing
description: Selects and runs ReactiveView test and build validation commands by change scope with fast feedback loops. Use when implementing code changes, debugging regressions, or preparing PR verification notes.
---

# ReactiveView Testing

Run the smallest useful validation first, then broaden only when needed.

## When To Use

- After changing Ruby gem code under `reactive_view/`.
- After changing SolidStart/template or npm package code.
- After changing example app pages/loaders/config that affect runtime behavior.
- Before handing work back to the user or opening a PR.

## Workflow

1. Classify changed files by area (gem, template, npm package, example app, docs-only).
2. Run targeted checks for each changed area.
3. If targeted checks fail, fix and re-run the same command first.
4. If changes are cross-cutting, run the broader safety check set.
5. Report exact commands and outcomes.

## Command Selection

Use `references/command-matrix.md` to choose commands.

Default order:

1. Fastest targeted command for touched area.
2. Broader command in same area (if risk is medium/high).
3. Cross-area sanity checks only when changes span multiple areas.

## Execution Rules

- Run commands from the correct working directory.
- Prefer deterministic commands (no long-running watch mode).
- Do not claim tests were run if a required dependency/setup step blocked execution.
- If a command cannot run locally, state the blocker and give the exact follow-up command.

## Docker Validation Rule

When changes include `Dockerfile`, `docker-compose.yml`, or container startup scripts for the example app, validation must include:

1. Successful Docker image build.
2. Container boot that serves the app.
3. Curl smoke check against `http://127.0.0.1:3000`.

Use the command set in `references/command-matrix.md` and always stop/remove the smoke-test container at the end.

## Output Template

Use this structure in status updates:

```md
Validation run

- Scope: <files or subsystem>
- Command: `<command>` (workdir: `<dir>`)
- Result: pass | fail | blocked
- Notes: <short failure/blocker detail>
```

## References

- Command matrix: `references/command-matrix.md`
