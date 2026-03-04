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
export declare function getCSRFToken(): string | null;
/**
 * Get the CSRF parameter name (typically "authenticity_token" in Rails)
 * @returns The parameter name or null if not available
 */
export declare function getCSRFParam(): string;
//# sourceMappingURL=csrf.d.ts.map