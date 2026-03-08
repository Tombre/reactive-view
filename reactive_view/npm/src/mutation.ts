import { action, redirect } from "@solidjs/router";
import { isServer } from "solid-js/web";
import { getCSRFToken } from "./csrf.js";
import { getSSRRequestContext } from "./request-context.js";

// ============================================================================
// Types
// ============================================================================

/**
 * Result from a mutation action.
 * Contains success status, optional errors, and any additional data.
 */
export interface MutationResult<T = unknown> {
  /** Whether the mutation was successful */
  success: boolean;
  /** Validation errors keyed by field name */
  errors?: Record<string, string[]>;
  /** Internal redirect instruction (handled automatically) */
  _redirect?: string;
  /** Routes to revalidate after mutation */
  _revalidate?: string[];
  /** Any additional data returned by the mutation */
  [key: string]: unknown;
}

type MutationJsonInput = Record<string, unknown>;

// ============================================================================
// Shared Utilities (same as loader.ts)
// ============================================================================

/**
 * Get the Rails base URL from environment or globals
 */
function getRailsBaseUrl(): string {
  if (isServer) {
    const { railsBaseUrl } = getSSRRequestContext();
    if (railsBaseUrl) return railsBaseUrl;

    const globalRailsUrl = (globalThis as any).__RAILS_BASE_URL__;
    if (globalRailsUrl) return globalRailsUrl;

    try {
      const envUrl = (globalThis as any).process?.env?.RAILS_BASE_URL;
      if (envUrl) return envUrl;
    } catch {
      // Ignore - process.env not available
    }

    return "http://localhost:3000";
  }

  const clientRailsUrl = (window as any).__RAILS_BASE_URL__;
  if (clientRailsUrl) return clientRailsUrl;

  return window.location.origin;
}

/**
 * Get cookies for SSR requests (forwarded from Rails)
 */
function getSSRCookies(): string | undefined {
  if (isServer) {
    const { cookies } = getSSRRequestContext();
    if (cookies) return cookies;

    return (globalThis as any).__REACTIVE_VIEW_COOKIES__;
  }
  return undefined;
}

// ============================================================================
// Mutation Action Creator
// ============================================================================

/**
 * Create a mutation action for a loader route.
 *
 * This creates a Solid Router action that POSTs to the Rails mutation endpoint.
 * The action automatically handles:
 * - CSRF token inclusion
 * - Cookie forwarding for SSR
 * - Redirect responses from the server
 * - Route revalidation after success
 *
 * @param loaderPath - The loader path (e.g., "users/[id]")
 * @param mutationName - The mutation method name (defaults to "mutate")
 * @returns A Solid Router action that can be used with forms or useAction
 *
 * @example
 * // In generated loader file:
 * export const updateAction = createMutation("users/[id]", "update");
 *
 * // Usage in component:
 * <form action={updateAction} method="post">
 *   <input name="name" />
 *   <button type="submit">Save</button>
 * </form>
 *
 * @example
 * // Programmatic usage with FormData:
 * const update = useAction(updateAction);
 * await update(new FormData(formElement));
 *
 * @example
 * // Programmatic usage with JSON:
 * const update = useAction(updateAction);
 * await update({ name: "New Name", email: "new@example.com" });
 */
export function createMutation<
  TResult = unknown,
  TInput = MutationJsonInput,
