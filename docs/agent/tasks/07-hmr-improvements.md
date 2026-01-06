# Hot Module Replacement Improvements

**Status:** Not Started  
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

## Acceptance Criteria

- [ ] TSX component edits preserve local state when possible
- [ ] Signal values are preserved during HMR updates
- [ ] Changes to `.loader.rb` files trigger appropriate data refresh
- [ ] HMR errors display helpful error overlay
- [ ] Recovery from HMR errors doesn't require manual page refresh
- [ ] HMR works correctly with nested route components
- [ ] HMR performance is optimized (fast update cycles)
- [ ] Console provides clear feedback during HMR cycles
- [ ] Documentation covers HMR behavior and limitations
- [ ] Example application demonstrates state preservation

## Tasks

- [ ] Audit current Vite HMR configuration in `app.config.ts`
- [ ] Configure Vite for optimal SolidJS HMR (solid-refresh plugin settings)
- [ ] Implement state preservation for SolidJS signals during HMR
- [ ] Add file watcher for `.loader.rb` file changes in the daemon
- [ ] Implement loader change detection and refresh strategy
- [ ] Configure HMR boundary settings for route components
- [ ] Improve error overlay for HMR failures
- [ ] Add HMR recovery mechanism (auto-retry, graceful fallback)
- [ ] Optimize HMR update speed (minimize unnecessary re-renders)
- [ ] Add development console logging for HMR events
- [ ] Test HMR with various component patterns (signals, stores, context)
- [ ] Test HMR with route parameter changes
- [ ] Document HMR behavior and known limitations
- [ ] Add HMR-specific configuration options if needed

## Technical Notes

### Vite HMR Configuration

```typescript
// app.config.ts
export default defineConfig({
  vite: {
    plugins: [
      solid({
        hot: true,
        // Preserve signals across HMR
        babel: {
          plugins: [
            // solid-refresh configuration
          ]
        }
      })
    ],
    server: {
      hmr: {
        // HMR websocket configuration
        overlay: true,
      }
    }
  }
});
```

### Loader File Watching

The ReactiveView daemon should watch for loader file changes:

```ruby
# In daemon.rb
def watch_loader_files
  Listen.to(pages_path, only: /\.loader\.rb$/) do |modified, added, removed|
    notify_hmr_server(modified + added + removed)
  end
end
```

### State Preservation Strategy

For SolidJS, state preservation during HMR requires:

1. Using `solid-refresh` Vite plugin correctly
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

### Loader Refresh Strategy Options

1. **Full page refresh:** Simple but loses all state
2. **Data refetch only:** Keep component, fetch new loader data
3. **Route-level refresh:** Remount route component with fresh data
4. **Intelligent diff:** Only refresh if loader output schema changed

Recommend option 2 or 3 for best DX.

### HMR Event Handling

```typescript
// Client-side HMR event handling
if (import.meta.hot) {
  import.meta.hot.on('reactive-view:loader-update', (data) => {
    // Refetch loader data for affected route
    invalidateLoaderData(data.route);
  });
}
```

## Related Files

- `reactive_view/template/app.config.ts`
- `reactive_view/template/package.json`
- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/reactive_view/file_sync.rb`
