// ReactiveView SolidStart Configuration
// User configuration is loaded from ../reactive_view.config.ts (Rails root)

import { defineConfig as solidStartDefineConfig } from "@solidjs/start/config";
import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";
import type { ReactiveViewConfig } from "@reactive-view/core/config";
import { resolve } from "node:path";

// Load user config from Rails root.
// This path resolves from .reactive_view/app.config.ts -> ../reactive_view.config.ts
let userConfig: ReactiveViewConfig = {};
try {
  const module = await import("../reactive_view.config.ts");
  userConfig = module.default || {};
} catch {
  // Missing or invalid user config - use defaults
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
