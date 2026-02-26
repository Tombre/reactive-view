# ReactiveView Skills Evals

Use these scenarios to validate that project-scoped skills are discoverable and actionable.

## Scenario 1: Setup drift recovery

- Skills: `setup`
- Query: "I switched from gem work to the example app and now `bin/dev` fails. Fix setup drift."
- Expected behavior:
  - Re-runs context-appropriate dependency installation.
  - Runs `bin/rails reactive_view:setup` in the example app when generated artifacts are stale.
  - Verifies with a startup command.

## Scenario 2: Loader shape change sync

- Skills: `automation-hooks`
- Query: "I changed a loader `shape`; make sure routes and types are correct and HMR still works."
- Expected behavior:
  - Runs `reactive_view:sync` then `reactive_view:types:generate`.
  - Inspects routes with `reactive_view:routes`.
  - Validates by starting dev flow and checking behavior.

## Scenario 3: SolidJS regression prevention

- Skills: `solidjs`, `testing`
- Query: "Review this TSX diff and fix framework issues."
- Expected behavior:
  - Replaces React aliases (`className`, `htmlFor`, `tabIndex`) with Solid/HTML attributes.
  - Replaces React-style conditional/list shortcuts with Solid control-flow components.
  - Runs template build or equivalent validation loop.

## Scenario 4: Pre-PR readiness

- Skills: `pr-checklist`
- Query: "Prepare this branch for PR and provide the final checklist status."
- Expected behavior:
  - Verifies tests/build scope based on touched files.
  - Confirms docs updates for API/workflow changes.
  - Confirms generated and sensitive files are untracked.
  - Produces PR-ready verification notes with exact commands.
