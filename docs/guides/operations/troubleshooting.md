# Troubleshooting

## Daemon unavailable / SSR failures

- verify daemon is running: `bin/rails reactive_view:daemon:status`
- inspect `.reactive_view/daemon.log`
- confirm host/port in initializer

## Loader type mismatch errors

- check shape definitions and returned data
- regenerate types: `bin/rails reactive_view:types:generate`
- ensure `response_shape` is assigned for `:load`

## Mutation 404 or method not found

- confirm mutation method exists on loader
- confirm `params_shape` assignment matches mutation name
- regenerate types and restart dev processes

## CSRF invalid authenticity token

- ensure `csrf_meta_tags` are present
- verify token is sent in `X-CSRF-Token` (generated helpers do this)

## HMR not updating loader data

- verify Rails file watcher is running in development
- check daemon and Vite are both up
- run `bin/rails reactive_view:sync` once to force refresh

## Route not appearing

- verify file is under `app/pages` and not private (`_` prefix)
- run `bin/rails reactive_view:routes`
- check for route-group expectations (`(group)` affects file organization, not URL)
