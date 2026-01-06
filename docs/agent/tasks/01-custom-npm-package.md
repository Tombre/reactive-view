# Custom `@reactive-view/core` npm Package

**Status:** Implemented (Local Development)  
**Priority:** High  
**Category:** Developer Experience

## Context

ReactiveView now includes an npm package (`@reactive-view/core`) that provides TypeScript types and the `useLoaderData` hook for editor/IDE support. This enables proper IntelliSense, type checking, and autocomplete when editing TSX files in `app/pages/`.

## Current Implementation

The `@reactive-view/core` package is located at `reactive_view/npm/` and provides:

- `useLoaderData<T>()` hook for loading data from Rails loaders
- `LoaderDataMap` interface (augmented by generated types)
- `LoaderData<T>` helper type

**Import Path:**
```tsx
import { useLoaderData } from "@reactive-view/core";
```

**Type Generation:**
Running `rails reactive_view:types:generate` creates `.reactive_view/types/loader-data.d.ts` which augments the `@reactive-view/core` module with project-specific loader types.

## Completed Tasks

- [x] Create npm package structure (`reactive_view/npm/`)
- [x] Set up TypeScript configuration for the package
- [x] Export ReactiveView utilities (`useLoaderData`)
- [x] TypeScript types are properly exported
- [x] Update the gem's template to use the new package
- [x] Update example application imports to `@reactive-view/core`
- [x] Install generator creates `package.json` and `tsconfig.json` at project root
- [x] Type generation outputs to `.reactive_view/types/loader-data.d.ts` with module augmentation

## Remaining Tasks (Future)

### Publishing to npm Registry

- [ ] Set up npm account and obtain publish rights for `@reactive-view` scope
- [ ] Create CI/CD workflow for automated publishing (GitHub Actions)
- [ ] Add version synchronization between gem and npm package
- [ ] Create unscoped alias package `reactive-view` that re-exports from `@reactive-view/core`
- [ ] Update documentation with npm install instructions (not file: links)

### Enhanced Exports

- [ ] Re-export SolidJS primitives from `@reactive-view/core/solid`
- [ ] Re-export SolidJS Router primitives from `@reactive-view/core/router`
- [ ] Add `RequestTokenProvider` and other context utilities
- [ ] Optimize bundle size (ensure no duplicate SolidJS in final build)

### Testing

- [ ] Add tests for the npm package
- [ ] Add integration tests for type generation

## Technical Notes

- The package uses peer dependencies for `solid-js` and `@solidjs/router`
- Currently uses `file:` links for local development
- Type generation uses TypeScript module augmentation to extend `LoaderDataMap`
- The approach is similar to how Prisma generates types

## Related Files

- `reactive_view/npm/` - The npm package source
- `reactive_view/lib/reactive_view/types/typescript_generator.rb` - Type generation
- `reactive_view/lib/generators/reactive_view/install_generator.rb` - Install generator
- `reactive_view/template/package.json` - Template package.json
