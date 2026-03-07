# External Daemon Architecture

ReactiveView development now runs as two coordinated processes:

1. Rails web process
2. ReactiveView daemon orchestrator (`bundle exec reactiveview dev`)

## Why this changed

The previous model embedded daemon startup/supervision into Rails engine
initialization. That coupling increased startup latency and made failures less
obvious. The new model moves process management into an explicit CLI command.

## Process model

### Rails process

- Boots and serves requests normally.
- Does not start, stop, or monitor the daemon.

### Orchestrator process

- Boots Rails environment to read app configuration.
- Verifies single-instance lock.
- Ensures daemon port is free.
- Runs a quiet safe cleanup preflight equivalent to `reactiveview doctor --fix`.
- Loads loaders and runs `ReactiveView::FileSync.sync_all`.
- Starts file watcher (`ReactiveView::FileSync.start_watching`).
- Spawns `npx reactiveview dev --port <configured-port>` as child process.
- Forwards shutdown via signal handling and tears down child/watcher together.

## Lifecycle guarantees

- One orchestrator per app instance (file lock + pid metadata).
- One daemon per orchestrator.
- Killing the orchestrator stops the daemon process group.
- Startup fails fast if daemon is already running or port is occupied.

## Development usage

Manual two-terminal flow:

```bash
# terminal 1
bin/dev

# terminal 2
bundle exec reactiveview dev
```

Optional process manager flow:

```bash
foreman start -f Procfile.dev
```
