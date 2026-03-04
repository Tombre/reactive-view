# External Daemon Orchestrator Plan

**Status:** Implemented
**Priority:** High
**Scope:** Replace Rails-managed daemon lifecycle with explicit Ruby CLI orchestration

## Overview

ReactiveView now uses a split-process development architecture:

- Rails runs as a normal web process.
- The SolidStart daemon is started explicitly with `bundle exec reactiveview dev`.
- A Ruby orchestrator process performs preflight checks, syncs generated files, starts file watching, and supervises the Node daemon lifecycle.

## Goals

1. Remove daemon startup and supervision work from Rails boot.
2. Make development startup failures explicit and deterministic.
3. Enforce single-instance daemon orchestration to avoid silent port contention.
4. Keep generated wrappers/types synchronized before daemon startup.

## Implementation Summary

1. Added gem executable and CLI entrypoint:
   - `reactive_view/exe/reactiveview`
   - `reactive_view/lib/reactive_view/cli.rb`
   - `reactive_view/lib/reactive_view/cli/dev_command.rb`
2. Added orchestrator runtime:
   - `reactive_view/lib/reactive_view/dev_orchestrator.rb`
3. Removed Rails-managed daemon lifecycle:
   - deleted `reactive_view/lib/reactive_view/daemon.rb`
   - removed engine initializers for auto-start and signal trapping
   - removed rake daemon tasks
4. Updated app scripts/docs to two-process development model.

## Validation

Validation is executed via:

- Gem specs (`reactive_view`)
- Example app specs (`examples/reactive_view_example`)
- Example Playwright e2e (`examples/reactive_view_example/bin/e2e`)
- Manual dogfooding of the example app with Rails + orchestrator running together
