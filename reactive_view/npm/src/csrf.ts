import { isServer } from "solid-js/web";

/**
 * Get the CSRF token for mutation requests.
 *
 * During SSR, returns the token from Rails globals (set during render request).
 * On client, reads from the meta tag injected into the HTML.
 *
 * @returns The CSRF token or null if not available
 *
 * @example
 * const token = getCSRFToken();
 * if (token) {
 *   headers["X-CSRF-Token"] = token;
 * }
 */
export function getCSRFToken(): string | null {
  if (isServer) {
    // During SSR, Rails passes the token via globalThis
    return (globalThis as any).__RAILS_CSRF_TOKEN__ || null;
  }

  // On client, read from meta tag
  if (typeof document === "undefined") return null;

  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta?.getAttribute("content") || null;
}

/**
 * Get the CSRF parameter name (typically "authenticity_token" in Rails)
 * @returns The parameter name or null if not available
 */
export function getCSRFParam(): string {
  if (isServer) {
    return "authenticity_token";
  }

  if (typeof document === "undefined") return "authenticity_token";

  const meta = document.querySelector('meta[name="csrf-param"]');
  return meta?.getAttribute("content") || "authenticity_token";
}
