---
name: solidjs
description: Writes and reviews SolidJS TSX for ReactiveView pages with Rails loader integration. Use when creating or editing `app/pages/**/*.tsx`, wiring `#loaders/*` helpers, or fixing React-to-Solid regressions.
---

# ReactiveView SolidJS

Write SolidJS code that matches ReactiveView's routing, loader, and mutation conventions.

## When To Use

- Creating or updating TSX route files in `app/pages/`.
- Wiring loader data with generated `#loaders/*` modules.
- Implementing typed mutations and streaming UI with generated helpers.
- Reviewing TSX for framework mismatches (React patterns in Solid files).

## Workflow

1. Identify route context from file location (`app/pages/...`) and nearby loader (`*.loader.rb`) when present.
2. Import primitives from `@reactive-view/core`; import route-typed helpers from `#loaders/<route>`.
3. Use Solid control flow and signals (`<Show>`, `<For>`, `createSignal`, `createEffect`) instead of React patterns.
4. Keep TSX aligned with generated types (`useLoaderData`, `useForm`, `useStream`) instead of handwritten request code.
5. If shapes or loaders changed, run type regeneration command listed in references.

## Non-Negotiables

- Use HTML/Solid attributes: `class`, `for`, `tabindex`, `onInput`.
- Do not use React-only APIs or patterns (`className`, `htmlFor`, `tabIndex`, `useState`, `map`-based JSX loops as default control flow).
- Prefer generated route modules (`#loaders/...`) for typed page data and mutation forms.
- Keep Rails as source of truth for auth/business logic; TSX handles rendering and interaction.

## Quick Checks

- Are imports from `@reactive-view/core` and `#loaders/...` (not ad hoc frontend wrappers)?
- Are conditionals/lists using Solid control-flow components?
- Are mutation UIs using generated form/stream helpers?
- If Ruby `shape` changed, was type generation run?

## References

- Patterns and examples: `references/patterns.md`
