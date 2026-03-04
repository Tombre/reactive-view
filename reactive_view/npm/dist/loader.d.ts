import { type Resource } from "solid-js";
import type { LoaderDataMap } from "./types";
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
export declare function createLoaderQuery<T>(loaderPath: string): (params: Record<string, string>) => Promise<T>;
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
export declare function useLoaderData<T>(): Resource<T>;
export declare function useLoaderData<R extends keyof LoaderDataMap>(route: R, params?: Record<string, string>): Resource<LoaderDataMap[R]>;
export declare function useLoaderData<T>(route: string, params?: Record<string, string>): Resource<T>;
//# sourceMappingURL=loader.d.ts.map