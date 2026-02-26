# Your First Page

ReactiveView routes come from files in `app/pages`.

## Create a page

```tsx
// app/pages/hello.tsx
export default function HelloPage() {
  return <h1>Hello from ReactiveView</h1>;
}
```

This creates route `GET /hello`.

## Use SolidJS conventions

ReactiveView uses SolidJS TSX (not React JSX):

- use `class`, not `className`
- use `<Show>` and `<For>` for control flow

Example:

```tsx
import { createSignal, Show } from "solid-js";

export default function CounterPage() {
  const [count, setCount] = createSignal(0);

  return (
    <main class="p-6">
      <button onClick={() => setCount(count() + 1)}>Increment</button>
      <Show when={count() > 0}>
        <p>Count: {count()}</p>
      </Show>
    </main>
  );
}
```

## Private files and folders

Paths prefixed with `_` do not become routes:

- `app/pages/_components/Nav.tsx`
- `app/pages/users/_partials/UserCard.tsx`

You can import them normally from route files.

Next: [Your First Loader](first-loader.md)
