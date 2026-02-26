# TypeScript: Mutation API

## `createMutation`

```ts
createMutation<TResult = unknown>(loaderPath: string, mutationName = "mutate")
```

- submits `FormData` to `/_reactive_view/loaders/${loaderPath}/mutate?_mutation=${name}`
- includes `X-CSRF-Token` when available
- handles redirect payloads (`_redirect`, `_revalidate`) via Solid Router `redirect`

## `createJsonMutation`

```ts
createJsonMutation<TInput = Record<string, unknown>, TResult = unknown>(loaderPath: string, mutationName = "mutate")
```

- sends JSON body instead of `FormData`
- otherwise same endpoint and redirect behavior

## Re-exported router helpers

- `useAction`
- `useSubmission`
- `useSubmissions`

## `MutationResult` interface

Important keys:

- `success: boolean`
- `errors?: Record<string, string[]>`
- `_redirect?: string`
- `_revalidate?: string[]`
