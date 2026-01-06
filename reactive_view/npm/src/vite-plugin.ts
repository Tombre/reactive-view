/**
 * ReactiveView Vite Plugin
 *
 * This plugin resolves `#loaders/*` imports to `@reactive-view/core` at runtime.
 * TypeScript resolves types via tsconfig paths, while this plugin ensures the
 * runtime import works correctly.
 *
 * @example
 * ```ts
 * // app.config.ts
 * import { defineConfig } from "@solidjs/start/config";
 * import { reactiveViewPlugin } from "@reactive-view/core";
 *
 * export default defineConfig({
 *   vite: {
 *     plugins: [reactiveViewPlugin()],
 *   },
 * });
 * ```
 */

import type { Plugin } from "vite";

export interface ReactiveViewPluginOptions {
  /**
   * Enable debug logging
   * @default false
   */
  debug?: boolean;
}

/**
 * Vite plugin for ReactiveView that resolves #loaders/* imports.
 *
 * The plugin intercepts imports like `#loaders/users/index` and resolves them
 * to `@reactive-view/core` at runtime. TypeScript types are provided by
 * generated files in `.reactive_view/types/loaders/`.
 *
 * @param options - Plugin options
 * @returns Vite plugin
 */
export function reactiveViewPlugin(options: ReactiveViewPluginOptions = {}): Plugin {
  const { debug = false } = options;
  let resolvedCorePath: string | null = null;

  return {
    name: "reactive-view",
    enforce: "pre",

    async resolveId(id: string, importer: string | undefined) {
      // Resolve #loaders/* imports to @reactive-view/core at runtime
      // TypeScript will resolve types via tsconfig paths to .reactive_view/types/loaders/*
      if (id.startsWith("#loaders/")) {
        // Resolve @reactive-view/core to its actual path (cache for performance)
        if (!resolvedCorePath) {
          const resolved = await this.resolve("@reactive-view/core", importer, {
            skipSelf: true,
          });
          if (resolved) {
            resolvedCorePath = resolved.id;
          }
        }

        if (debug) {
          console.log(`[reactive-view] Resolving ${id} from ${importer} -> ${resolvedCorePath}`);
        }

        // Return the resolved path to the @reactive-view/core package
        return resolvedCorePath;
      }
      return null;
    },
  };
}
