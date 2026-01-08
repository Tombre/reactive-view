import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/pages/**/*.{ts,tsx}",
    "./.reactive_view/src/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};

export default config;
