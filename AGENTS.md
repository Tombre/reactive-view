# AGENTS.md - Agent Guidelines for ReactiveView

ReactiveView is a Ruby on Rails view framework gem for building modern reactive frontends without splitting into separate frontend/backend services. It replaces the Rails view layer with TSX components (TypeScript + SolidJS) while keeping data, auth, and business logic in Rails.

## What the Gem Does

- SSR + hydration: pages are server-rendered and hydrate into interactive SolidJS apps.
- Type safety: TypeScript types are generated from Ruby `shape` definitions.
- File-based routing: routes come from `app/pages/` (SolidStart style).
- Loader and mutation pattern: data loading and mutations are defined in Ruby loaders with typed params/results.
- Rails-first architecture: Rails owns auth/models/business rules; SolidJS owns UI rendering and interactivity.

## High-Level Architecture

ReactiveView coordinates a Rails Engine with a SolidStart daemon:

- Rails receives the request, runs loader/auth logic, and coordinates rendering.
- SolidStart daemon performs SSR for TSX pages.
- Daemon callbacks hit loader-data endpoints in Rails for typed data payloads.
- Final response is SSR HTML plus hydration scripts.

Read `README.md` when you need deeper context on architecture and motivation.

## Project Structure

- `reactive_view/` - Ruby gem (Rails Engine, routing, loaders)
- `reactive_view/template/` - SolidStart frontend template
- `examples/reactive_view_example/` - Demo Rails app
- `docs/` - design notes and roadmap tasks

Use relative paths in discussions so other agents can jump directly to files.

## External File Loading

CRITICAL: When you encounter a file reference (for example `@docs/general.md`), load it on demand.

- Do not preemptively load all references.
- When loaded, referenced docs are mandatory instructions that override defaults.
- Follow references recursively when needed.

## Non-Negotiables

- Stay surgical: edit only files needed for the task.
- Prefer edits over rewrites; keep history meaningful.
- Run targeted tests for touched areas before handing back work.
- Keep generated artifacts (`.reactive_view`, `coverage`, `tmp`, `node_modules`) untracked.
- Keep AGENTS and docs synchronized with reality when workflows change.

## Core Coding Rules

### Ruby

- Two spaces, no tabs.
- Prefer guard clauses and small methods.
- Class/module names in `CamelCase`; methods/vars in `snake_case`.
- Raise domain-specific errors and log once at boundaries.
- Use `Rails.logger` over `puts`.

### TypeScript / SolidStart

CRITICAL: ReactiveView uses SolidJS TSX, not React JSX.

- Use HTML attributes (`class`, `for`, `tabindex`) rather than React aliases.
- Use Solid control flow (`<Show>`, `<For>`, `<Switch>/<Match>`), not JSX shortcuts.
- Use Solid event and state conventions (`e.target`, `createSignal`, `createResource`).
- Keep loader imports and typed route data aligned with project conventions.

## Project-Scoped Skills

Load task-specific guidance from local skills under `.opencode/skills/`.

- `write-skill`: guide for creating/updating skills, including structure and best practices.
- `testing`: test strategy, command matrix, and RSpec conventions.
- `solidjs`: full SolidJS coding standards and anti-React guardrails.
- `docker-config-sync`: keeps example app runtime Docker and repo devcontainer configs updated in tandem.
- `pull-request`: create/update GitHub PRs with complete summaries and manual testing notes.
- `planning`: write and store planning documents under `plans/`.
