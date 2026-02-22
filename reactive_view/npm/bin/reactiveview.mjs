#!/usr/bin/env node

// ReactiveView CLI
// Thin entry point that checks Node.js version and delegates to the CLI module.

const currentVersion = process.versions.node;
const major = parseInt(currentVersion.split(".")[0], 10);

if (major < 18) {
  console.error(
    `ReactiveView requires Node.js 18 or later. You are running Node.js ${currentVersion}.`
  );
  process.exit(1);
}

const module = await import("../dist/cli.js");
module.run(process.argv.slice(2));
