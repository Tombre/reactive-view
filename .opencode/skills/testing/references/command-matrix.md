# ReactiveView Command Matrix

Pick commands by touched paths. Use the smallest sufficient set.

## 1) Ruby gem (`reactive_view/`)

- **Primary:** `bundle exec rspec <target>`
- **Broad:** `bundle exec rspec`
- **Workdir:** `reactive_view`
- **Use when:** editing `lib/`, `app/`, `spec/`, gem tasks, routing, loaders, daemon, renderer, type generation internals.

Examples:

- `bundle exec rspec spec/reactive_view/router_spec.rb`
- `bundle exec rspec spec/reactive_view/types/`
- `bundle exec rspec`

## 2) SolidStart template (`reactive_view/template/`)

- **Primary:** `npx reactiveview build`
- **Workdir:** `examples/reactive_view_example`
- **Use when:** editing TSX/runtime/build config in template and validating generated app build wiring.

Note: no JS test runner is configured in this repo yet, so build is the current validation gate.

## 3) NPM core package (`reactive_view/npm/`)

- **Primary:** `npm run build`
- **Workdir:** `reactive_view/npm`
- **Use when:** editing `reactive_view/npm/src/**`, CLI, or package exports.

## 4) Example app (`examples/reactive_view_example/`)

- **Primary RSpec:** `bundle exec rspec`
- **Primary sync/type checks:**
  - `bin/rails reactive_view:sync`
  - `bin/rails reactive_view:types:generate`
  - `bin/rails reactive_view:routes`
- **Build check:** `npm run build`
- **E2E browser tests (RSpec + Playwright Ruby):**
  - `bin/e2e spec/e2e/smoke_spec.rb` (targeted)
  - `bin/e2e` (full local e2e scope; CI defaults to smoke)
- **Workdir:** `examples/reactive_view_example`
- **Use when:** editing `app/pages/**`, `.loader.rb` files, example config, or ReactiveView integration wiring.

### Example app Docker validation (single-container)

- **Primary:** build image + run container + curl smoke check
- **Workdir:** repo root
- **Use when:** editing `examples/reactive_view_example/Dockerfile`, `examples/reactive_view_example/docker-compose.yml`, `examples/reactive_view_example/Procfile.dev`, or container startup scripts.

Commands:

```bash
docker build -f examples/reactive_view_example/Dockerfile -t reactive-view-example .
docker run --rm -d --name reactive-view-example-smoke -p 3000:3000 reactive-view-example
curl --fail --retry 30 --retry-connrefused --retry-delay 1 http://127.0.0.1:3000
docker stop reactive-view-example-smoke
```

Safer single-command variant with cleanup trap:

```bash
docker build -f examples/reactive_view_example/Dockerfile -t reactive-view-example . && bash -lc 'set -euo pipefail; trap "docker rm -f reactive-view-example-smoke >/dev/null 2>&1 || true" EXIT; docker run --rm -d --name reactive-view-example-smoke -p 3000:3000 reactive-view-example; curl --fail --retry 30 --retry-connrefused --retry-delay 1 http://127.0.0.1:3000'
```

## 5) Cross-area changes

Run one command per affected area, usually in this order:

1. `bundle exec rspec <target>` in `reactive_view`
2. `npm run build` in `reactive_view/npm` (if touched)
3. `npx reactiveview build` in `examples/reactive_view_example` (if template/runtime touched)
4. Example checks in `examples/reactive_view_example` (if touched)

Escalate to full `bundle exec rspec` when changes impact shared internals.

## 6) Required Handoff Verification (default)

Unless the user explicitly opts out, run all of the following before final handoff:

1. `bundle exec rspec` in `reactive_view`
2. `bundle exec rspec` in `examples/reactive_view_example`
3. `bin/e2e` in `examples/reactive_view_example`

## 7) Docs-only changes

- No test command required.
- State explicitly: "Docs-only change; code validation not required."

## 8) Failure Loop

1. Run selected command.
2. Fix the first meaningful failure.
3. Re-run the same command.
4. Repeat until pass or blocked.
5. Only then broaden scope.
