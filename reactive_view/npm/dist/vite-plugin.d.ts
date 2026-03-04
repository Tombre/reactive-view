/**
 * ReactiveView Vite Plugin
 *
 * This plugin provides:
 * 1. Resolution of `#loaders/*` imports to `@reactive-view/core` at runtime
 * 2. HMR support for loader file changes via custom events
 * 3. Development server middleware for loader invalidation
 *
 * @example
 * ```ts
 * // app.config.ts
 * import { defineConfig } from "@solidjs/start/config";
 * import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";
 *
 * export default defineConfig({
 *   vite: {
 *     plugins: [reactiveViewPlugin()],
 *   },
 * });
 * ```
 */
import type { Plugin, ViteDevServer } from "vite";
export interface ReactiveViewPluginOptions {
    /**
     * Enable debug logging for HMR events and module resolution
     * @default false
     */
    debug?: boolean;
    /**
     * Absolute path to the pages directory (e.g., Rails.root/app/pages).
     * When set, a Vite alias `~pages` is registered so route wrappers can
     * import user source files directly instead of requiring copies.
     */
    pagesPath?: string;
    /**
     * Absolute path to generated loader type files
     * (e.g., Rails.root/.reactive_view/types/loaders).
     */
    loaderTypesPath?: string;
}
/**
 * Vite plugin for ReactiveView that provides:
 * - Resolution of #loaders/* imports to @reactive-view/core
 * - HMR event emission for loader file changes
 * - Development middleware for triggering loader invalidation
 *
 * @param options - Plugin options
 * @returns Vite plugin
 */
export declare function reactiveViewPlugin(options?: ReactiveViewPluginOptions): Plugin;
/**
 * Helper to manually trigger a loader invalidation from the server side.
 * This can be used in development tools or test utilities.
 *
 * @param server - Vite dev server instance
 * @param routes - Array of route paths to invalidate (e.g., ["users/index", "users/[id]"])
 * @param type - Type of change: "modified", "added", or "removed"
 */
export declare function invalidateLoaders(server: ViteDevServer, routes: string[], type?: "modified" | "added" | "removed"): void;
//# sourceMappingURL=vite-plugin.d.ts.map