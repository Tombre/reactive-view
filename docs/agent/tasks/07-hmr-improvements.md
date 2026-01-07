# Hot Module Replacement Improvements

**Status:** Completed  
**Priority:** Medium  
**Category:** Developer Experience

## Context

ReactiveView relies on Vite's Hot Module Replacement (HMR) for fast development feedback. SolidStart/Vinxi has a known issue where route files in `src/routes/` always trigger full page reloads instead of hot-swapping components.

To work around this, ReactiveView uses a **wrapper pattern**:
- Page components are synced to `src/pages/` (HMR works here)
- Thin wrapper files in `src/routes/` import from `src/pages/`
- When you edit a page, only `src/pages/` changes, so Vite can hot-swap

## Overview

The HMR architecture enables:

- **True HMR** for page component changes (state preserved)
- **Loader file** changes trigger data refetching via custom HMR events
- **Route structure changes** (add/remove pages) trigger full reload as expected

**HMR Flow:**
```
Edit app/pages/counter.tsx
    │
    ↓
FileSync copies to .reactive_view/src/pages/counter.tsx
    │
    ↓
Vite detects change in src/pages/ (NOT src/routes/)
    │
    ↓
solid-refresh hot-swaps the component
    │
    ↓
Browser updates WITHOUT full reload, state preserved!
```

## Implementation Summary

### Phase 1: Wrapper Pattern for True HMR

SolidStart/Vinxi's file-system router triggers full reloads when route files change. To work around this:

- Page components are synced to `src/pages/` (not `src/routes/`)
- Thin wrapper files in `src/routes/` import and re-export from `src/pages/`
- Wrapper files never change during normal development
- Vite's HMR only sees changes in `src/pages/`, enabling true hot-swapping

**Generated wrapper example:**
```tsx
// .reactive_view/src/routes/counter.tsx (auto-generated)
import Page from "../pages/counter";
export * from "../pages/counter";
export default Page;
```

**Files modified:**
- `reactive_view/lib/reactive_view/file_sync.rb` - generates wrappers, syncs to src/pages/

### Phase 2: Loader File Change Detection

When `.loader.rb` files change, the system triggers automatic data refetching:

- `FileSync` watches for `.loader.rb` file changes (in addition to TSX/TS files)
- On loader change, it regenerates TypeScript types and notifies Vite
- Vite plugin exposes `POST /__reactive_view/invalidate-loader` endpoint
- Plugin emits custom HMR event `reactive-view:loader-update` to connected clients
- Client-side `loader.ts` listens for HMR events and triggers resource refetch

**Files modified:**
- `reactive_view/lib/reactive_view/file_sync.rb` - watches loader files, notifies Vite
- `reactive_view/npm/src/vite-plugin.ts` - invalidation endpoint, HMR event emission
- `reactive_view/npm/src/loader.ts` - HMR event listener, refetch trigger

### Phase 3: HMR WebSocket Path Normalization

Vinxi serves assets under `/_build/` which caused HMR WebSocket connection issues:

- Vite plugin normalizes the HMR path based on the configured `base`
- Uses relative path (`../@vite/ws`) to escape the `/_build` prefix
- Debug mode via `REACTIVE_VIEW_DEBUG=true` environment variable

**Files modified:**
- `reactive_view/npm/src/vite-plugin.ts` - HMR path normalization in `configResolved`
- `reactive_view/template/app.config.ts` - optimized HMR settings

## Acceptance Criteria

- [x] TSX component edits preserve local state when possible
- [x] Signal values are preserved during HMR updates
- [x] Changes to `.loader.rb` files trigger appropriate data refresh
- [x] HMR errors display helpful error overlay
- [x] Recovery from HMR errors doesn't require manual page refresh
- [x] HMR works correctly with nested route components
- [x] HMR performance is optimized (fast update cycles)
- [x] Console provides clear feedback during HMR cycles
- [x] Documentation covers HMR behavior and limitations
- [x] Example application demonstrates state preservation

## Tasks

- [x] Audit current Vite HMR configuration in `app.config.ts`
- [x] Configure Vite for optimal SolidJS HMR (solid-refresh plugin settings)
- [x] Implement state preservation for SolidJS signals during HMR
- [x] Add file watcher for `.loader.rb` file changes in the daemon
- [x] Implement loader change detection and refresh strategy
- [x] Configure HMR boundary settings for route components
- [x] Improve error overlay for HMR failures
- [x] Add HMR recovery mechanism (auto-retry, graceful fallback)
- [x] Optimize HMR update speed (minimize unnecessary re-renders)
- [x] Add development console logging for HMR events
- [x] Test HMR with various component patterns (signals, stores, context)
- [x] Test HMR with route parameter changes
- [x] Document HMR behavior and known limitations
- [x] Add HMR-specific configuration options if needed

## Technical Notes

### File Sync Architecture

```
app/pages/counter.tsx (source - you edit this)
    │
    ↓ FileSync copies
.reactive_view/src/pages/counter.tsx (actual component - HMR works)
    │
    ↓ Imported by
.reactive_view/src/routes/counter.tsx (thin wrapper - stable)
    │
    ↓ Vinxi router loads
Browser renders component
```

### Loader Change Flow

```
Edit users/index.loader.rb
    │
    ↓
FileSync (Listen gem) detects change
    │
    ├─→ Regenerate TypeScript types
    │
    └─→ POST to Vite: /__reactive_view/invalidate-loader
           │
           ↓
        Vite plugin emits HMR event: reactive-view:loader-update
           │
           ↓
        loader.ts receives event, increments invalidation signal
           │
           ↓
        createResource refetches data from Rails
```

### Vite HMR Configuration

```typescript
// app.config.ts
export default defineConfig({
  vite: {
    plugins: [
      reactiveViewPlugin({
        debug: process.env.REACTIVE_VIEW_DEBUG === "true",
      }),
    ],
    server: {
      hmr: {
        overlay: true, // Show error overlay
      }
    }
  }
});
```

### State Preservation Strategy

For SolidJS, state preservation during HMR requires:

1. Using `solid-refresh` Vite plugin correctly (included in @solidjs/start)
2. Ensuring signals are created at module scope or preserved
3. Avoiding side effects in component body that break on re-execution

```tsx
// This signal will be preserved during HMR
const [count, setCount] = createSignal(0);

export default function Counter() {
  // Component re-executes, but count signal persists
  return <button onClick={() => setCount(c => c + 1)}>{count()}</button>;
}
```

### Debugging HMR Issues

Set `REACTIVE_VIEW_DEBUG=true` in your environment to enable verbose logging:

```bash
REACTIVE_VIEW_DEBUG=true bin/dev
```

This will log:
- Module resolution for `#loaders/*` imports
- HMR updates for route files
- Loader invalidation requests and events

## Related Files

- `reactive_view/template/app.config.ts`
- `reactive_view/template/package.json`
- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/reactive_view/file_sync.rb`
- `reactive_view/lib/reactive_view/dev_proxy.rb`
- `reactive_view/npm/src/vite-plugin.ts`
- `reactive_view/npm/src/loader.ts`
