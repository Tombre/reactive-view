import { defineConfig } from "@solidjs/start/config";

export default defineConfig({
  server: {
    // Preset for Node.js server
    preset: "node-server",
  },
  // Allow cross-origin requests from Rails
  vite: {
    server: {
      cors: true,
    },
  },
});
