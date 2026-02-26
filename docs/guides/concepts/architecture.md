# Architecture

ReactiveView keeps Rails as the backend authority and uses SolidStart for SSR + hydration.

## Runtime pieces

- **Rails app + ReactiveView engine**: routing, auth, business logic, loader execution
- **SolidStart daemon**: renders TSX to HTML and hydrates client app
- **Generated TS loader types**: typed bridge between Ruby loader shapes and TSX

## Request flow (SSR)

1. Browser requests a route (for example `/users/123`)
2. Rails route maps to a loader class and calls `Loader#call`
3. `ReactiveView::Renderer` POSTs to daemon `/_api/render` (`/api/render` in template)
4. Daemon SSR calls back to Rails internal loader endpoint for JSON
5. Rails `LoaderDataController#show` runs loader `#load`
6. Daemon returns HTML to Rails
7. Rails responds with SSR HTML + hydration script

## Client-side navigation

After hydration, `useLoaderData()` fetches loader JSON from Rails directly via internal endpoints.

## Internal vs public surfaces

- **Public**: `ReactiveView::Loader`, `shape`, `params_shape`, `response_shape`, `@reactive-view/core`
- **Internal**: `LoaderDataController`, file watcher internals, transport internals

Use internals for debugging and extension work, not as your primary app integration surface.
