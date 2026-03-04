/**
 * Map of loader paths to their return types.
 * This interface is augmented by the generated types file (.reactive_view/types/loader-data.d.ts)
 *
 * @example
 * ```typescript
 * // Generated types will look like:
 * declare module "@reactive-view/core" {
 *   interface LoaderDataMap {
 *     "users/index": { users: User[]; total: number };
 *     "users/[id]": { user: User };
 *   }
 * }
 * ```
 */
export interface LoaderDataMap {
}
/**
 * Helper type to get the loader data type for a specific route.
 *
 * @example
 * ```typescript
 * type UserData = LoaderData<"users/[id]">;
 * // { user: { id: number; name: string } }
 * ```
 */
export type LoaderData<T extends keyof LoaderDataMap> = LoaderDataMap[T];
/**
 * Check if a route path has generated loader types.
 */
export type HasLoaderData<T extends string> = T extends keyof LoaderDataMap ? true : false;
//# sourceMappingURL=index.d.ts.map