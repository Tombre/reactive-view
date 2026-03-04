import { action, redirect } from "@solidjs/router";
import { isServer } from "solid-js/web";
import { getCSRFToken } from "./csrf.js";
import { getSSRRequestContext } from "./request-context.js";
// ============================================================================
// Shared Utilities (same as loader.ts)
// ============================================================================
/**
 * Get the Rails base URL from environment or globals
 */
function getRailsBaseUrl() {
    if (isServer) {
        const { railsBaseUrl } = getSSRRequestContext();
        if (railsBaseUrl)
            return railsBaseUrl;
        const globalRailsUrl = globalThis.__RAILS_BASE_URL__;
        if (globalRailsUrl)
            return globalRailsUrl;
        try {
            const envUrl = globalThis.process?.env?.RAILS_BASE_URL;
            if (envUrl)
                return envUrl;
        }
        catch {
            // Ignore - process.env not available
        }
        return "http://localhost:3000";
    }
    const clientRailsUrl = window.__RAILS_BASE_URL__;
    if (clientRailsUrl)
        return clientRailsUrl;
    return window.location.origin;
}
/**
 * Get cookies for SSR requests (forwarded from Rails)
 */
function getSSRCookies() {
    if (isServer) {
        const { cookies } = getSSRRequestContext();
        if (cookies)
            return cookies;
        return globalThis.__REACTIVE_VIEW_COOKIES__;
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
 * // Programmatic usage:
 * const update = useAction(updateAction);
 * await update(new FormData(formElement));
 */
export function createMutation(loaderPath, mutationName = "mutate") {
    return action(async (formData) => {
        const railsBaseUrl = getRailsBaseUrl();
        const url = new URL(`/_reactive_view/loaders/${loaderPath}/mutate`, railsBaseUrl);
        // Add mutation name as query param
        url.searchParams.set("_mutation", mutationName);
        // Build headers
        const headers = {
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
        const response = await fetch(url.toString(), {
            method: "POST",
            headers,
            body: formData,
            credentials: "include",
        });
        // Parse the response
        let result;
        try {
            result = (await parseResponseJson(response));
        }
        catch {
            throw new Error(`Mutation failed: ${response.status} ${response.statusText}`);
        }
        // Handle redirect responses from the server
        if (result._redirect) {
            throw redirect(result._redirect, {
                revalidate: result._revalidate || [],
            });
        }
        // For non-redirect errors, check HTTP status
        if (!response.ok && !result.errors) {
            throw new Error(result.error?.toString() ||
                `Mutation failed: ${response.status} ${response.statusText}`);
        }
        return result;
    }, `${loaderPath}:${mutationName}`);
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
export function createJsonMutation(loaderPath, mutationName = "mutate") {
    return action(async (input) => {
        const railsBaseUrl = getRailsBaseUrl();
        const url = new URL(`/_reactive_view/loaders/${loaderPath}/mutate`, railsBaseUrl);
        url.searchParams.set("_mutation", mutationName);
        const headers = {
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
        let result;
        try {
            result = (await parseResponseJson(response));
        }
        catch {
            throw new Error(`Mutation failed: ${response.status} ${response.statusText}`);
        }
        if (result._redirect) {
            throw redirect(result._redirect, {
                revalidate: result._revalidate || [],
            });
        }
        if (!response.ok && !result.errors) {
            throw new Error(result.error?.toString() ||
                `Mutation failed: ${response.status} ${response.statusText}`);
        }
        return result;
    }, `${loaderPath}:${mutationName}:json`);
}
// Re-export Solid Router action primitives for convenience
export { useAction, useSubmission, useSubmissions } from "@solidjs/router";
async function parseResponseJson(response) {
    const contentType = response.headers.get("content-type") || "";
    const bodyText = await response.text();
    if (!contentType.includes("application/json")) {
        throw new Error(`Expected JSON response from ${response.url}, received ${contentType || "unknown content-type"}. Body starts with: ${bodyText.slice(0, 120)}`);
    }
    return JSON.parse(bodyText);
}
