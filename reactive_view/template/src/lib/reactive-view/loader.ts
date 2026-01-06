import { createResource, Resource } from "solid-js";
import { isServer } from "solid-js/web";
import { useLocation, useParams } from "@solidjs/router";
import { useRequestToken } from "./context";

// Get the Rails base URL from environment or default
const getRailsBaseUrl = (): string => {
  if (isServer) {
    return process.env.RAILS_BASE_URL || "http://localhost:3000";
  }
  // On client, use the current origin (same-origin request)
  return window.location.origin;
};

/**
 * Hook to load data from a Rails loader.
 * Automatically calls the corresponding Rails loader based on the current route.
 * 
 * @example
 * ```tsx
 * // In app/pages/users/[id].tsx
 * import { useLoaderData } from "~/lib/reactive-view";
 * 
 * export default function UserPage() {
 *   const user = useLoaderData<{ id: number; name: string }>();
 *   return <div>Hello, {user()?.name}</div>;
 * }
 * ```
 */
export function useLoaderData<T>(): Resource<T> {
  const token = useRequestToken();
  const location = useLocation();
  const params = useParams();

  const [data] = createResource(
    // Track both token and location for reactivity
    () => ({ token, path: location.pathname, params: { ...params } }),
    async (source) => {
      const loaderPath = buildLoaderPath(source.path, source.params);
      const railsBaseUrl = getRailsBaseUrl();
      
      const url = new URL(`/_reactive_view/loaders/${loaderPath}/load`, railsBaseUrl);
      
      // Add token if available (required for SSR)
      if (source.token) {
        url.searchParams.set("token", source.token);
      }
      
      // Add route params as query parameters for client-side navigation
      // (Rails will use these to reconstruct the request context)
      Object.entries(source.params).forEach(([key, value]) => {
        if (value) {
          url.searchParams.set(key, value);
        }
      });

      const response = await fetch(url.toString(), {
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
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
