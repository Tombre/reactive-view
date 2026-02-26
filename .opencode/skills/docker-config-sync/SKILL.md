---
name: docker-config-sync
description: Keeps runtime Docker and repo devcontainer configs in sync. Use when changing Dockerfiles, compose files, startup scripts, or devcontainer setup.
---

# Docker Config Sync

Update container configuration as a paired change: runtime container (`examples/reactive_view_example/`) and repo devcontainer (`.devcontainer/`).

## When To Use

- Editing `examples/reactive_view_example/Dockerfile`.
- Editing `examples/reactive_view_example/docker-compose.yml`.
- Editing container startup wiring (`examples/reactive_view_example/Procfile.dev`, `examples/reactive_view_example/bin/start`, `examples/reactive_view_example/bin/dev`).
- Editing `.devcontainer/Dockerfile`, `.devcontainer/devcontainer.json`, or `.devcontainer/post-create.sh`.
- Bumping Ruby/Node/system package versions used by containerized workflows.

## Tandem Update Rule

If one side changes, review and update the other side in the same task unless there is a clear reason not to.

Paired areas:

1. **Base runtime versions**
   - Ruby version (`.ruby-version`, runtime Dockerfile base image, devcontainer Dockerfile base image)
   - Node major version and installation method
2. **System dependencies**
   - Keep shared essentials aligned (`build-essential`, `libsqlite3-dev`, `pkg-config`, `git`, `node`, `npm`)
3. **Startup behavior**
   - Runtime starts app services (`bin/start` / `Procfile.dev`)
   - Devcontainer bootstraps development dependencies (`post-create.sh`)
4. **Ports and accessibility**
   - Rails bind/port assumptions (`0.0.0.0:3000`)
   - Forwarded devcontainer ports must match app expectations

## Workflow

1. Identify which config changed first (runtime or devcontainer).
2. Diff against the paired config and apply equivalent updates where relevant.
3. Update docs if behavior or commands changed.
4. Validate both sides (build/runtime + devcontainer image build).
5. Report both validation results explicitly.

## Validation Minimum

From repo root, run:

```bash
docker build -f examples/reactive_view_example/Dockerfile -t reactive-view-example .
docker build -f .devcontainer/Dockerfile -t reactive-view-devcontainer .
```

If runtime behavior changed, also run the smoke check sequence from `.opencode/skills/testing/references/command-matrix.md`.

## Non-Negotiables

- Do not land runtime Docker changes without evaluating devcontainer impact.
- Do not land devcontainer toolchain changes without evaluating runtime Docker impact.
- If a change is intentionally one-sided, state why in the handoff.
- Keep edits surgical; do not rewrite unrelated Docker/devcontainer files.
