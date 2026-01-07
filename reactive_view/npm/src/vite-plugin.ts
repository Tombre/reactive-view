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

import type { Plugin, ViteDevServer, HmrContext } from "vite";

export interface ReactiveViewPluginOptions {
  /**
   * Enable debug logging for HMR events and module resolution
   * @default false
   */
  debug?: boolean;
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
export function reactiveViewPlugin(
  options: ReactiveViewPluginOptions = {}
): Plugin {
  const { debug = false } = options;
  let resolvedCorePath: string | null = null;
  let viteServer: ViteDevServer | null = null;

  const log = (message: string, ...args: unknown[]) => {
    if (debug) {
      console.log(`[reactive-view] ${message}`, ...args);
    }
  };

  return {
    name: "reactive-view",
    enforce: "pre",

    /**
     * Store reference to the Vite dev server for HMR event emission
     */
    configureServer(server: ViteDevServer) {
      viteServer = server;

      // Add middleware for loader invalidation endpoint
      // Rails FileSync will POST to this endpoint when loader files change
      server.middlewares.use((req, res, next) => {
        if (
          req.method === "POST" &&
          req.url === "/__reactive_view/invalidate-loader"
        ) {
          let body = "";

          req.on("data", (chunk: Buffer) => {
            body += chunk.toString();
          });

          req.on("end", () => {
            try {
              const data = JSON.parse(body) as {
                route?: string;
                routes?: string[];
                type?: "modified" | "added" | "removed";
              };

              const routes = data.routes || (data.route ? [data.route] : []);
              const eventType = data.type || "modified";

              log(`Loader invalidation request:`, { routes, type: eventType });

              // Emit custom HMR event to all connected clients
              if (viteServer && routes.length > 0) {
                viteServer.ws.send({
                  type: "custom",
                  event: "reactive-view:loader-update",
                  data: {
                    routes,
                    type: eventType,
                    timestamp: Date.now(),
                  },
                });

                log(`Sent HMR event for routes:`, routes);
              }

              res.writeHead(200, { "Content-Type": "application/json" });
              res.end(JSON.stringify({ success: true, routes }));
            } catch (error) {
              console.error("[reactive-view] Invalidation error:", error);
              res.writeHead(400, { "Content-Type": "application/json" });
              res.end(
                JSON.stringify({
                  error: error instanceof Error ? error.message : "Unknown error",
                })
              );
            }
          });

          return;
        }

        next();
      });

      log("Development server configured with loader invalidation endpoint");
    },

    /**
     * Resolve #loaders/* imports to @reactive-view/core at runtime.
     * TypeScript will resolve types via tsconfig paths to .reactive_view/types/loaders/*
     */
    async resolveId(id: string, importer: string | undefined) {
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

        log(`Resolving ${id} from ${importer} -> ${resolvedCorePath}`);

        // Return the resolved path to the @reactive-view/core package
        return resolvedCorePath;
      }
      return null;
    },

    /**
     * Handle HMR updates for TSX files
     * Log updates in debug mode for visibility into what's being hot-reloaded
     */
    handleHotUpdate(ctx: HmrContext) {
      const { file, modules } = ctx;

      // Only log for route files (TSX in routes directory)
      if (file.includes("/routes/") && file.endsWith(".tsx")) {
        const routePath = file
          .split("/routes/")[1]
          ?.replace(/\.tsx$/, "")
          .replace(/\/index$/, "");

        log(`HMR update for route: ${routePath}`, {
          file,
          moduleCount: modules.length,
        });
      }

      // Return undefined to use default HMR behavior
      return undefined;
    },
  };
}

/**
 * Helper to manually trigger a loader invalidation from the server side.
 * This can be used in development tools or test utilities.
 *
 * @param server - Vite dev server instance
 * @param routes - Array of route paths to invalidate (e.g., ["users/index", "users/[id]"])
 * @param type - Type of change: "modified", "added", or "removed"
 */
export function invalidateLoaders(
  server: ViteDevServer,
  routes: string[],
  type: "modified" | "added" | "removed" = "modified"
): void {
  server.ws.send({
    type: "custom",
    event: "reactive-view:loader-update",
    data: {
      routes,
      type,
      timestamp: Date.now(),
    },
  });
}
