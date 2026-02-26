# Production Build and Deploy

This guide covers production build flow for ReactiveView.

## Build command

```bash
bin/rails reactive_view:build
```

What it does:

1. syncs/generated artifacts
2. runs frontend build in `.reactive_view`
3. outputs Vinxi bundle under `.reactive_view/.output`

## Production daemon mode

Recommended: set `external_daemon = true` and run frontend process separately.

Rails should point to the frontend daemon host/port via config.

## Minimal deployment checklist

- run `bundle install` and app migrations
- ensure `.reactive_view` deps are installed
- run `bin/rails reactive_view:build`
- start Rails and daemon processes
- verify SSR and loader endpoints

## Runtime concerns

- keep `rails_base_url` correct when Rails sits behind proxies
- preserve cookie/session forwarding between services
- include CSRF meta tags in rendered pages

See [Internal Endpoints](../../reference/ruby/internal-endpoints.md) and [Renderer/Daemon Reference](../../reference/ruby/renderer-and-daemon.md).
