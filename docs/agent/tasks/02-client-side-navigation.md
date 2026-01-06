# Client-Side Navigation Data Fetching

**Status:** Not Started  
**Priority:** High  
**Category:** Core Functionality

## Context

The current MVP implementation handles server-side rendering (SSR) data loading correctly. When a user first visits a page, Rails generates a request token, SolidStart renders the page, calls back to Rails for loader data, and returns fully rendered HTML.

However, after the page hydrates and becomes interactive, client-side navigation (clicking `<A>` links from SolidJS Router) does not automatically fetch fresh data from Rails loaders. This is a critical gap because:

1. Users expect SPA-like navigation with fresh data on each route
2. The current `useLoaderData` hook only works during SSR
3. Client-side navigation results in stale or missing data

## Overview

Implement a seamless data fetching mechanism for client-side navigation that:

- Automatically detects client-side route transitions
- Fetches fresh data from the appropriate Rails loader
- Provides loading states during data fetching
- Optionally caches previously loaded data
- Handles errors gracefully

The solution should be transparent to developers - the same `useLoaderData()` hook should work for both SSR and client-side navigation.

**SSR Flow (current, working):**
```
Page Request → Rails Loader → Token → SolidStart SSR → Callback to Rails → HTML Response
```

**Client Navigation Flow (to implement):**
```
Link Click → SolidJS Router → useLoaderData detects client → Fetch from Rails → Update UI
```

## Acceptance Criteria

- [ ] `useLoaderData()` returns fresh data on client-side navigation
- [ ] Loading states are available via the resource API (e.g., `data.loading`)
- [ ] Error states are properly propagated
- [ ] The Rails loader endpoint accepts client-side requests (authentication via cookies or session)
- [ ] No token required for client-side requests (uses standard Rails session)
- [ ] Data is refetched when route params change
- [ ] Optional: Previously loaded data can be cached and revalidated
- [ ] TypeScript types remain accurate
- [ ] No breaking changes to existing SSR behavior
- [ ] Example application demonstrates client-side navigation with data

## Tasks

- [ ] Implement client-side token generation or cookie-based authentication
- [ ] Update `useLoaderData` hook to detect client vs server context
- [ ] Create data fetching logic for client-side navigation using SolidJS `createResource`
- [ ] Add loading state support to the hook's return value
- [ ] Handle loading states during client-side fetches (Suspense boundaries)
- [ ] Implement error handling for failed fetches
- [ ] Add optional cache strategy for previously loaded data
- [ ] Update `LoaderDataController` to accept cookie-based auth for client requests
- [ ] Add CSRF protection for client-side requests
- [ ] Update example application to demonstrate client navigation
- [ ] Add tests for client-side data fetching
- [ ] Document the behavior and any configuration options

## Technical Notes

### Authentication Approach

For SSR, we use signed tokens because SolidStart is a separate process. For client-side navigation, we have options:

1. **Cookie-based (recommended):** Client includes Rails session cookie, loader validates session
2. **Token refresh:** Generate new tokens on each navigation (complex)
3. **Long-lived tokens:** Store token in client state (security concerns)

Recommend cookie-based approach as it leverages existing Rails session infrastructure.

### Implementation Considerations

```typescript
// Enhanced useLoaderData hook
export function useLoaderData<T>(): Resource<T> {
  const isServer = isServer; // from solid-js/web
  const location = useLocation();
  const params = useParams();
  
  const [data] = createResource(
    () => ({ path: location.pathname, params: { ...params } }),
    async (source) => {
      if (isServer) {
        // SSR path - use token from context
        return fetchWithToken(source);
      } else {
        // Client path - use cookies
        return fetchWithCookies(source);
      }
    }
  );
  
  return data;
}
```

### Cache Strategy Options

1. **No cache:** Always fetch fresh (simplest)
2. **Route-based cache:** Cache by route, invalidate on navigation
3. **SWR pattern:** Show stale, revalidate in background
4. **Manual invalidation:** Developer controls cache

## Related Files

- `reactive_view/template/src/lib/reactive-view/loader.ts`
- `reactive_view/app/controllers/reactive_view/loader_data_controller.rb`
- `reactive_view/lib/reactive_view/request_context.rb`
