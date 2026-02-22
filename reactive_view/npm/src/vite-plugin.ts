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

import { posix as pathPosix, resolve as pathResolve } from "node:path";
import type { Plugin, ViteDevServer, HmrContext } from "vite";

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
}

const DEFAULT_HMR_WEBSOCKET_PATH = "/@vite/ws";
const PAGES_FILE_PATTERN = /[\\/](?:src[\\/]pages|app[\\/]pages)[\\/].+\.(tsx|ts)$/;
const ROUTE_FILE_PATTERN = /[\\/]src[\\/]routes[\\/].+\.tsx$/;

function normalizeBasePath(base?: string): string {
  if (!base || base === "") {
    return "/";
  }
  if (!base.startsWith("/")) {
    return `/${base}`;
  }
  return base;
}

function computeRelativeHmrPath(base: string): string {
  const relative = pathPosix.relative(base, DEFAULT_HMR_WEBSOCKET_PATH);
  if (!relative || relative === ".") {
    return DEFAULT_HMR_WEBSOCKET_PATH;
  }
  return relative;
}

function isDefaultHmrPath(pathValue?: string): boolean {
  if (!pathValue) {
    return true;
  }
  const normalized = pathValue.trim().replace(/\/+$/, "");
  const defaultNoSlash = DEFAULT_HMR_WEBSOCKET_PATH.replace(/\/+$/, "");
  return (
    normalized === defaultNoSlash ||
    normalized === defaultNoSlash.slice(1)
  );
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
     * Register resolve aliases and filesystem access rules.
     * In development, maps `~pages` to the Rails app/pages directory so
     * route wrappers can import user source files directly (no file copy).
     */
    config(_userConfig, { command }) {
      if (options.pagesPath) {
        const isDev = command === "serve";
        const pagesAlias = { find: "~pages", replacement: options.pagesPath };

        return {
          resolve: {
            alias: isDev ? [pagesAlias] : [],
          },
          server: {
            fs: {
              // Allow Vite to read files from the Rails root (parent of .reactive_view)
              allow: [
                process.cwd(),
                pathResolve(process.cwd(), ".."),
              ],
            },
          },
        };
      }
      return {};
    },

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

    configResolved(config) {
      const base = normalizeBasePath(config.base as string | undefined);
      const serverConfig = config.server;

      if (serverConfig.hmr === false) {
        return;
      }

      const existingHmr =
        typeof serverConfig.hmr === "object" && serverConfig.hmr !== null
          ? { ...serverConfig.hmr }
          : {};

      const currentPath =
        typeof existingHmr.path === "string" ? existingHmr.path : undefined;

      if (isDefaultHmrPath(currentPath)) {
        const resolvedPath = computeRelativeHmrPath(base);
        if (currentPath !== resolvedPath) {
          log(
            `Normalized Vite HMR path for base ${base} -> ${resolvedPath}`
          );
        }
        existingHmr.path = resolvedPath;
      }

      const isMiddlewareMode = Boolean(serverConfig.middlewareMode);
      if (
        isMiddlewareMode &&
        typeof existingHmr.port !== "number" &&
        typeof existingHmr.clientPort === "number"
      ) {
        log("Removed clientPort override to allow middleware HMR fallback");
        delete existingHmr.clientPort;
      }

      serverConfig.hmr = existingHmr;
    },

    /**
     * Resolve #loaders/* imports to the generated loader type files.
     * These files contain route-specific preloadData() and useLoaderData() functions.
     *
     * For example:
     * - #loaders/users/index -> ./types/loaders/users/index.ts
     * - #loaders/users/[id] -> ./types/loaders/users/[id].ts
     */
    async resolveId(id: string, importer: string | undefined) {
      if (id.startsWith("#loaders/")) {
        // Extract the route path from the import
        const routePath = id.slice("#loaders/".length);

        // Build the absolute path to the generated loader file
        // The types/loaders directory is at the root of the .reactive_view project
        const loaderPath = pathResolve(process.cwd(), `types/loaders/${routePath}.ts`);

        log(`Resolving ${id} from ${importer} -> ${loaderPath}`);

        // Return the absolute resolved path to the generated loader type file
        return loaderPath;
      }
      return null;
    },

    /**
     * Handle HMR updates for TSX files
     * Log updates in debug mode for visibility into what's being hot-reloaded
     */
    handleHotUpdate(ctx: HmrContext) {
      const { file, modules } = ctx;

      if (PAGES_FILE_PATTERN.test(file)) {
        const [_, pagePart] = file.split(/[\\/](?:src|app)[\\/]pages[\\/]/);
        const componentPath = pagePart?.replace(/\.(tsx|ts)$/, "");

        log(`HMR update for page component: ${componentPath}`, {
          file,
          moduleCount: modules.length,
        });

        return undefined;
      }

      if (ROUTE_FILE_PATTERN.test(file)) {
        log(`Route wrapper change detected (structure update): ${file}`);
        return undefined;
      }

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
