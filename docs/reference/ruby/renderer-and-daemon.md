# Ruby: Renderer and Daemon

## Renderer (`ReactiveView::Renderer`)

Purpose: POST render requests to SolidStart daemon.

Key methods:

- `render(path:, loader_path:, rails_base_url:, cookies: nil, csrf_token: nil)`
- `healthy?`

Errors:

- raises `ReactiveView::DaemonUnavailableError` on transport failures
- raises `ReactiveView::RenderError` on non-success render responses

## Daemon (`ReactiveView::Daemon`)

Singleton process manager (`ReactiveView::Daemon.instance`).

Key methods:

- `start`
- `stop`
- `restart`
- `running?`
- `health_check`
- `within_restart_budget?`
- `pid_file_path`

Features:

- startup polling with exponential backoff
- health monitor thread with bounded restart policy
- PID file and stale process cleanup
- graceful stop (`TERM` then `KILL` fallback)

Health endpoint checked: `GET /api/render` on daemon.
