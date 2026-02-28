/**
 * ReactiveView CLI
 *
 * Provides `reactiveview dev`, `reactiveview build`, and `reactiveview start` commands
 * that run the SolidStart/Vinxi toolchain from the Rails project root.
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
import { existsSync } from "node:fs";
import { relative, resolve } from "node:path";

const WORKING_DIR = ".reactive_view";
const CONFIG_FILE = "app.config.ts";
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

  const configPath = resolve(workingDir, CONFIG_FILE);
  const configPathArg = relative(process.cwd(), configPath);

  if (!existsSync(configPath)) {
    console.error(`Error: SolidStart config not found at ${configPath}`);
    console.error("");
    console.error(`The .reactive_view directory is incomplete.`);
    console.error(`Run "rails reactive_view:setup" to repair it.`);
    process.exit(1);
  }

  // Build the vinxi command (executed from Rails root)
  const args = ["vinxi", commandConfig.script, "--config", configPathArg, ...passthrough];

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

  const child = spawn("npx", args, {
    cwd: process.cwd(),
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
