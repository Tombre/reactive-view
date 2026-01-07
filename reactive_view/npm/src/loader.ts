import { createResource, createSignal, type Resource } from "solid-js";
import { isServer } from "solid-js/web";
import { useLocation, useParams } from "@solidjs/router";
import type { LoaderDataMap } from "./types";

// Get the Rails base URL from environment or default
const getRailsBaseUrl = (): string => {
  if (isServer) {
    // Server-side: check globalThis first, then environment variable, then default
    const globalRailsUrl = (globalThis as any).__RAILS_BASE_URL__;
    if (globalRailsUrl) return globalRailsUrl;

    // Try to access process.env safely (may not exist in all environments)
    try {
      const envUrl = (globalThis as any).process?.env?.RAILS_BASE_URL;
      if (envUrl) return envUrl;
    } catch {
      // Ignore - process.env not available
    }

    return "http://localhost:3000";
  }
  // On client, use the current origin (same-origin request)
  return window.location.origin;
};

// Get cookies for SSR requests (forwarded from Rails)
const getSSRCookies = (): string | undefined => {
  if (isServer) {
    return (globalThis as any).__REACTIVE_VIEW_COOKIES__;
  }
  return undefined;
};

// ============================================================================
// HMR Support for Loader Invalidation
// ============================================================================

/**
 * Track invalidated routes for HMR-triggered refetching.
 * When a loader file changes, Rails notifies Vite which broadcasts to clients.
 * This signal triggers refetching of affected loaders.
 */
const [loaderInvalidationCount, setLoaderInvalidationCount] = createSignal(0);

/**
 * Set of routes that have been invalidated by HMR.
 * Used to determine if a specific loader should refetch.
 */
let invalidatedRoutes: Set<string> = new Set();

/**
 * Setup HMR event listener for loader invalidation.
 * This runs once on the client when the module loads.
 */
function setupLoaderHMR(): void {
  if (isServer) return;

  // Check if HMR is available (Vite dev mode)
  if (typeof import.meta.hot !== "undefined" && import.meta.hot) {
    import.meta.hot.on(
      "reactive-view:loader-update",
      (data: { routes: string[]; type: string; timestamp: number }) => {
        console.log("[ReactiveView] Loader update received:", data);

        // Add routes to invalidation set
        for (const route of data.routes) {
          invalidatedRoutes.add(route);
        }

        // Trigger refetch for all active loaders
        // The signal change will cause createResource to re-run its fetcher
        setLoaderInvalidationCount((c) => c + 1);

        // Clear invalidation set after a tick to allow loaders to check it
        setTimeout(() => {
          invalidatedRoutes.clear();
        }, 100);
      }
    );

    console.log("[ReactiveView] HMR loader invalidation listener registered");
  }
}

// Initialize HMR on module load (client-side only)
if (!isServer) {
  setupLoaderHMR();
}

// ============================================================================
// useLoaderData Hook
// ============================================================================

/**
 * Hook to load data from a Rails loader.
 *
 * ## Usage Modes
 *
 * ### 1. Auto-typed (Recommended)
 * Import from the route-specific generated loader file:
 * ```tsx
 * import { useLoaderData } from "#loaders/users/index";
 *
 * export default function UsersPage() {
 *   const data = useLoaderData();  // Automatically typed!
 *   return <div>{data()?.total} users</div>;
 * }
 * ```
 *
 * ### 2. Cross-route loading
 * Load data from a different route by specifying the route path:
 * ```tsx
 * import { useLoaderData } from "@reactive-view/core";
 *
 * export default function SomePage() {
 *   const userData = useLoaderData("users/[id]", { id: "123" });
 *   return <div>{userData()?.user.name}</div>;
 * }
 * ```
 *
 * ### 3. Manual typing
 * Provide an explicit type parameter:
 * ```tsx
 * import { useLoaderData } from "@reactive-view/core";
 *
 * interface MyData { name: string; }
 *
 * export default function MyPage() {
 *   const data = useLoaderData<MyData>();
 *   return <div>{data()?.name}</div>;
 * }
 * ```
 *
 * ## HMR Support
 *
 * When a `.loader.rb` file changes during development, the data will
 * automatically refetch without requiring a page refresh.
 */

