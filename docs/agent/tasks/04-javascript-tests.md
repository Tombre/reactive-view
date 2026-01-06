# JavaScript/TypeScript Tests

**Status:** Not Started  
**Priority:** Medium  
**Category:** Testing

## Context

The current test suite only covers the Ruby components of ReactiveView. The JavaScript/TypeScript code in the SolidStart template has no automated tests. This includes critical functionality like:

- The `useLoaderData` hook that fetches data from Rails
- The `RequestTokenProvider` context that manages authentication tokens
- The `/api/render` endpoint that Rails calls for SSR

Without tests, changes to the frontend code risk introducing regressions that won't be caught until manual testing or production issues.

## Overview

Establish a comprehensive test suite for the SolidStart template code using modern JavaScript testing tools. The test suite should:

- Cover all ReactiveView-specific hooks and components
- Test the API endpoints
- Run quickly for fast feedback during development
- Integrate with CI/CD pipeline
- Provide clear error messages when tests fail

## Acceptance Criteria

- [ ] Test framework is set up and configured (Vitest recommended)
- [ ] `useLoaderData` hook is tested for SSR and client scenarios
- [ ] `RequestTokenProvider` context is tested
- [ ] `/api/render` endpoint is tested
- [ ] Tests run in CI on every pull request
- [ ] Test coverage reporting is available
- [ ] Tests complete in under 30 seconds
- [ ] Documentation explains how to run and write tests
- [ ] At least 80% code coverage on ReactiveView-specific code

## Tasks

- [ ] Set up Vitest (or similar) testing framework in the template
- [ ] Configure TypeScript for test files
- [ ] Create test utilities and mocks for SolidJS
- [ ] Write tests for `useLoaderData` hook
  - [ ] SSR context with token
  - [ ] Client context without token
  - [ ] Error handling
  - [ ] Loading states
- [ ] Write tests for `RequestTokenProvider`
  - [ ] Token extraction from URL
  - [ ] Token context propagation
- [ ] Write tests for `/api/render` endpoint
  - [ ] Successful render requests
  - [ ] Error responses
  - [ ] Token validation
- [ ] Add test script to package.json
- [ ] Configure CI pipeline to run tests
- [ ] Set up code coverage reporting
- [ ] Document testing conventions and how to run tests

## Technical Notes

### Recommended Stack

- **Vitest** - Fast, Vite-native test runner
- **@solidjs/testing-library** - Testing utilities for SolidJS
- **msw** - Mock Service Worker for API mocking

### Example Test Structure

```typescript
// src/lib/reactive-view/__tests__/loader.test.ts
import { describe, it, expect, vi } from 'vitest';
import { renderHook } from '@solidjs/testing-library';
import { useLoaderData } from '../loader';

describe('useLoaderData', () => {
  it('fetches data from Rails in SSR context', async () => {
    // Mock the fetch call
    vi.mock('solid-js/web', () => ({ isServer: true }));
    
    const { result } = renderHook(() => useLoaderData());
    
    // Assertions
  });
  
  it('handles errors gracefully', async () => {
    // Test error scenarios
  });
});
```

### CI Configuration

```yaml
# .github/workflows/test.yml
jobs:
  js-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: cd reactive_view/template && npm ci
      - run: cd reactive_view/template && npm test
```

## Related Files

- `reactive_view/template/package.json`
- `reactive_view/template/src/lib/reactive-view/loader.ts`
- `reactive_view/template/src/lib/reactive-view/context.tsx`
- `reactive_view/template/src/routes/api/render.ts`
