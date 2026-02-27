// ReactiveView SolidStart Configuration
// User configuration is loaded from ../reactive_view.config.ts (Rails root)

import { defineConfig as solidStartDefineConfig } from "@solidjs/start/config";
import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";
import type { ReactiveViewConfig } from "@reactive-view/core/config";
import { resolve } from "node:path";

// Load user config from Rails root (dynamic import with fallback)
let userConfig: ReactiveViewConfig = {};
try {
  const module = await import("../reactive_view.config.ts");
  userConfig = module.default || {};
} catch {
  // No user config found - use defaults
}

// Compute pages path — points to app/pages in the Rails root
const pagesPath = resolve(process.cwd(), "../app/pages");

export default solidStartDefineConfig({
  server: {
    preset: "node-server",
  },
  vite: {
    plugins: [
      reactiveViewPlugin({
        ...(userConfig.reactiveView || {}),
        pagesPath,
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
