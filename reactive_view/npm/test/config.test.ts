import { describe, expect, it } from "vitest";
import { defineConfig } from "../src/config";

describe("defineConfig", () => {
  it("returns an empty config by default", () => {
    expect(defineConfig()).toEqual({});
  });

  it("returns the provided object unchanged", () => {
    const config = {
      vitePlugins: [{ name: "test-plugin" }],
      vite: { base: "/app" },
      reactiveView: { debug: true },
    };

    expect(defineConfig(config)).toBe(config);
  });
});
