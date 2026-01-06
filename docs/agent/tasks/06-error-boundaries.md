# Error Boundaries

**Status:** Not Started  
**Priority:** Medium  
**Category:** Developer Experience

## Context

SolidJS components can throw errors during rendering, and without proper error handling, these errors can crash the entire application or leave users with a blank screen. While SolidJS provides `ErrorBoundary` as a primitive, ReactiveView should offer:

1. A consistent error handling pattern across all ReactiveView applications
2. Sensible default error UI that doesn't expose sensitive information
3. Easy customization for application-specific error handling
4. Integration with error reporting services

Currently, if a component throws an error during SSR or client-side rendering, the behavior is unpredictable and provides poor user experience.

## Overview

Implement a comprehensive error boundary system for ReactiveView that:

- Wraps components with SolidJS `ErrorBoundary` in a ReactiveView-specific way
- Provides a default, styled error fallback UI
- Allows developers to provide custom error components
- Supports error reporting to external services
- Handles both SSR and client-side errors gracefully

**Without Error Boundaries:**
```
Component Error → Crash → Blank Screen / Hydration Mismatch
```

**With Error Boundaries:**
```
Component Error → Caught → Fallback UI → Error Reported → User Continues
```

## Acceptance Criteria

- [ ] ReactiveView provides an `<ErrorBoundary>` wrapper component
- [ ] Default error UI is shown when no custom fallback is provided
- [ ] Default error UI is styled appropriately and doesn't expose stack traces in production
- [ ] Custom error fallback components can be provided via props
- [ ] Error information is passed to fallback component (error message, reset function)
- [ ] Errors can be reported to external services via callback
- [ ] Error boundaries work correctly during SSR
- [ ] Error boundaries work correctly during client-side hydration
- [ ] Nested error boundaries work as expected (inner catches before outer)
- [ ] Documentation explains error boundary usage patterns
- [ ] Example application demonstrates error boundary usage

## Tasks

- [ ] Create `ErrorBoundary` wrapper component in `reactiveview` package
- [ ] Design and implement default error fallback UI component
- [ ] Add prop for custom fallback component (`fallback` prop)
- [ ] Implement `onError` callback prop for error reporting
- [ ] Add `reset` functionality to retry rendering
- [ ] Ensure stack traces are hidden in production builds
- [ ] Add development-mode enhanced error display with stack traces
- [ ] Test SSR error handling behavior
- [ ] Test client-side error handling behavior
- [ ] Test hydration error scenarios
- [ ] Integrate with Rails logger for server-side error capture
- [ ] Add TypeScript types for error boundary props
- [ ] Update example application with error boundary examples
- [ ] Document error boundary patterns and best practices

## Technical Notes

### Component API

```tsx
import { ErrorBoundary } from "reactiveview";

// Basic usage with default fallback
<ErrorBoundary>
  <MyComponent />
</ErrorBoundary>

// Custom fallback
<ErrorBoundary
  fallback={(err, reset) => (
    <div>
      <p>Something went wrong: {err.message}</p>
      <button onClick={reset}>Try Again</button>
    </div>
  )}
>
  <MyComponent />
</ErrorBoundary>

// With error reporting
<ErrorBoundary
  onError={(error, errorInfo) => {
    reportToService(error, errorInfo);
  }}
>
  <MyComponent />
</ErrorBoundary>
```

### Default Fallback UI

The default fallback should:
- Display a user-friendly error message
- Provide a "Try Again" button
- Show error details only in development
- Be styled to match common UI patterns
- Be accessible (ARIA labels, keyboard navigation)

### SSR Considerations

During SSR, errors should:
1. Be caught by the error boundary
2. Render the fallback UI in the HTML response
3. Log the error server-side (SolidStart and/or Rails)
4. Not expose sensitive information in the HTML

### Error Reporting Integration

```tsx
// Global error handler configuration
ReactiveView.configure({
  onError: (error, componentStack) => {
    // Send to Sentry, Bugsnag, etc.
    Sentry.captureException(error, {
      extra: { componentStack }
    });
  }
});
```

## Related Files

- `reactive_view/template/src/lib/reactive-view/index.ts`
- `reactive_view/template/src/app.tsx`
- `reactive_view/lib/reactive_view/renderer.rb`