// Overload 1: No arguments - uses current route, type provided by caller or generated import
export function useLoaderData<T>(): Resource<T>;

// Overload 2: Explicit route with optional params - for cross-route loading
export function useLoaderData<R extends keyof LoaderDataMap>(
  route: R,
  params?: Record<string, string>
): Resource<LoaderDataMap[R]>;

// Overload 3: Explicit route (string) with params - fallback for unknown routes
export function useLoaderData<T>(
  route: string,
  params?: Record<string, string>
): Resource<T>;

// Implementation
export function useLoaderData<T>(
  route?: string,
  explicitParams?: Record<string, string>
): Resource<T> {
  const location = useLocation();
  const routeParams = useParams<Record<string, string>>();

  const [data] = createResource(
    // Track location, params, and invalidation count for reactivity
    () => ({
      path: location.pathname,
      routeParams: { ...routeParams } as Record<string, string>,
      explicitRoute: route,
      explicitParams,
      // Include invalidation count to trigger refetch on HMR
      invalidationCount: loaderInvalidationCount(),
    }),
    async (source) => {
      let loaderPath: string;
      let params: Record<string, string>;

      if (source.explicitRoute) {
        // Cross-route loading: use the explicit route and params
        loaderPath = source.explicitRoute;
        params = source.explicitParams || {};
      } else {
        // Current route loading: derive from location
        loaderPath = buildLoaderPath(source.path, source.routeParams);
        params = source.routeParams;
      }

      const railsBaseUrl = getRailsBaseUrl();
      const url = new URL(
        `/_reactive_view/loaders/${loaderPath}/load`,
        railsBaseUrl
      );

      // Add route params as query parameters
      // Rails will use these to populate the loader's params
      Object.entries(params).forEach(([key, value]) => {
        if (value) {
          url.searchParams.set(key, value);
        }
      });

      // Build headers
      const headers: Record<string, string> = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };

      // For SSR, forward the cookies from Rails
      const ssrCookies = getSSRCookies();
      if (ssrCookies) {
        headers["Cookie"] = ssrCookies;
      }

      const response = await fetch(url.toString(), {
        method: "GET",
        headers,
        // Include credentials for cookie-based auth on client-side navigation
        credentials: "include",
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(
          errorData.error || `Loader request failed: ${response.statusText}`
        );
      }

      return response.json() as Promise<T>;
    }
  );

  return data as Resource<T>;
}

/**
 * Build the loader path from the current URL path and params.
 * Converts actual values back to parameter placeholders.
 *
 * For directory routes (like /users), this appends /index to match
 * the file-based routing convention (users/index.tsx -> users/index loader).
 *
 * @example
 * buildLoaderPath("/users/123", { id: "123" }) -> "users/[id]"
 * buildLoaderPath("/users", {}) -> "users/index"
 * buildLoaderPath("/", {}) -> "index"
 */
function buildLoaderPath(
  pathname: string,
  params: Record<string, string>
): string {
  // Remove leading slash
  let path = pathname.replace(/^\//, "");

  // Handle root path
  if (!path) {
    return "index";
  }

  // Replace param values with their parameter names in brackets
  // Sort by value length descending to avoid partial replacements
  const sortedParams = Object.entries(params).sort(
    ([, a], [, b]) => b.length - a.length
  );

  for (const [key, value] of sortedParams) {
    if (value) {
      // Replace the value with [key]
      // Handle both segment replacement and partial path replacement
      path = path
        .split("/")
        .map((segment) => (segment === value ? `[${key}]` : segment))
        .join("/");
    }
  }

  // If the path doesn't end with a param placeholder (like [id]),
  // it's a directory route and needs /index appended
  // Examples: /users -> users/index, /users/123 -> users/[id] (no index needed)
  const lastSegment = path.split("/").pop() || "";
  const hasParamAtEnd = lastSegment.startsWith("[") && lastSegment.endsWith("]");

  if (!hasParamAtEnd) {
    path = `${path}/index`;
  }

  return path;
}
