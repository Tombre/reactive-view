import { createResource, createSignal, type Resource, type Accessor } from "solid-js";
import { isServer } from "solid-js/web";
import { useLocation, useParams, query, createAsync } from "@solidjs/router";
import type { LoaderDataMap } from "./types";
import { getSSRRequestContext } from "./request-context.js";

const LOADER_REQUEST_MAX_ATTEMPTS = 2;
const LOADER_RETRY_DELAY_MS = 150;
type RedirectHandling = "window" | "response";

// Get the Rails base URL from environment or default
const getRailsBaseUrl = (): string => {
  if (isServer) {
    const { railsBaseUrl } = getSSRRequestContext();
    if (railsBaseUrl) return railsBaseUrl;

    // Backward-compat fallback
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
  // On client, prefer the injected Rails base URL (for split-origin dev setups)
  const clientRailsUrl = (window as any).__RAILS_BASE_URL__;
  if (clientRailsUrl) return clientRailsUrl;

  // Fallback to same-origin requests
  return window.location.origin;
};

// Get cookies for SSR requests (forwarded from Rails)
const getSSRCookies = (): string | undefined => {
  if (isServer) {
    const { cookies } = getSSRRequestContext();
    if (cookies) return cookies;

    // Backward-compat fallback
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
// Loader Query Functions (for preloading)
// ============================================================================

/**
 * Fetch loader data from Rails.
 * This is the core fetch function used by both query-based and resource-based loaders.
 *
 * @param loaderPath - The route path (e.g., "users/index", "users/[id]")
 * @param params - Route parameters to pass to the loader
 */
async function fetchLoaderData<T>(
  loaderPath: string,
  params: Record<string, string>
): Promise<T> {
  const railsBaseUrl = getRailsBaseUrl();
  const url = new URL(
    `/_reactive_view/loaders/${loaderPath}/load`,
    railsBaseUrl
  );

  // Add route params as query parameters
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

  return requestLoaderData<T>(url, headers, "response");
}

/**
 * Create a cached query function for a loader.
 * This query is cached by the router and can be preloaded before navigation.
 *
 * @param loaderPath - The route path (e.g., "users/index", "users/[id]")
 * @returns A query function that can be called to fetch/cache data
 *
 * @example
 * // In a generated loader file:
 * const getUsersQuery = createLoaderQuery<LoaderData>("users/index");
 *
 * export function preloadData() {
 *   getUsersQuery({});
 * }
 *
 * export function useLoaderData() {
 *   return createAsync(() => getUsersQuery({}));
 * }
 */
export function createLoaderQuery<T>(loaderPath: string): (params: Record<string, string>) => Promise<T> {
  const queryFn = query(
    async (params: Record<string, string>) => fetchLoaderData<T>(loaderPath, params),
    `loader:${loaderPath}`
  );
  // Cast to the expected return type - the router's NarrowResponse is compatible
  // with our data type since we're not using Response objects
  return queryFn as (params: Record<string, string>) => Promise<T>;
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

      return requestLoaderData<T>(url, headers, "window");
    }
  );

  return data as Resource<T>;
}

async function requestLoaderData<T>(
  url: URL,
  headers: Record<string, string>,
  redirectHandling: RedirectHandling
): Promise<T> {
  let lastError: Error | null = null;
  let requestUrl = new URL(url.toString());

  for (let attempt = 1; attempt <= LOADER_REQUEST_MAX_ATTEMPTS; attempt += 1) {
    let response: Response;

    try {
      response = await fetch(requestUrl.toString(), {
        method: "GET",
        headers,
        // Include credentials for cookie-based auth on client-side navigation
        credentials: "include",
      });
    } catch (error) {
      const fallbackUrl = resolveClientOriginFallbackUrlForFailure(requestUrl);

      if (fallbackUrl) {
        requestUrl = fallbackUrl;
        continue;
      }

      throw error;
    }

    const contentType = response.headers.get("content-type") || "";
    const bodyText = await response.text();

    const fallbackUrl = resolveClientOriginFallbackUrl(
      requestUrl,
      contentType,
      bodyText
    );

    if (fallbackUrl) {
      requestUrl = fallbackUrl;
      continue;
    }

    const retryableHtmlResponse =
      !contentType.includes("application/json") &&
      contentType.includes("text/html") &&
      bodyText.startsWith("<!DOCTYPE html>") &&
      attempt < LOADER_REQUEST_MAX_ATTEMPTS;

    if (retryableHtmlResponse) {
      await sleep(LOADER_RETRY_DELAY_MS * attempt);
      continue;
    }

    try {
      const data = parseResponseJson(response, contentType, bodyText);

      if (!response.ok) {
        const redirectPath = extractRedirectPath(data);

        if (redirectPath && redirectHandling === "response") {
          return createRedirectResponse(redirectPath) as T;
        }

        if (redirectPath && redirectHandling === "window" && !isServer) {
          window.location.assign(redirectPath);
          return new Promise<T>(() => {});
        }

        throw new Error(
          (data as Record<string, unknown>).error as string ||
            `Loader request failed: ${response.status} ${response.statusText}`
        );
      }

      return data as T;
    } catch (error) {
      if (error instanceof Error) {
        lastError = error;
      }

      const canRetry =
        attempt < LOADER_REQUEST_MAX_ATTEMPTS &&
        contentType.includes("text/html") &&
        bodyText.startsWith("<!DOCTYPE html>");

      if (!canRetry) {
        throw error;
      }

      await sleep(LOADER_RETRY_DELAY_MS * attempt);
    }
  }

  throw (
    lastError ||
      new Error(`Loader request failed for ${requestUrl.toString()} after retries`)
  );
}

function resolveClientOriginFallbackUrl(
  requestUrl: URL,
  contentType: string,
  bodyText: string
): URL | null {
  if (isServer) {
    return null;
  }

  const isHtmlDocumentResponse =
    contentType.includes("text/html") && bodyText.startsWith("<!DOCTYPE html>");

  if (!isHtmlDocumentResponse) {
    return null;
  }

  // WHY: In split-origin dev setups we may temporarily fetch from the daemon
  // origin. When that origin responds with an HTML document shell instead of
  // loader JSON (common during boot/reload races), retrying the same origin
  // keeps failing. Falling back to the browser origin recovers to Rails' JSON
  // loader endpoint and prevents repeated "Expected JSON response" regressions.
  const currentOrigin = window.location.origin;
  if (requestUrl.origin === currentOrigin) {
    return null;
  }

  return new URL(`${requestUrl.pathname}${requestUrl.search}`, currentOrigin);
}

function resolveClientOriginFallbackUrlForFailure(requestUrl: URL): URL | null {
  if (isServer) {
    return null;
  }

  // WHY: Network failures on the injected daemon base URL are often transient
  // startup/disconnect issues. Retrying against the browser origin lets client
  // navigation continue without forcing a full page refresh.
  const currentOrigin = window.location.origin;
  if (requestUrl.origin === currentOrigin) {
    return null;
  }

  return new URL(`${requestUrl.pathname}${requestUrl.search}`, currentOrigin);
}

function parseResponseJson(
  response: Response,
  contentType: string,
  bodyText: string
): unknown {
  if (!contentType.includes("application/json")) {
    throw new Error(
      `Expected JSON response from ${response.url}, received ${contentType || "unknown content-type"} (status ${response.status}). Body starts with: ${bodyText.slice(
        0,
        120
      )}`
    );
  }

  try {
    return JSON.parse(bodyText);
  } catch {
    throw new Error(
      `Invalid JSON response from ${response.url}. Body starts with: ${bodyText.slice(
        0,
        120
      )}`
    );
  }
}

function extractRedirectPath(data: unknown): string | null {
  if (!data || typeof data !== "object") {
    return null;
  }

  const redirectValue = (data as Record<string, unknown>).redirect;
  if (typeof redirectValue !== "string" || redirectValue.length === 0) {
    return null;
  }

  return redirectValue;
}

function createRedirectResponse(path: string): Response {
  return new Response(null, {
    status: 302,
    headers: {
      Location: path
    }
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
