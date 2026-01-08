/**
 * ReactiveView Configuration
 * 
 * Use defineConfig to configure your ReactiveView frontend.
 * Place this in reactive_view.config.ts at your Rails root.
 * 
 * @example
 * ```ts
 * import { defineConfig } from "@reactive-view/core/config";
 * import tailwindcss from "@tailwindcss/vite";
 * 
 * export default defineConfig({
 *   vitePlugins: [tailwindcss()],
 * });
 * ```
 */

import type { Plugin, PluginOption } from "vite";

export interface ReactiveViewConfig {
  /**
   * Additional Vite plugins (e.g., Tailwind, SCSS, etc.)
   * Can be a single plugin, array of plugins, or nested arrays
   */
  vitePlugins?: PluginOption[];
  
  /**
   * Additional Vite configuration to merge
   */
  vite?: Record<string, unknown>;
  
  /**
   * ReactiveView plugin options
   */
  reactiveView?: {
    debug?: boolean;
  };
}

/**
 * Define ReactiveView configuration.
 * 
 * @param config - Configuration options
 * @returns The configuration object
 */
export function defineConfig(config: ReactiveViewConfig = {}): ReactiveViewConfig {
  return config;
}
