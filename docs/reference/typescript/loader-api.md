# TypeScript: Loader API

Source: `@reactive-view/core` loader module.

## `useLoaderData`

Overloads:

- `useLoaderData<T>()`
- `useLoaderData(route, params?)`

Returns Solid `Resource<T>`.

## `createLoaderQuery`

```ts
createLoaderQuery<T>(loaderPath: string): (params: Record<string, string>) => Promise<T>
```

Uses Solid Router `query()` for cached loader requests.

## Transport details

- endpoint: `/_reactive_view/loaders/${loaderPath}/load`
- query params include route params
- credentials included on client
- SSR can forward cookies via globals

## HMR behavior

In dev, custom event `reactive-view:loader-update` invalidates active loaders and triggers refetch.
