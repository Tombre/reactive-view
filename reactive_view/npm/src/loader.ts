import { createResource, Resource } from "solid-js";
import { isServer } from "solid-js/web";
import { useLocation, useParams } from "@solidjs/router";

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

/**
 * Hook to load data from a Rails loader.
 * Automatically calls the corresponding Rails loader based on the current route.
 * 
 * @example
 * ```tsx
 * // With generated types (recommended):
 * import { useLoaderData } from "@reactive-view/core";
 * 
 * export default function UserPage() {
 *   // TypeScript knows the type from LoaderDataMap
 *   const data = useLoaderData<"users/[id]">();
 *   return <div>Hello, {data()?.user.name}</div>;
 * }
 * ```
 * 
 * @example
 * ```tsx
 * // With inline type definition:
 * import { useLoaderData } from "@reactive-view/core";
 * 
 * interface UserData {
 *   user: { id: number; name: string };
 * }
 * 
 * export default function UserPage() {
 *   const data = useLoaderData<UserData>();
 *   return <div>Hello, {data()?.user.name}</div>;
 * }
 * ```
 */
export function useLoaderData<T>(): Resource<T> {
  const location = useLocation();
  const params = useParams();

  const [data] = createResource(
    // Track location for reactivity
    () => ({ path: location.pathname, params: { ...params } as Record<string, string> }),
    async (source) => {
      const loaderPath = buildLoaderPath(source.path, source.params);
      const railsBaseUrl = getRailsBaseUrl();
      
      const url = new URL(`/_reactive_view/loaders/${loaderPath}/load`, railsBaseUrl);
      
      // Add route params as query parameters
      // Rails will use these to populate the loader's params
      Object.entries(source.params).forEach(([key, value]) => {
        if (value) {
          url.searchParams.set(key, value);
        }
      });

      // Build headers
      const headers: Record<string, string> = {
        "Accept": "application/json",
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
 * @example
 * buildLoaderPath("/users/123", { id: "123" }) -> "users/[id]"
 */
function buildLoaderPath(pathname: string, params: Record<string, string>): string {
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
      path = path.split("/").map(segment => 
        segment === value ? `[${key}]` : segment
      ).join("/");
    }
  }
  
  return path;
}