>(
  loaderPath: string,
  mutationName: string = "mutate"
) {
  return action(
    async (input: FormData | TInput): Promise<MutationResult<TResult>> => {
      const railsBaseUrl = getRailsBaseUrl();
      const url = new URL(
        `/_reactive_view/loaders/${loaderPath}/mutate`,
        railsBaseUrl
      );

      // Add mutation name as query param
      url.searchParams.set("_mutation", mutationName);

      // Build headers
      const headers: Record<string, string> = {
        Accept: "application/json",
        "X-Reactive-View-Client": "true",
      };

      // Add CSRF token for security
      const csrfToken = getCSRFToken();
      if (csrfToken) {
        headers["X-CSRF-Token"] = csrfToken;
      }

      // For SSR, forward cookies
      const ssrCookies = getSSRCookies();
      if (ssrCookies) {
        headers["Cookie"] = ssrCookies;
      }

      let body: BodyInit;
      if (isFormDataInput(input)) {
        body = input;
      } else if (isJsonInput(input)) {
        headers["Content-Type"] = "application/json";
        body = JSON.stringify(input);
      } else {
        throw new Error(
          "Mutation input must be FormData or a JSON object"
        );
      }

      const response = await fetch(url.toString(), {
        method: "POST",
        headers,
        body,
        credentials: "include",
      });

      // Parse the response
      let result: MutationResult<TResult>;
      try {
        result = (await parseResponseJson(response)) as MutationResult<TResult>;
      } catch {
        throw new Error(
          `Mutation failed: ${response.status} ${response.statusText}`
        );
      }

      // Handle redirect responses from the server
      if (result._redirect) {
        throw redirect(result._redirect, {
          revalidate: result._revalidate || [],
        });
      }

      // For non-redirect errors, check HTTP status
      if (!response.ok && !result.errors) {
        throw new Error(
          result.error?.toString() ||
            `Mutation failed: ${response.status} ${response.statusText}`
        );
      }

      return result;
    },
    `${loaderPath}:${mutationName}`
  );
}

/**
 * Create a mutation action that sends JSON instead of FormData.
 * Useful for programmatic mutations where you want type-safe input.
 *
 * @param loaderPath - The loader path (e.g., "users/[id]")
 * @param mutationName - The mutation method name (defaults to "mutate")
 * @returns A Solid Router action that accepts a typed object
 *
 * @example
 * const updateAction = createJsonMutation<UpdateParams>("users/[id]", "update");
 *
 * // Programmatic usage:
 * const update = useAction(updateAction);
 * await update({ name: "New Name", email: "new@example.com" });
 */
export function createJsonMutation<TInput = Record<string, unknown>, TResult = unknown>(
  loaderPath: string,
  mutationName: string = "mutate"
) {
  return action(
    async (input: TInput): Promise<MutationResult<TResult>> => {
      const railsBaseUrl = getRailsBaseUrl();
      const url = new URL(
        `/_reactive_view/loaders/${loaderPath}/mutate`,
        railsBaseUrl
      );

      url.searchParams.set("_mutation", mutationName);

      const headers: Record<string, string> = {
        Accept: "application/json",
        "Content-Type": "application/json",
        "X-Reactive-View-Client": "true",
      };

      const csrfToken = getCSRFToken();
      if (csrfToken) {
        headers["X-CSRF-Token"] = csrfToken;
      }

      const ssrCookies = getSSRCookies();
      if (ssrCookies) {
        headers["Cookie"] = ssrCookies;
      }

      const response = await fetch(url.toString(), {
        method: "POST",
        headers,
        body: JSON.stringify(input),
        credentials: "include",
      });

      let result: MutationResult<TResult>;
      try {
        result = (await parseResponseJson(response)) as MutationResult<TResult>;
      } catch {
        throw new Error(
          `Mutation failed: ${response.status} ${response.statusText}`
        );
      }

      if (result._redirect) {
        throw redirect(result._redirect, {
          revalidate: result._revalidate || [],
        });
      }

      if (!response.ok && !result.errors) {
        throw new Error(
          result.error?.toString() ||
            `Mutation failed: ${response.status} ${response.statusText}`
        );
      }

      return result;
    },
    `${loaderPath}:${mutationName}:json`
  );
}

// Re-export Solid Router action primitives for convenience
export { useAction, useSubmission, useSubmissions } from "@solidjs/router";

function isFormDataInput(input: unknown): input is FormData {
  return typeof FormData !== "undefined" && input instanceof FormData;
}

function isJsonInput(input: unknown): input is MutationJsonInput {
  return input !== null && typeof input === "object" && !Array.isArray(input);
}

async function parseResponseJson(response: Response): Promise<unknown> {
  const contentType = response.headers.get("content-type") || "";
  const bodyText = await response.text();

  if (!contentType.includes("application/json")) {
    throw new Error(
      `Expected JSON response from ${response.url}, received ${contentType || "unknown content-type"}. Body starts with: ${bodyText.slice(
        0,
        120
      )}`
    );
  }

  return JSON.parse(bodyText);
}
