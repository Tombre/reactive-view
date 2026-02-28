# Decision Log

Use this log to track planning and implementation decisions that should inform future work.

## How to read this file

- `Status: Active` means the decision is currently in effect.
- `Status: Deprecated` means the decision was replaced by a newer decision.
- `Deprecated By` points to the replacement decision ID.
- `Supersedes` lists decision IDs replaced by the current decision.

## DEC-20260228-01 - Establish decision log workflow

- Status: Active
- Date: 2026-02-28
- Deprecated By: N/A
- Supersedes: None

### Context
Planning and implementation choices were not being recorded in one durable place, which made later decisions slower and less consistent.

### Decision
Adopt a repository-level decision log at `plans/decision-log/DECISIONS.md` and capture non-trivial planning and implementation choices with stable IDs.

### Consequences
Future planning can reference prior rationale quickly; when choices change, old decisions stay visible and are marked deprecated instead of deleted.

## DEC-20260228-02 - Root-owned Node runtime, generated `.reactive_view`, keep SolidStart

- Status: Active
- Date: 2026-02-28
- Deprecated By: N/A
- Supersedes: None

### Context
ReactiveView previously generated a self-contained `.reactive_view` Node project with its own `package.json`, `node_modules`, and `tsconfig.json`. That duplicated runtime ownership and made development ergonomics diverge from common metaframework expectations (single project root JS runtime). We needed to remove duplication while preserving existing gem APIs and behavior.

### Decision
Adopt a root-owned Node runtime model:

- Keep `package.json`, `node_modules`, and TypeScript config at the Rails root.
- Keep `.reactive_view` as generated framework artifacts (`app.config.ts`, generated routes, generated types, build output), not a second package-managed project.
- Run Vinxi from Rails root via `reactiveview` CLI using `.reactive_view/app.config.ts`.
- Keep route wrappers in `.reactive_view/src/routes`, but import directly from `app/pages` via `~pages` for both dev and production builds.
- Keep SolidStart for now instead of replacing it with a custom router/runtime stack.

### Why SolidStart is retained for now
SolidStart currently provides stable, working primitives that ReactiveView depends on (file-routed SSR, hydration wiring, streaming-compatible server runtime, and integration with Vinxi/Nitro). Replacing it now would require rebuilding and revalidating core framework responsibilities (SSR orchestration, route compilation/runtime behavior, preload integration, and production server output semantics) with substantial migration and regression risk. We can revisit replacement once the root-owned runtime architecture is fully stable and measured under real app workloads.

### Consequences
- Developer experience aligns with single-root metaframework workflows.
- Production still emits a self-contained generated runtime under `.reactive_view/.output`.
- Existing Ruby-side gem API remains largely unchanged (same loaders, mutations, routes, and daemon interfaces).
- There is now one canonical dependency graph for frontend runtime dependencies.
