# Daemon Management

ReactiveView uses a SolidStart daemon for SSR.

## Rake tasks

```bash
bin/rails reactive_view:daemon:start
bin/rails reactive_view:daemon:stop
bin/rails reactive_view:daemon:restart
bin/rails reactive_view:daemon:status
```

## Auto-start vs external daemon

- `auto_start_daemon = true`: Rails starts and monitors daemon
- `external_daemon = true`: you manage daemon lifecycle yourself

## Health and restart controls

Use config values:

- `daemon_max_restarts`
- `daemon_restart_window`
- `daemon_health_check_interval`
- `daemon_health_check_ttl`

## Logs and PID

Daemon files in `.reactive_view/`:

- `daemon.log`
- `daemon.pid`

See [Renderer and Daemon Reference](../../reference/ruby/renderer-and-daemon.md).
