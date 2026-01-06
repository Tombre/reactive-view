# ReactiveView - Post-MVP Tasks Index

This document provides an overview of all follow-up tasks identified during the MVP implementation. Each task has been split into its own detailed file with context, overview, acceptance criteria, and implementation tasks.

## Task Files

### High Priority

| # | Task | File | Description |
|---|------|------|-------------|
| 01 | Custom npm Package | [01-custom-npm-package.md](./01-custom-npm-package.md) | Bundle SolidJS and provide locked versions via `reactiveview` imports |
| 02 | Client-Side Navigation | [02-client-side-navigation.md](./02-client-side-navigation.md) | Data fetching for client-side route transitions |
| 03 | Zeitwerk Integration | [03-zeitwerk-integration.md](./03-zeitwerk-integration.md) | Better autoloading for `.loader.rb` files |
| 04 | JavaScript Tests | [04-javascript-tests.md](./04-javascript-tests.md) | Test suite for SolidStart components and hooks |
| 05 | Production Assets | [05-production-assets.md](./05-production-assets.md) | Integrate SolidStart build with Rails asset pipeline |
| 08 | Mutations/Actions | [08-mutations-actions.md](./08-mutations-actions.md) | POST/PUT/DELETE operations from the frontend |

### Medium Priority

| # | Task | File | Description |
|---|------|------|-------------|
| 06 | Error Boundaries | [06-error-boundaries.md](./06-error-boundaries.md) | Graceful error handling in components with fallback UI |
| 07 | HMR Improvements | [07-hmr-improvements.md](./07-hmr-improvements.md) | Better hot module replacement for TSX files |
| 09 | Streaming SSR | [09-streaming-ssr.md](./09-streaming-ssr.md) | Use SolidStart's streaming capabilities for improved TTFB |

### Low Priority

| # | Task | File | Description |
|---|------|------|-------------|
| 10 | Multi-Server Deployment | [10-multi-server-deployment.md](./10-multi-server-deployment.md) | Run SolidStart daemon on separate server/container |

### Not Yet Detailed

The following tasks have been identified but not yet documented in detail:

- **Nested Layout Data Loading** - Loaders on layout files accessible to children
- **TypeScript Generation Improvements** - More sophisticated type generation from Ruby to TypeScript
- **Test Coverage** - Integration tests with real SolidStart, E2E tests
- **Documentation** - YARD docs, usage guides, troubleshooting
- **CI/CD Setup** - GitHub Actions, automated releases

## Status Legend

Each task file contains a status field:

| Status | Meaning |
|--------|---------|
| Not Started | Work has not begun |
| In Progress | Active development |
| In Review | Complete, pending review |
| Completed | Merged and deployed |
| On Hold | Blocked or deprioritized |

## MVP Limitations Summary

The current MVP provides:
- Basic gem structure with Rails Engine
- Token-based communication between Rails and SolidStart
- Type-safe loader signatures with Dry::Types
- File-based routing from `app/pages/`
- Development tools (daemon management, file sync, type generation)
- Example Rails application

Key limitations to address:
1. Client-side navigation requires manual data fetching setup
2. No mutation support (read-only loaders)
3. Manual loader file loading (Zeitwerk incompatible)
4. Basic error handling
5. No streaming SSR

## Contributing

### Adding New Tasks

1. Create a new file following the naming convention: `XX-task-name.md`
2. Include these sections:
   - **Status/Priority/Category** header
   - **Context** - Why this feature is needed
   - **Overview** - What will be implemented
   - **Acceptance Criteria** - Checkboxes for done definition
   - **Tasks** - Implementation checkboxes
   - **Technical Notes** - Code examples, considerations
   - **Related Files** - Affected codebase locations
3. Update this index file with the new task

### Completing Tasks

1. Update the status in the task file header
2. Check off completed acceptance criteria and tasks
3. Add completion date and any relevant notes
4. Reference the PR/commit that completed the work
5. Update the index status if needed
