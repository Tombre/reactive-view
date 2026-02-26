---
name: solidjs
description: Enforces SolidJS TSX conventions for ReactiveView pages and components, including anti-React guardrails and loader-data usage rules. Use for TSX implementation and frontend code review.
compatibility: opencode
metadata:
  scope: project
  workflow: frontend
---

## What it does

Prevents React-pattern regressions and keeps TSX code aligned with SolidJS and ReactiveView loader conventions.

## When to use

- Writing or editing `app/pages/**/*.tsx`.
- Reviewing frontend diffs for framework mismatches.
- Touching loader-data hooks or route data access.

## Default workflow

1. Implement using Solid primitives and control-flow components.
2. Verify no React attribute aliases or render shortcuts are used.
3. Verify loader-data imports match route conventions.
4. Build and fix compile or type issues.

## Required guardrails

- Use `class`, `for`, `tabindex`.
- Use `e.target` for event handling.
- Use `<Show>`, `<For>`, `<Switch>/<Match>` instead of React-style `&&` and `.map()` JSX shortcuts.
- Use `createSignal`/`createResource` and avoid mutating signal getter outputs.

## Loader data conventions

Per-route import:

```ts
import { useLoaderData } from "#loaders/users/index";
```

Cross-route access:

```ts
useLoaderData("users/[id]", { id });
```

## Validation loop

1. Run a frontend build.
2. Fix type or runtime issues.
3. Re-run build until clean.
4. Re-scan changed TSX for React-pattern leakage.

## Pitfalls

- Copying React snippets without Solid adaptation.
- Using `className`, `htmlFor`, or `tabIndex`.
- Hiding async failures instead of rendering explicit fallback states.
