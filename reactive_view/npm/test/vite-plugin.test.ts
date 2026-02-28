import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { EventEmitter } from "node:events";
import { afterEach, describe, expect, it, vi } from "vitest";
import { invalidateLoaders, reactiveViewPlugin } from "../src/vite-plugin";

describe("reactiveViewPlugin", () => {
  const tempDirs: string[] = [];

  afterEach(() => {
    vi.restoreAllMocks();
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it("registers ~pages alias and fs allowlist when pagesPath is provided", () => {
    const plugin = reactiveViewPlugin({ pagesPath: "/rails/app/pages" });
    const configResult = plugin.config?.({}, { command: "serve", mode: "development" });

    expect(configResult).toEqual({
      resolve: {
        alias: [{ find: "~pages", replacement: "/rails/app/pages" }],
      },
      server: {
        fs: {
          allow: [process.cwd()],
        },
      },
    });
  });

  it("handles loader invalidation middleware requests", () => {
    const wsSend = vi.fn();
    let middleware: ((req: any, res: any, next: () => void) => void) | undefined;

    const plugin = reactiveViewPlugin();
    plugin.configureServer?.({
      ws: { send: wsSend },
      middlewares: {
        use(fn: (req: any, res: any, next: () => void) => void) {
          middleware = fn;
        },
      },
    } as any);

    const req = new EventEmitter() as any;
    req.method = "POST";
    req.url = "/__reactive_view/invalidate-loader";

    const res = {
      writeHead: vi.fn(),
      end: vi.fn(),
    };

    middleware?.(req, res, vi.fn());
    req.emit("data", Buffer.from('{"routes":["users/index"],"type":"modified"}'));
    req.emit("end");

    expect(wsSend).toHaveBeenCalledWith(
      expect.objectContaining({
        type: "custom",
        event: "reactive-view:loader-update",
        data: expect.objectContaining({
          routes: ["users/index"],
          type: "modified",
        }),
      })
    );
    expect(res.writeHead).toHaveBeenCalledWith(200, {
      "Content-Type": "application/json",
    });
    expect(res.end).toHaveBeenCalledWith(
      expect.stringContaining('"success":true')
    );
  });

  it("returns 400 for invalid middleware payload", () => {
    let middleware: ((req: any, res: any, next: () => void) => void) | undefined;

    const plugin = reactiveViewPlugin();
    plugin.configureServer?.({
      ws: { send: vi.fn() },
      middlewares: {
        use(fn: (req: any, res: any, next: () => void) => void) {
          middleware = fn;
        },
      },
    } as any);

    const req = new EventEmitter() as any;
    req.method = "POST";
    req.url = "/__reactive_view/invalidate-loader";

    const res = {
      writeHead: vi.fn(),
      end: vi.fn(),
    };

    middleware?.(req, res, vi.fn());
    req.emit("data", Buffer.from("not-json"));
    req.emit("end");

    expect(res.writeHead).toHaveBeenCalledWith(400, {
      "Content-Type": "application/json",
    });
    expect(res.end).toHaveBeenCalledWith(expect.stringContaining("error"));
  });

  it("normalizes default HMR path for non-root base and strips middleware clientPort", () => {
    const plugin = reactiveViewPlugin({ debug: true });
    const config: any = {
      base: "/app/",
      server: {
        middlewareMode: true,
        hmr: {
          path: "/@vite/ws",
          clientPort: 24678,
        },
      },
    };

    plugin.configResolved?.(config);

    expect(config.server.hmr.path).toBe("../@vite/ws");
    expect(config.server.hmr.clientPort).toBeUndefined();
  });

  it("resolves #loaders imports to generated .tsx files", async () => {
    const tempDir = mkdtempSync(join(tmpdir(), "rv-loaders-"));
    tempDirs.push(tempDir);

    const nestedDir = join(tempDir, "users");
    mkdirSync(nestedDir, { recursive: true });
    writeFileSync(join(nestedDir, "index.tsx"), "export const x = 1;\n", "utf8");

    const plugin = reactiveViewPlugin({ loaderTypesPath: tempDir });
    const resolved = await plugin.resolveId?.("#loaders/users/index", "/tmp/importer.tsx");

    expect(resolved).toBe(join(tempDir, "users/index.tsx"));
  });

  it("falls back to .ts when .tsx loader type file does not exist", async () => {
    const tempDir = mkdtempSync(join(tmpdir(), "rv-loaders-"));
    tempDirs.push(tempDir);

    const nestedDir = join(tempDir, "users");
    mkdirSync(nestedDir, { recursive: true });
    writeFileSync(join(nestedDir, "show.ts"), "export const x = 1;\n", "utf8");

    const plugin = reactiveViewPlugin({ loaderTypesPath: tempDir });
    const resolved = await plugin.resolveId?.("#loaders/users/show", "/tmp/importer.tsx");

    expect(resolved).toBe(join(tempDir, "users/show.ts"));
  });

  it("ignores non-loader imports", async () => {
    const plugin = reactiveViewPlugin();
    await expect(plugin.resolveId?.("./local-module", "/tmp/importer.ts")).resolves.toBeNull();
  });
});

describe("invalidateLoaders", () => {
  it("sends the expected custom HMR payload", () => {
    const send = vi.fn();

    invalidateLoaders(
      {
        ws: { send },
      } as any,
      ["users/index", "users/[id]"],
      "removed"
    );

    expect(send).toHaveBeenCalledWith(
      expect.objectContaining({
        type: "custom",
        event: "reactive-view:loader-update",
        data: expect.objectContaining({
          routes: ["users/index", "users/[id]"],
          type: "removed",
        }),
      })
    );
  });
});
