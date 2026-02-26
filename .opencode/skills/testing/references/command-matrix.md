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

- **Primary:** `npm run build`
- **Workdir:** `reactive_view/template`
- **Use when:** editing TSX/runtime/build config in template.

Note: no JS test runner is configured in this repo yet, so build is the current validation gate.

## 3) NPM core package (`reactive_view/npm/`)

- **Primary:** `npm run build`
- **Workdir:** `reactive_view/npm`
- **Use when:** editing `reactive_view/npm/src/**`, CLI, or package exports.

## 4) Example app (`examples/reactive_view_example/`)

- **Primary sync/type checks:**
  - `bin/rails reactive_view:sync`
  - `bin/rails reactive_view:types:generate`
  - `bin/rails reactive_view:routes`
- **Build check:** `npm run build`
- **Workdir:** `examples/reactive_view_example`
- **Use when:** editing `app/pages/**`, `.loader.rb` files, example config, or ReactiveView integration wiring.

## 5) Cross-area changes

Run one command per affected area, usually in this order:

1. `bundle exec rspec <target>` in `reactive_view`
2. `npm run build` in `reactive_view/npm` (if touched)
3. `npm run build` in `reactive_view/template` (if touched)
4. Example checks in `examples/reactive_view_example` (if touched)

Escalate to full `bundle exec rspec` when changes impact shared internals.

## 6) Docs-only changes

- No test command required.
- State explicitly: "Docs-only change; code validation not required."

## Failure Loop

1. Run selected command.
2. Fix the first meaningful failure.
3. Re-run the same command.
4. Repeat until pass or blocked.
5. Only then broaden scope.
