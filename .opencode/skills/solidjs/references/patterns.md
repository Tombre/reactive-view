# SolidJS Patterns For ReactiveView

Use these patterns when writing TSX in `app/pages/`.

## Imports

Preferred import sources:

```tsx
import { createSignal, Show, For, Suspense } from "@reactive-view/core";
import { useLoaderData, useForm, useStream } from "#loaders/users/[id]";
```

- Use `@reactive-view/core` for Solid primitives/router helpers used by app pages.
- Use route-specific `#loaders/...` modules for typed loader and mutation helpers.

## Control Flow And Attributes

Use Solid conventions:

```tsx
<Show when={data()?.user} fallback={<p>User not found</p>}>
  {(user) => <h1 class="text-xl">{user().name}</h1>}
</Show>

<For each={data()?.users || []}>{(user) => <li>{user.name}</li>}</For>

<label for="email">Email</label>
<input id="email" class="input" onInput={(e) => setEmail(e.target.value)} />
```

Avoid React aliases and shortcuts in Solid TSX:

- `className` -> `class`
- `htmlFor` -> `for`
- `tabIndex` -> `tabindex`
- `array.map(...)` for list rendering as a default pattern -> `<For>`
- `condition && <X />` as a default pattern -> `<Show when={condition}>`

## Loader Data

Use generated loader hook in route files:

```tsx
import { useLoaderData } from "#loaders/users/index";

export default function UsersPage() {
  const data = useLoaderData();
  return <p>{data()?.users.length || 0} users</p>;
}
```

For cross-route access, use `@reactive-view/core` route key API:

```tsx
import { useLoaderData } from "@reactive-view/core";

const users = useLoaderData("users/index");
const user = useLoaderData("users/[id]", { id: "123" });
```

## Mutations

Prefer generated `useForm("mutationName")` helpers from `#loaders/*`:

```tsx
const [UpdateForm, updateSubmission] = useForm("update");

<UpdateForm>
  <input name="name" />
  <button type="submit" disabled={updateSubmission.pending}>
    <Show when={updateSubmission.pending} fallback="Save">
      Saving...
    </Show>
  </button>
</UpdateForm>;
```

## Streaming

For SSE mutation UX:

```tsx
const stream = useStream("generate");
const StreamForm = useForm(stream);

<StreamForm>
  <input name="prompt" />
  <button type="submit" disabled={stream.streaming()}>
    <Show when={stream.streaming()} fallback="Send">
      Generating...
    </Show>
  </button>
</StreamForm>;
```

Programmatic calls stay typed:

```tsx
stream.start({ prompt: "Hello" });
```

Use stream state helpers:

- `stream.data()` accumulated text
- `stream.streaming()` in-flight state
- `stream.error()` request/stream failure
- `stream.chunks()` mixed text/json events

## Regeneration Trigger

After changing Ruby loader shapes or mutation definitions:

```bash
bin/rails reactive_view:types:generate
```
