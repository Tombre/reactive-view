# Hot Module Replacement Improvements

**Status:** Completed  
**Priority:** Medium  
**Category:** Developer Experience

## Context

ReactiveView relies on Vite's Hot Module Replacement (HMR) for fast development feedback. While basic HMR works out of the box with SolidStart, there are several areas where the developer experience can be improved:

1. State preservation during component updates is inconsistent
2. Changes to loader files (`.loader.rb`) don't trigger appropriate refreshes
3. HMR configuration isn't optimized for the ReactiveView file structure
4. Error recovery after HMR failures can be clunky

A smooth HMR experience is critical for developer productivity and adoption of the framework.

## Overview

Improve the Hot Module Replacement experience for ReactiveView developers by:

- Optimizing Vite HMR configuration for TSX file patterns
- Preserving component state during hot updates where possible
- Handling loader file changes with appropriate refresh strategies
- Improving error recovery and feedback during HMR cycles

**Current HMR Experience:**
```
Edit TSX → Vite Detects → Full Component Remount → State Lost
Edit Loader → No Detection → Manual Refresh Required
```

**Improved HMR Experience:**
```
Edit TSX → Vite Detects → Granular Update → State Preserved
Edit Loader → File Watcher → Intelligent Refresh → Fresh Data
```

## Implementation Summary

### Phase 1: Direct WebSocket HMR Connection

HMR WebSocket connections bypass the Rails proxy and connect directly to Vite:

- Configured Vite's `server.hmr.clientPort` to tell the browser to connect to port 3001
- Browser loads page from Rails (port 3000), but HMR WebSocket connects to Vite (port 3001)
- This avoids the complexity of proxying WebSockets through Rack middleware
- HTTP asset requests still go through the Rails DevProxy for consistent routing

**Files modified:**
- `reactive_view/template/app.config.ts` - configured `hmr.clientPort: 3001`

### Phase 2: Loader File Change Detection

When `.loader.rb` files change, the system now triggers automatic data refetching:

- `FileSync` watches for `.loader.rb` file changes (in addition to TSX/TS files)
- On loader change, it regenerates TypeScript types and notifies Vite
- Vite plugin exposes `POST /__reactive_view/invalidate-loader` endpoint
- Plugin emits custom HMR event `reactive-view:loader-update` to connected clients
- Client-side `loader.ts` listens for HMR events and triggers resource refetch

**Files modified:**
- `reactive_view/lib/reactive_view/file_sync.rb` - watches loader files, notifies Vite
- `reactive_view/npm/src/vite-plugin.ts` - invalidation endpoint, HMR event emission
- `reactive_view/npm/src/loader.ts` - HMR event listener, refetch trigger

### Phase 3: HMR Configuration Optimization

Optimized Vite configuration for better HMR experience:

- Added debug mode via `REACTIVE_VIEW_DEBUG=true` environment variable
- Enabled HMR error overlay for better error visibility
- Added dependency pre-bundling for faster cold starts
- Added HMR logging in the Vite plugin for debugging

**Files modified:**
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

### WebSocket Proxy Architecture

```
Browser (localhost:3000)
    │
    │ WebSocket upgrade request to /_build/@vite/client
    ↓
Rails DevProxy Middleware
    │
    │ Detects Upgrade header, establishes upstream connection
    ↓
Vite Dev Server (localhost:3001)
    │
    │ HMR events broadcast
    ↓
DevProxy bridges messages back to browser
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
