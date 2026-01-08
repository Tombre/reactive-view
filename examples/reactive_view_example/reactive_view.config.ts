import { defineConfig } from "@reactive-view/core/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  vitePlugins: [tailwindcss()],
});
