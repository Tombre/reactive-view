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
      // HMR configuration
      // When accessing via Rails proxy (port 3000), the browser needs to connect
      // directly to Vite (port 3001) for HMR WebSocket.
      //
      // Important: We must specify protocol, host, and port explicitly because
      // Vinxi uses /_build/ as base URL, but the WebSocket server listens at root.
      // Without explicit configuration, the browser would try to connect to
      // ws://localhost:3001/_build/ instead of ws://localhost:3001/
      hmr: {
        // Use WebSocket protocol (not secure since we're on localhost)
        protocol: "ws",
        // Connect to localhost for HMR WebSocket
        host: "localhost",
        // The Vite dev server port (not the Rails proxy port)
        clientPort: 3001,
        // Force WebSocket path to the root (avoid /_build/ prefix)
        path: "/@vite/ws",
        // Show error overlay for HMR failures
        overlay: true,
      },
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
