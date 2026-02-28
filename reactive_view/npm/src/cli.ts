/**
 * ReactiveView CLI
 *
 * Provides `reactiveview dev`, `reactiveview build`, and `reactiveview start` commands
 * that run the SolidStart/Vinxi toolchain from the .reactive_view working directory.
 *
 * Usage:
 *   reactiveview dev     - Start the development server (vinxi dev)
 *   reactiveview build   - Build for production (vinxi build)
 *   reactiveview start   - Start the production server (vinxi start)
 *
 * @example package.json
 * ```json
 * {
 *   "scripts": {
 *     "dev": "reactiveview dev",
 *     "build": "reactiveview build",
 *     "start": "reactiveview start"
 *   }
 * }
 * ```
 */

import { spawn } from "node:child_process";
import { existsSync, cpSync, rmSync, mkdirSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

const WORKING_DIR = ".reactive_view";
const DEFAULT_DEV_PORT = "3001";
const VERSION = "0.1.0";

const COMMANDS: Record<string, { description: string; script: string }> = {
  dev: {
    description: "Start the development server",
    script: "dev",
  },
  build: {
    description: "Build for production",
    script: "build",
  },
  start: {
    description: "Start the production server",
    script: "start",
  },
};

/**
 * Print usage information.
 */
function printHelp(): void {
  console.log(`
  reactiveview v${VERSION}

  Usage:
    reactiveview <command> [options]

  Commands:
    dev       Start the development server (vinxi dev)
    build     Build for production (vinxi build)
    start     Start the production server (vinxi start)

  Options:
    --port <number>   Port for the dev server (default: ${DEFAULT_DEV_PORT})
    --help, -h        Show this help message
    --version, -v     Show version number

  Examples:
    reactiveview dev
    reactiveview dev --port 3002
    reactiveview build
    reactiveview start
`);
}

/**
 * Parse CLI arguments into a command and options.
 */
function parseArgs(argv: string[]): {
  command: string | undefined;
  port: string | undefined;
  help: boolean;
  version: boolean;
  passthrough: string[];
} {
  let command: string | undefined;
  let port: string | undefined;
  let help = false;
  let version = false;
  const passthrough: string[] = [];

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];

    if (arg === "--help" || arg === "-h") {
      help = true;
    } else if (arg === "--version" || arg === "-v") {
      version = true;
    } else if (arg === "--port" && i + 1 < argv.length) {
      port = argv[++i];
    } else if (arg.startsWith("--port=")) {
      port = arg.split("=")[1];
    } else if (!arg.startsWith("-") && !command) {
      command = arg;
    } else {
      passthrough.push(arg);
    }
  }

  return { command, port, help, version, passthrough };
}

/**
 * Sync page files from app/pages to .reactive_view/src/pages for production builds.
 *
 * In development, Vite reads directly from app/pages via the ~pages alias.
 * For production builds, files must be copied into the working directory so
 * the build is self-contained.
 *
 * @param workingDir - Absolute path to .reactive_view directory
 * @param pagesDir - Absolute path to app/pages directory
 */
function syncPagesForBuild(workingDir: string, pagesDir: string): void {
  if (!existsSync(pagesDir)) {
    console.error(`Error: Pages directory not found at ${pagesDir}`);
    process.exit(1);
  }

  const destDir = resolve(workingDir, "src", "pages");

  // Clean and recreate destination
  if (existsSync(destDir)) {
    rmSync(destDir, { recursive: true });
  }
  mkdirSync(destDir, { recursive: true });

  // Copy all files except .loader.rb files
  copyDirRecursive(pagesDir, destDir);

  console.log(`Synced pages from ${pagesDir} to ${destDir}`);
}

/**
 * Recursively copy a directory, excluding .loader.rb files.
 */
function copyDirRecursive(src: string, dest: string): void {
  const entries = readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = resolve(src, entry.name);
    const destPath = resolve(dest, entry.name);

    if (entry.isDirectory()) {
      mkdirSync(destPath, { recursive: true });
      copyDirRecursive(srcPath, destPath);
    } else if (!entry.name.endsWith(".loader.rb")) {
      cpSync(srcPath, destPath);
    }
  }
}

/**
 * Run the CLI with the given arguments.
 *
 * @param argv - Arguments from process.argv.slice(2)
 */
export function run(argv: string[]): void {
  const { command, port, help, version, passthrough } = parseArgs(argv);

  if (version) {
    console.log(`reactiveview v${VERSION}`);
    process.exit(0);
  }

  if (help || !command) {
    printHelp();
    process.exit(help ? 0 : 1);
  }

  const commandConfig = COMMANDS[command];

  if (!commandConfig) {
    console.error(`Unknown command: ${command}\n`);
    console.error(`Available commands: ${Object.keys(COMMANDS).join(", ")}`);
    console.error(`Run "reactiveview --help" for usage information.`);
    process.exit(1);
  }

  const workingDir = resolve(process.cwd(), WORKING_DIR);

  if (!existsSync(workingDir)) {
    console.error(`Error: Working directory not found at ${workingDir}`);
    console.error(``);
    console.error(`The .reactive_view directory has not been set up yet.`);
    console.error(`Run "rails reactive_view:setup" to create it.`);
    process.exit(1);
  }

  // Build the npm run command
  const args = ["run", commandConfig.script, ...passthrough];

  // For the build command, sync page files into .reactive_view/src/pages first.
  // In development, Vite reads directly from app/pages via the ~pages alias,
  // but production builds need a self-contained copy.
  if (command === "build") {
    const pagesDir = resolve(process.cwd(), "app", "pages");
    console.log("Syncing pages for production build...");
    syncPagesForBuild(workingDir, pagesDir);
  }

  // Set up environment
  const env: Record<string, string> = { ...process.env } as Record<
    string,
    string
  >;

  // For dev command, set the port via PORT env var
  if (command === "dev") {
    const devPort = port || process.env.PORT || DEFAULT_DEV_PORT;
    env.PORT = devPort;
  }

  // For start command, allow port override too
  if (command === "start" && port) {
    env.PORT = port;
  }

  const child = spawn("npm", args, {
    cwd: workingDir,
    stdio: "inherit",
    env,
    // Use shell on Windows for npm to resolve correctly
    shell: process.platform === "win32",
  });

  // Forward termination signals to child
  const signals: NodeJS.Signals[] = ["SIGTERM", "SIGINT", "SIGHUP"];

  for (const signal of signals) {
    process.on(signal, () => {
      if (child.pid) {
        child.kill(signal);
      }
    });
  }

  child.on("close", (code) => {
    process.exit(code ?? 1);
  });

  child.on("error", (err) => {
    console.error(`Failed to start: ${err.message}`);
    process.exit(1);
  });
}
