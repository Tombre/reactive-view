import { EventEmitter } from "node:events";
import { resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

class ExitSignal extends Error {
  constructor(readonly code: number | undefined) {
    super(`process.exit(${String(code)})`);
  }
}

type CliImportOptions = {
  existsSync?: (path: string) => boolean;
  spawnSync?: () => { status: number | null; error?: Error };
};

async function importCliModule(options: CliImportOptions = {}) {
  vi.resetModules();

  const spawnMock = vi.fn(() => {
    const child = new EventEmitter() as EventEmitter & {
      pid: number;
      kill: ReturnType<typeof vi.fn>;
    };
    child.pid = 1234;
    child.kill = vi.fn();
    return child;
  });

  const existsSyncMock = vi.fn((path: string) => options.existsSync?.(path) ?? true);
  const spawnSyncMock = vi.fn(
    () => options.spawnSync?.() ?? { status: 0 as number | null }
  );

  vi.doMock("node:child_process", () => ({
    spawn: spawnMock,
    spawnSync: spawnSyncMock,
  }));

  vi.doMock("node:fs", () => ({
    existsSync: existsSyncMock,
  }));

  const module = await import("../src/cli");
  return { module, spawnMock, spawnSyncMock, existsSyncMock };
}

describe("reactiveview cli", () => {
  beforeEach(() => {
    vi.spyOn(process, "on").mockImplementation((() => process) as any);
    vi.spyOn(process, "exit").mockImplementation(((code?: number) => {
      throw new ExitSignal(code);
    }) as never);
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(console, "error").mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete process.env.PORT;
  });

  it("prints version and exits 0", async () => {
    const { module } = await importCliModule();

    expect(() => module.run(["--version"])).toThrowError(new ExitSignal(0));
    expect(console.log).toHaveBeenCalledWith("reactiveview v0.1.0");
  });

  it("prints help and exits 1 when command is missing", async () => {
    const { module } = await importCliModule();

    expect(() => module.run([])).toThrowError(new ExitSignal(1));
    expect(console.log).toHaveBeenCalled();
  });

  it("rejects unknown commands", async () => {
    const { module } = await importCliModule();

    expect(() => module.run(["shipit"])).toThrowError(new ExitSignal(1));
    expect(console.error).toHaveBeenCalledWith("Unknown command: shipit\n");
  });

  it("runs setup automatically when .reactive_view is missing", async () => {
    const cwd = process.cwd();
    const workingDir = resolve(cwd, ".reactive_view");
    const configPath = resolve(workingDir, "app.config.ts");

    let setupCompleted = false;

    const { module, spawnMock, spawnSyncMock } = await importCliModule({
      existsSync: (path) => {
        if (path === workingDir || path === configPath) {
          return setupCompleted;
        }

        return true;
      },
      spawnSync: () => {
        setupCompleted = true;
        return { status: 0 };
      },
    });

    module.run(["dev"]);

    expect(spawnSyncMock).toHaveBeenCalledWith(
      "bundle",
      ["exec", "rails", "reactive_view:setup"],
      expect.objectContaining({ cwd: process.cwd() })
    );
    expect(spawnMock).toHaveBeenCalled();
    expect(console.log).toHaveBeenCalledWith(
      `ReactiveView setup completed at ${workingDir}.`
    );
  });

  it("errors when setup command fails", async () => {
    const cwd = process.cwd();
    const workingDir = resolve(cwd, ".reactive_view");

    const { module } = await importCliModule({
      existsSync: (path) => path !== workingDir,
      spawnSync: () => ({ status: 1 }),
    });

    expect(() => module.run(["dev"])).toThrowError(new ExitSignal(1));
    expect(console.error).toHaveBeenCalledWith(
      'Run "bundle exec rails reactive_view:setup" manually to fix setup errors.'
    );
  });

  it("errors when app.config.ts is missing", async () => {
    const cwd = process.cwd();
    const workingDir = resolve(cwd, ".reactive_view");
    const configPath = resolve(workingDir, "app.config.ts");

    const { module } = await importCliModule({
      existsSync: (path) => path !== configPath,
    });

    expect(() => module.run(["dev"])).toThrowError(new ExitSignal(1));
    expect(console.error).toHaveBeenCalledWith(
      `Error: SolidStart config not found at ${configPath}`
    );
  });

  it("spawns vinxi dev with PORT fallback and passthrough args", async () => {
    process.env.PORT = "4555";
    const { module, spawnMock } = await importCliModule();

    module.run(["dev", "--host", "0.0.0.0"]);

    expect(spawnMock).toHaveBeenCalledWith(
      "npx",
      [
        "vinxi",
        "dev",
        "--config",
        ".reactive_view/app.config.ts",
        "--host",
        "0.0.0.0",
        "--port",
        "4555",
      ],
      expect.objectContaining({
        cwd: process.cwd(),
        stdio: "inherit",
        env: expect.objectContaining({ PORT: "4555" }),
      })
    );
  });

  it("spawns vinxi start with explicit --port", async () => {
    const { module, spawnMock } = await importCliModule();

    module.run(["start", "--port", "4002"]);

    expect(spawnMock).toHaveBeenCalledWith(
      "npx",
      [
        "vinxi",
        "start",
        "--config",
        ".reactive_view/app.config.ts",
        "--port",
        "4002",
      ],
      expect.objectContaining({
        env: expect.objectContaining({ PORT: "4002" }),
      })
    );
  });

  it("exits with child close code", async () => {
    const { module, spawnMock } = await importCliModule();

    module.run(["build"]);
    const child = spawnMock.mock.results[0]?.value as EventEmitter;
    expect(child).toBeTruthy();

    expect(() => {
      child.emit("close", 0);
    }).toThrowError(new ExitSignal(0));
  });

  it("exits 1 when child emits an error", async () => {
    const { module, spawnMock } = await importCliModule();

    module.run(["build"]);
    const child = spawnMock.mock.results[0]?.value as EventEmitter;

    expect(() => {
      child.emit("error", new Error("boom"));
    }).toThrowError(new ExitSignal(1));
    expect(console.error).toHaveBeenCalledWith("Failed to start: boom");
  });
});
