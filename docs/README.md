# ReactiveView Documentation

ReactiveView documentation is split into two levels:

- **Guides**: practical, concept-first docs for building apps
- **Reference**: API and behavior details for Ruby and TypeScript surfaces

## Guides

- Start here: [Guides Index](guides/index.md)
- Getting started:
  - [Installation](guides/getting-started/installation.md)
  - [Your First Page](guides/getting-started/first-page.md)
  - [Your First Loader](guides/getting-started/first-loader.md)
  - [Development Workflow](guides/getting-started/development-workflow.md)
- Concepts:
  - [Architecture](guides/concepts/architecture.md)
  - [Routing](guides/concepts/routing.md)
  - [Shapes and Validation](guides/concepts/shapes-and-validation.md)
  - [HMR and File Sync](guides/concepts/hmr-and-file-sync.md)
  - [Security, Cookies, and CSRF](guides/concepts/security-cookies-csrf.md)
- Data:
  - [Loaders](guides/data/loaders.md)
  - [Mutations](guides/data/mutations.md)
  - [Streaming](guides/data/streaming.md)
  - [Type Generation](guides/data/type-generation.md)
- Operations:
  - [Configuration](guides/operations/configuration.md)
  - [Daemon Management](guides/operations/daemon-management.md)
  - [Production Build and Deploy](guides/operations/production-build-and-deploy.md)
  - [Troubleshooting](guides/operations/troubleshooting.md)

## Reference

- Start here: [Reference Index](reference/index.md)
- Ruby API:
  - [Configuration](reference/ruby/configuration.md)
  - [Loader](reference/ruby/loader.md)
  - [Shape](reference/ruby/shape.md)
  - [Types DSL](reference/ruby/types-dsl.md)
  - [MutationResult](reference/ruby/mutation-result.md)
  - [Router and LoaderRegistry](reference/ruby/router-and-loader-registry.md)
  - [Renderer and Daemon](reference/ruby/renderer-and-daemon.md)
  - [File Sync](reference/ruby/file-sync.md)
  - [Internal Endpoints](reference/ruby/internal-endpoints.md)
  - [Rake Tasks](reference/ruby/rake-tasks.md)
  - [Errors](reference/ruby/errors.md)
- TypeScript API:
  - [Core API](reference/typescript/core-api.md)
  - [Loader API](reference/typescript/loader-api.md)
  - [Mutation API](reference/typescript/mutation-api.md)
  - [Stream API](reference/typescript/stream-api.md)
  - [CSRF API](reference/typescript/csrf-api.md)
  - [Config API](reference/typescript/config-api.md)
  - [Vite Plugin API](reference/typescript/vite-plugin-api.md)
  - [Generated Loader Files](reference/typescript/generated-loader-files.md)

## Stability Notes

- **Public API**: classes and functions intended for app-level use (`ReactiveView::Loader`, `ReactiveView.configure`, `@reactive-view/core` exports)
- **Internal API**: engine internals and transport/controller details may change between releases (`LoaderDataController`, file watcher internals, daemon internals)

Internal APIs are documented to aid debugging and extension work, but should not be treated as long-term stable integration points.
