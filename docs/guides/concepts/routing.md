# Routing

ReactiveView uses file-based routing from `app/pages`.

## Filename to route mapping

- `app/pages/index.tsx` -> `/`
- `app/pages/about.tsx` -> `/about`
- `app/pages/users/index.tsx` -> `/users`
- `app/pages/users/[id].tsx` -> `/users/:id`
- `app/pages/blog/[...slug].tsx` -> `/blog/*slug`
- `app/pages/users/[[id]].tsx` -> `/users(/:id)`

## Route groups

Parenthesized folders organize files without changing URL paths:

- `app/pages/(admin)/dashboard/index.tsx` -> `/dashboard`
- `app/pages/(admin)/(auth)/login.tsx` -> `/login`

## Private paths

Any segment prefixed with `_` is private and does not generate routes:

- `app/pages/_components/*`
- `app/pages/_styles/*`
- `app/pages/users/_partials/*`

## Layout routes

A file becomes a layout when a same-named folder exists:

- `app/pages/blog.tsx` wraps routes under `app/pages/blog/*`

## Route drawing and priority

`ReactiveView::Router` scans pages and sorts priority to prefer specific routes:

1. static
2. dynamic (`[id]`)
3. optional (`[[id]]`)
4. catch-all (`[...slug]`)

See [Router and LoaderRegistry Reference](../../reference/ruby/router-and-loader-registry.md).
