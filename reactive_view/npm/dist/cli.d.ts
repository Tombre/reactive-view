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
/**
 * Run the CLI with the given arguments.
 *
 * @param argv - Arguments from process.argv.slice(2)
 */
export declare function run(argv: string[]): void;
//# sourceMappingURL=cli.d.ts.map