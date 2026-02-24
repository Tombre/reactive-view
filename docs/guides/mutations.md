# Mutations Guide

This guide covers how to use ReactiveView's mutation system to handle form submissions and data modifications while keeping all business logic in Rails.

## Overview

ReactiveView mutations allow you to define data modification operations alongside your loader data shapes. When you define a mutation shape, ReactiveView automatically generates:

- A typed action function for Solid Router
- A pre-configured Form component with CSRF protection
- TypeScript interfaces for mutation parameters

## Defining Mutations

Mutations are defined in your `.loader.rb` files using the `shape` DSL:

```ruby
# app/pages/users/[id].loader.rb
module Pages
  module Users
    class IdLoader < ReactiveView::Loader
      # Load shape for reading data
      shape :load do
        param :user, ReactiveView::Types::Hash.schema(
          id: ReactiveView::Types::Integer,
          name: ReactiveView::Types::String,
          email: ReactiveView::Types::String
        )
      end

      # Update mutation shape
      shape :update do
        param :name, ReactiveView::Types::String
        param :email, ReactiveView::Types::String
      end

      # Delete mutation (no params needed)
      shape :delete do
      end

      def load
        { user: serialize_user(user) }
      end

      def update
        typed_params = shapes.update(params)

        if user.update(typed_params)
          render_success(user: serialize_user(user))
        else
          render_error(user)
        end
      end

      def delete
        if user.destroy
          mutation_redirect "/users"
        else
          render_error(user)
        end
      end

      private

      def user
        @user ||= User.find(params[:id])
      end

      def serialize_user(user)
        { id: user.id, name: user.name, email: user.email }
      end
    end
  end
end
```

## Using Generated Components

After defining mutations and running `rails reactive_view:types:generate`, you can import the generated components:

```tsx
// app/pages/users/[id].tsx
import { Show, createSignal } from "solid-js";
import {
  useLoaderData,
  UpdateForm,
  DeleteForm,
  updateAction,
  useSubmission,
} from "#loaders/users/[id]";

export default function UserPage() {
  const data = useLoaderData();
  const [isEditing, setIsEditing] = createSignal(false);
  const updateSubmission = useSubmission(updateAction);

  return (
    <div>
      <Show when={!isEditing()}>
        <p>{data()?.user.name}</p>
        <button onClick={() => setIsEditing(true)}>Edit</button>
      </Show>

      <Show when={isEditing()}>
        <UpdateForm>
          <input name="name" value={data()?.user.name} />
          <input name="email" value={data()?.user.email} />
          <button type="submit" disabled={updateSubmission.pending}>
            {updateSubmission.pending ? "Saving..." : "Save"}
          </button>
          <button type="button" onClick={() => setIsEditing(false)}>
            Cancel
          </button>
        </UpdateForm>
      </Show>

      <DeleteForm>
        <button type="submit">Delete User</button>
      </DeleteForm>
    </div>
  );
}
```

## Typed Parameter Extraction

Use `shapes.mutation_name(params)` to extract and validate typed parameters:

```ruby
def update
  # Extract only the declared params with type coercion
  typed_params = shapes.update(params)
  # => { name: "John", email: "john@example.com" }

  user.update(typed_params)
end
```

The `shapes` accessor:
- Extracts only the params declared in the shape definition
- Coerces types (strings to integers, booleans, etc.)
- Returns a hash ready for use with ActiveRecord

## Response Helpers

### render_success

Returns a successful JSON response:

```ruby
def update
  if user.update(typed_params)
    render_success(
      user: serialize_user(user),
      revalidate: ["users/index"]  # Routes to revalidate on client
    )
  end
end
```

Response format:
```json
{
  "success": true,
  "user": { "id": 1, "name": "John", "email": "john@example.com" },
  "revalidate": ["users/index"]
}
```

Note: data keys are spread at the top level of the response (not nested under a `"data"` key).

### render_error

Returns an error JSON response. Accepts:

1. **ActiveModel errors** (from a model with validation errors):
```ruby
def create
  user = User.new(typed_params)
  unless user.save
    render_error(user)
  end
end
```

Response:
```json
{
  "success": false,
  "errors": {
    "email": ["has already been taken"],
    "name": ["can't be blank"]
  }
}
```

2. **Hash of errors**:
```ruby
render_error({ email: "Invalid format" })
```

3. **String error**:
```ruby
render_error("Something went wrong")
```

Response:
```json
{
  "success": false,
  "errors": { "base": ["Something went wrong"] }
}
```

### mutation_redirect

For mutations that should redirect after completion, use `mutation_redirect`:

```ruby
def delete
  user.destroy
  mutation_redirect "/users"
end
```

Response:
```json
{
  "_redirect": "/users"
}
```

You can also include routes to revalidate:

```ruby
def delete
  user.destroy
  mutation_redirect "/users", revalidate: ["users/index"]
end
```

The client will automatically navigate to the redirect path. For non-client requests (direct browser navigation), a standard HTTP redirect is performed.

## Handling Submissions in Components

### useSubmission

Track the state of a form submission:

