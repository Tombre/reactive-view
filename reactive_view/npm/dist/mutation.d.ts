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
export declare function createMutation<TResult = unknown>(loaderPath: string, mutationName?: string): import("@solidjs/router").Action<[formData: FormData], MutationResult<TResult>, [formData: FormData]>;
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
export declare function createJsonMutation<TInput = Record<string, unknown>, TResult = unknown>(loaderPath: string, mutationName?: string): import("@solidjs/router").Action<[input: TInput], MutationResult<TResult>, [input: TInput]>;
export { useAction, useSubmission, useSubmissions } from "@solidjs/router";
//# sourceMappingURL=mutation.d.ts.map