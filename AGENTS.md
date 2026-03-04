# AGENTS.md - Agent Guidelines for ReactiveView

ReactiveView is a Ruby on Rails view framework gem for building modern reactive frontends without splitting into separate frontend/backend services. It replaces the Rails view layer with TSX components (TypeScript + SolidJS) while keeping data, auth, and business logic in Rails.

## About the Gem

### What the Gem Does

- SSR + hydration: pages are server-rendered and hydrate into interactive SolidJS apps.
- Type safety: TypeScript types are generated from Ruby `shape` definitions.
- File-based routing: routes come from `app/pages/` (SolidStart style).
- Loader and mutation pattern: data loading and mutations are defined in Ruby loaders with typed params/results.
- Rails-first architecture: Rails owns auth/models/business rules; SolidJS owns UI rendering and interactivity.
- Rails serves the request, talking to daemon (frontend server) that then returns the html for the page.

### High-Level Architecture

ReactiveView coordinates a Rails Engine with a SolidStart daemon:

- Rails receives the request, runs loader/auth logic, and coordinates rendering.
- SolidStart daemon performs SSR for TSX pages.
- Daemon callbacks hit loader-data endpoints in Rails for typed data payloads.
- Final response is SSR HTML plus hydration scripts.

Read `README.md` when you need deeper context on architecture and motivation.

### Project Structure

- `reactive_view/` - Ruby gem (Rails Engine, routing, loaders)
- `reactive_view/template/` - SolidStart frontend template
- `examples/reactive_view_example/` - Demo Rails app
- `docs/` - design notes and roadmap tasks

Use relative paths in discussions so other agents can jump directly to files.

## Agent Instructions

### Development Behaviour

- **Fact-based approach**: Do not hallucinate or assume. If you don't know something or need additional context about a framework or technology, search the web for up-to-date documentation. If clarification is needed, ask the user before making changes.
- **Constructive disagreement**: Do not just accept user direction if a better alternative exists. After reviewing the request, explain your reasoning for why an alternative approach might be better, providing technical justification and let the the developer decide.
- **Stop and ask**: Stop and ask user if:
  - Uncertain how to proceed
  - About to add type ignores, suppressions, or `any` types
  - Requirements are unclear
  - Better approach exists but needs confirmation

### Code Organization

- **Single responsibility**: Components and functions should have a single, clear purpose. Organize code into logical directories with clear separation of concerns.
- **Consistent patterns**: Follow established patterns in the codebase. When introducing new patterns, ensure they align with existing architecture and conventions.
- **Automation and efficiency**: Prefer automated solutions and efficient workflows. Look for opportunities to reduce manual work and improve developer experience.

### External File Loading

CRITICAL: When you encounter a file reference (for example `@docs/general.md`), load it on demand.

- Do not preemptively load all references.
- When loaded, referenced docs are mandatory instructions that override defaults.
- Follow references recursively when needed.

### Non-Negotiables

- Stay surgical: edit only files needed for the task.
- Prefer edits over rewrites (unless asked); keep history meaningful.
- Run targeted tests for touched areas before handing back work.
- Keep generated artifacts (`.reactive_view`, `coverage`, `tmp`, `node_modules`) untracked.
- Keep AGENTS and docs synchronized with reality when workflows change.

### Core Coding Rules

- **Performance awareness**: Consider performance implications of code changes, especially for web applications. Prefer static generation and minimal JavaScript when possible.
- **Accessibility**: Ensure code is accessible by default. Use semantic HTML, proper ARIA attributes, and test keyboard navigation.

#### Ruby

- Two spaces, no tabs.
- Prefer guard clauses and small methods.
- Class/module names in `CamelCase`; methods/vars in `snake_case`.
- Raise domain-specific errors and log once at boundaries.
- Use `Rails.logger` over `puts`.

#### TypeScript / SolidStart

CRITICAL: ReactiveView uses SolidJS TSX, not React JSX.

- Use HTML attributes (`class`, `for`, `tabindex`) rather than React aliases.
- Use Solid control flow (`<Show>`, `<For>`, `<Switch>/<Match>`), not JSX shortcuts.
- Use Solid event and state conventions (`e.target`, `createSignal`, `createResource`).
- Keep loader imports and typed route data aligned with project conventions.

#### Writing Tests/Specs

- Always add or modify tests (specs) when making code changes (unless superficial or asked not to)
- Tests should focus validate the actual behaviour and output of code, not the code itself
- Once you have written a test, run it to validate your working. Use the `testing` skill to do this

### Testing and validating your work (Dogfooding) behaviour

- **Confirm your code works:** ALWAYS test that your code works unless explicitly asked not to. use your `testing` skill for this.
- **Test the right things:** Don't run all specs, but ensure you run all relevant ones that interact with code changes
- **Dogfood your changes:** When building new features or fixing bugs - dogfood (manually test) your changes by starting the example application dev server and using your `dogfood` skill to interact with the relevant pages.

#### Running the Example Dev Server

Use the example server when testing changes to confirm they work.

- You should always start the example server using the `bin/dev` command via `docker`
- Refer to the `testing` skill for more information

### Other Behaviour

- If needing to interact with tmp files (writing all reading) do not access the root of the filesystem, write and read files from a project local ./tmp file

## Project-Scoped Skills

Load task-specific guidance from local skills under `.opencode/skills/`.

- `write-skill`: guide for creating/updating skills, including structure and best practices.
- `testing`: test strategy, command matrix, and RSpec conventions.
- `solidjs`: full SolidJS coding standards and anti-React guardrails.
- `docker-config-sync`: keeps example app runtime Docker and repo devcontainer configs updated in tandem.
- `pull-request`: create GitHub PRs with `gh` (or update existing branch PRs) using complete summaries and manual testing notes.
- `feature-plan`: writes feature plans and required architecture decision logs under `plans/`; trigger for big architecture changes, major plans, and new features.