```tsx
import { updateAction, useSubmission } from "#loaders/users/[id]";

export default function EditUser() {
  const submission = useSubmission(updateAction);

  return (
    <div>
      {/* Show loading state */}
      <Show when={submission.pending}>
        <p>Saving...</p>
      </Show>

      {/* Show errors */}
      <Show when={submission.result?.errors}>
        <div class="error">
          {Object.entries(submission.result.errors).map(([field, msgs]) => (
            <p>{field}: {msgs.join(", ")}</p>
          ))}
        </div>
      </Show>

      {/* Show success */}
      <Show when={submission.result?.success}>
        <p>Saved successfully!</p>
      </Show>
    </div>
  );
}
```

### useAction

For programmatic submissions (not using a form):

```tsx
import { updateAction, useAction } from "#loaders/users/[id]";

export default function EditUser() {
  const submitUpdate = useAction(updateAction);

  const handleSave = async () => {
    const formData = new FormData();
    formData.append("name", "New Name");
    formData.append("email", "new@example.com");

    const result = await submitUpdate(formData);
    if (result.success) {
      console.log("Updated!");
    }
  };

  return <button onClick={handleSave}>Save Programmatically</button>;
}
```

### createJsonMutation

For programmatic mutations that send JSON instead of FormData, use `createJsonMutation` from `@reactive-view/core`:

```tsx
import { createJsonMutation, useAction } from "@reactive-view/core";

// Create a JSON mutation action (typed input)
const updateAction = createJsonMutation<{ name: string; email: string }>(
  "users/[id]",
  "update"
);

export default function EditUser() {
  const submitUpdate = useAction(updateAction);

  const handleSave = async () => {
    const result = await submitUpdate({
      name: "New Name",
      email: "new@example.com",
    });
    if (result.success) {
      console.log("Updated!");
    }
  };

  return <button onClick={handleSave}>Save</button>;
}
```

`createJsonMutation` sends a JSON body with `Content-Type: application/json` instead of `multipart/form-data`. This is useful when you need type-safe input without using form elements.

## CSRF Protection

ReactiveView automatically handles CSRF protection:

1. During SSR, the CSRF token is injected as a `<meta name="csrf-token">` tag
2. Generated Form components automatically include the token
3. Programmatic mutations via `createMutation` include the token in headers

You don't need to manually handle CSRF tokens in most cases.

## Route Revalidation

After a mutation, you often want to refresh cached data on other routes. Use the `revalidate` option:

```ruby
def update
  if user.update(typed_params)
    render_success(
      user: serialize_user(user),
      revalidate: ["users/index", "users/[id]"]
    )
  end
end
```

The client will automatically invalidate cached data for the specified routes.

## Multiple Mutations Per Loader

You can define multiple mutations in a single loader:

```ruby
module Pages
  module Posts
    class IdLoader < ReactiveView::Loader
      shape :update do
        param :title, ReactiveView::Types::String
        param :content, ReactiveView::Types::String
      end

      shape :publish do
        param :published_at, ReactiveView::Types::String.optional
      end

      shape :delete do
      end

      def update
        # ...
      end

      def publish
        typed_params = shapes.publish(params)
        post.update(published: true, published_at: typed_params[:published_at] || Time.current)
        render_success(post: serialize_post(post))
      end

      def delete
        # ...
      end
    end
  end
end
```

This generates `UpdateForm`, `PublishForm`, and `DeleteForm` components.

## Error Handling

### Validation Errors

Display field-specific errors from ActiveModel:

```tsx
<UpdateForm>
  <div>
    <input name="email" />
    <Show when={submission.result?.errors?.email}>
      <span class="error">{submission.result.errors.email[0]}</span>
    </Show>
  </div>
  <button type="submit">Save</button>
</UpdateForm>
```

### Generic Errors

Handle base errors (not tied to a specific field):

```tsx
<Show when={submission.result?.errors?.base}>
  <div class="alert alert-error">
    {submission.result.errors.base}
  </div>
</Show>
```

## TypeScript Types

Generated mutation interfaces match your shape definitions:

```typescript
// Auto-generated in .reactive_view/types/loaders/users/[id].ts

export interface UpdateParams {
  name: string;
  email: string;
}

export interface PublishParams {
  published_at?: string | null;
}

export type DeleteParams = Record<string, unknown>;
```

## Best Practices

1. **Keep mutations focused**: Each mutation should do one thing well
2. **Use typed params**: Always use `shapes.mutation_name(params)` for type safety
3. **Handle all error cases**: Check for validation errors and return appropriate responses
4. **Revalidate related routes**: Keep the UI consistent by revalidating affected routes
5. **Show loading states**: Use `submission.pending` to indicate progress
6. **Display errors clearly**: Show field-specific errors next to inputs

## Troubleshooting

### CSRF Token Issues

If you see "Invalid authenticity token" errors:

1. Ensure your layout includes `<%= csrf_meta_tags %>`
2. Check that the meta tag is being injected by ReactiveView
3. Verify the token is being sent in the `X-CSRF-Token` header

### Mutations Not Found

If mutations return 404:

1. Run `rails reactive_view:types:generate` to regenerate types
2. Ensure the mutation method exists in your loader class
3. Check that the mutation name matches between shape and method

### Type Mismatches

If TypeScript shows type errors:

1. Run `rails reactive_view:types:generate` after changing shapes
2. Restart your TypeScript language server
3. Verify the shape definition matches your expected types
