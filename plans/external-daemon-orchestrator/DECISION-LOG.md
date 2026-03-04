# Decision Log - external-daemon-orchestrator

## DEC-20260304-01 - Rails no longer auto-manages the development daemon

- Status: Active
- Date: 2026-03-04
- Deprecated By: N/A
- Supersedes: None

### Context

The previous architecture started and supervised the SolidStart daemon from
inside Rails engine initialization. That increased Rails startup time and made
daemon lifecycle failures harder to reason about.

### Decision

Adopt an explicit split-process model for development:

- Rails starts independently as the web process.
- `bundle exec reactiveview dev` starts a Ruby orchestrator process.
- The orchestrator performs preflight checks, syncs generated artifacts,
  starts the file watcher, and supervises the Node daemon as a child process.
- The orchestrator enforces single-instance behavior and fails fast when the
  daemon port is already occupied.

### Consequences

- Rails boot is faster and less coupled to daemon process management.
- Startup responsibilities are clearer for developers and tooling.
- Development now requires two processes (or a Procfile process manager).
- Daemon ownership moves from Rails engine internals to a dedicated CLI path.
