import { defineConfig } from "@solidjs/start/config";
import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";

export default defineConfig({
  server: {
    // Preset for Node.js server
    preset: "node-server",
  },
  vite: {
    plugins: [
      // ReactiveView plugin handles:
      // - #loaders/* import resolution
      // - Loader file change notifications for HMR
      // - Development debugging (set debug: true for verbose logging)
      reactiveViewPlugin({
        debug: process.env.REACTIVE_VIEW_DEBUG === "true",
      }),
    ],
    server: {
      // Allow cross-origin requests from Rails
      cors: true,
    },
    resolve: {
      // Ensure shared dependencies are resolved from this project's node_modules
      // This prevents duplicate module issues with @reactive-view/core
      dedupe: ["solid-js", "@solidjs/router", "@solidjs/start"],
    },
    // Optimize dependency pre-bundling for faster cold starts
    optimizeDeps: {
      include: ["solid-js", "@solidjs/router"],
    },
  },
});
