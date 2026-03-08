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
 * // Programmatic usage with FormData:
 * const update = useAction(updateAction);
 * await update(new FormData(formElement));
 *
 * @example
 * // Programmatic usage with JSON:
 * const update = useAction(updateAction);
 * await update({ name: "New Name", email: "new@example.com" });
 */
export function createMutation(loaderPath, mutationName = "mutate") {
    return action(async (input) => {
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
        let body;
        if (isFormDataInput(input)) {
            body = input;
        }
        else if (isJsonInput(input)) {
            headers["Content-Type"] = "application/json";
            body = JSON.stringify(input);
        }
        else {
            throw new Error("Mutation input must be FormData or a JSON object");
        }
        const response = await fetch(url.toString(), {
            method: "POST",
            headers,
            body,
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
// Re-export Solid Router action primitives for convenience
export { useAction, useSubmission, useSubmissions } from "@solidjs/router";
function isFormDataInput(input) {
    return typeof FormData !== "undefined" && input instanceof FormData;
}
function isJsonInput(input) {
    return input !== null && typeof input === "object" && !Array.isArray(input);
}
async function parseResponseJson(response) {
    const contentType = response.headers.get("content-type") || "";
    const bodyText = await response.text();
    if (!contentType.includes("application/json")) {
        throw new Error(`Expected JSON response from ${response.url}, received ${contentType || "unknown content-type"}. Body starts with: ${bodyText.slice(0, 120)}`);
    }
    return JSON.parse(bodyText);
}
