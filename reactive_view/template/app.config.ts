// ReactiveView SolidStart Configuration
// User configuration is loaded from ../reactive_view.config.ts (Rails root)

import { defineConfig as solidStartDefineConfig } from "@solidjs/start/config";
import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";
import type { ReactiveViewConfig } from "@reactive-view/core/config";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

// Load user config from Rails root (dynamic import with fallback)
let userConfig: ReactiveViewConfig = {};
const userConfigPath = resolve(process.cwd(), "reactive_view.config.ts");

try {
  if (existsSync(userConfigPath)) {
    const module = await import(pathToFileURL(userConfigPath).href);
    userConfig = module.default || {};
  }
} catch {
  // No user config found - use defaults
}

// Compute pages path — points to app/pages in the Rails root
const pagesPath = resolve(process.cwd(), "app/pages");
const loaderTypesPath = resolve(process.cwd(), ".reactive_view/types/loaders");

export default solidStartDefineConfig({
  appRoot: "./.reactive_view/src",
  routeDir: "./routes",
  server: {
    preset: "node-server",
    output: {
      dir: ".reactive_view/.output",
      serverDir: ".reactive_view/.output/server",
      publicDir: ".reactive_view/.output/public",
    },
  },
  vite: {
    plugins: [
        reactiveViewPlugin({
          ...(userConfig.reactiveView || {}),
          pagesPath,
          loaderTypesPath,
        }),
      ...(userConfig.vitePlugins || []),
    ],
    server: {
      cors: true,
      strictPort: true,
    },
    resolve: {
      dedupe: ["solid-js", "@solidjs/router", "@solidjs/start"],
    },
    optimizeDeps: {
      include: ["solid-js", "@solidjs/router"],
    },
    ...(userConfig.vite || {}),
  },
});
