# Custom `reactiveview` npm Package

**Status:** Not Started  
**Priority:** High  
**Category:** Developer Experience

## Context

Currently, ReactiveView users must import SolidJS primitives directly from the `solid-js` package. This creates several challenges:

1. Version management becomes the user's responsibility
2. Potential version mismatches between what ReactiveView expects and what users install
3. More complex import statements scattered across the codebase
4. Users need to understand which SolidJS features are compatible with ReactiveView

The design document specifies that imports should come from a unified `reactiveview` namespace to provide a cohesive developer experience similar to other meta-frameworks.

## Overview

Create a dedicated npm package that bundles SolidJS and re-exports its primitives under the `reactiveview` namespace. This package will:

- Lock SolidJS to a specific tested version
- Provide all ReactiveView-specific utilities (`useLoaderData`, context providers, etc.)
- Re-export SolidJS primitives for convenience
- Simplify the import experience for developers

**Current State:**
```tsx
import { createSignal, createEffect } from "solid-js";
import { useLoaderData } from "~/lib/reactive-view";
```

**Target State:**
```tsx
import { createSignal, createEffect } from "reactiveview/solidjs";
import { useLoaderData } from "reactiveview";
```

## Acceptance Criteria

- [ ] A published npm package named `reactiveview` (or scoped `@reactiveview/core`)
- [ ] All SolidJS primitives are re-exported from `reactiveview/solidjs`
- [ ] All SolidJS Router primitives are re-exported from `reactiveview/router`
- [ ] ReactiveView-specific utilities exported from `reactiveview`
- [ ] The package version is tied to the gem version for consistency
- [ ] TypeScript types are properly exported
- [ ] Example application updated to use new import paths
- [ ] Documentation updated with new import conventions
- [ ] Vite/Vinxi alias configuration works seamlessly
- [ ] Bundle size is optimized (no duplicate SolidJS in final build)

## Tasks

- [ ] Create npm package structure (`packages/reactiveview/`)
- [ ] Set up TypeScript configuration for the package
- [ ] Bundle and re-export SolidJS primitives (`solid-js`)
- [ ] Bundle and re-export SolidJS Router (`@solidjs/router`)
- [ ] Export ReactiveView utilities (`useLoaderData`, `RequestTokenProvider`, etc.)
- [ ] Configure Vite/Vinxi for proper module aliasing in the template
- [ ] Add package.json scripts for building and publishing
- [ ] Update the gem's template to use the new package
- [ ] Update example application imports
- [ ] Update documentation and README
- [ ] Add tests for re-exported modules
- [ ] Set up npm publishing workflow (manual or automated)

## Technical Notes

- Consider using a monorepo structure with the npm package alongside the gem
- The package should be a peer dependency of the SolidStart template, not bundled into it
- Version synchronization between gem and npm package needs consideration
- May need to handle SSR vs client builds differently

## Related Files

- `reactive_view/template/package.json`
- `reactive_view/template/src/lib/reactive-view/index.ts`
- `reactive_view/template/src/app.tsx`
