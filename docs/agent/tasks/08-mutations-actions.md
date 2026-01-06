# Mutations/Actions Support

**Status:** Not Started  
**Priority:** High  
**Category:** Core Functionality

## Context

ReactiveView currently supports data loading from Rails to SolidJS components via loaders. However, modern web applications also need to mutate data - creating, updating, and deleting records. This is the other half of the data flow equation.

Currently, developers must:

1. Manually create Rails API endpoints for mutations
2. Write fetch calls in their SolidJS components
3. Handle loading states, errors, and optimistic updates manually
4. Manage form submissions without framework support

This is error-prone and creates inconsistent patterns across applications. ReactiveView should provide a first-class solution for data mutations, similar to how SolidStart actions or Remix actions work.

## Overview

Implement an action system for ReactiveView that:

- Provides a Ruby DSL for defining actions (similar to loaders)
- Registers actions and makes them callable from the client
- Offers a `useAction` hook for invoking actions from components
- Supports optimistic updates for better UX
- Handles form submissions seamlessly
- Integrates with Rails' existing patterns (strong parameters, validations)

**Current Mutation Flow:**
```
Component → Manual Fetch → Custom API Endpoint → Response → Manual State Update
```

**Target Mutation Flow:**
```
Component → useAction() → ActionRegistry → Rails Action → Response → Automatic Revalidation
```

## Acceptance Criteria

- [ ] Action DSL allows defining mutations in Ruby files (`.action.rb`)
- [ ] Actions support POST, PUT, PATCH, and DELETE operations
- [ ] `ActionRegistry` tracks all available actions
- [ ] `useAction` hook provides function to call actions from components
- [ ] Actions return typed responses to the client
- [ ] Loading states are available during action execution
- [ ] Error states are properly propagated and typed
- [ ] Optimistic updates can be configured
- [ ] Form submissions work with actions (`<form>` integration)
- [ ] Actions can trigger loader revalidation
- [ ] CSRF protection is enforced
- [ ] TypeScript types are generated for actions
- [ ] Example application demonstrates action usage

## Tasks

- [ ] Design action DSL syntax (mirroring loader DSL)
- [ ] Create `Action` class for defining mutations
- [ ] Implement `ActionRegistry` for tracking actions
- [ ] Create Rails controller for handling action requests
- [ ] Implement `useAction` hook in the client library
- [ ] Add loading and error state management to `useAction`
- [ ] Implement optimistic update support
- [ ] Add form submission handling (`<Form>` component or native form support)
- [ ] Implement action-triggered loader revalidation
- [ ] Add CSRF token handling for action requests
- [ ] Generate TypeScript types for action inputs and outputs
- [ ] Update type generation to include actions
- [ ] Add validation error handling and display
- [ ] Create example CRUD operations in example app
- [ ] Document action patterns and best practices

## Technical Notes

### Action DSL

```ruby
# app/pages/users/create.action.rb
class Users::CreateAction < ReactiveView::Action
  # Define input types
  input do
    name :string, required: true
    email :string, required: true
    role :string, default: "user"
  end

  # Define output type
  output do
    user do
      id :integer
      name :string
      email :string
    end
    errors :array, of: :string
  end

  def call
    user = User.new(input)
    
    if user.save
      { user: user.as_json(only: [:id, :name, :email]), errors: [] }
    else
      { user: nil, errors: user.errors.full_messages }
    end
  end
end
```

### useAction Hook

```tsx
import { useAction } from "reactiveview";

function CreateUserForm() {
  const createUser = useAction<typeof Users.CreateAction>("users/create");
  
  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    
    const result = await createUser({
      name: formData.get("name") as string,
      email: formData.get("email") as string,
    });
    
    if (result.errors.length === 0) {
      // Success - loader data will auto-revalidate
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input name="name" />
      <input name="email" type="email" />
      <button type="submit" disabled={createUser.pending}>
        {createUser.pending ? "Creating..." : "Create User"}
      </button>
      {createUser.error && <p>{createUser.error.message}</p>}
    </form>
  );
}
```

### Form Component Integration

```tsx
import { Form } from "reactiveview";

function CreateUserForm() {
  return (
    <Form action="users/create" onSuccess={() => navigate("/users")}>
      <input name="name" />
      <input name="email" type="email" />
      <button type="submit">Create User</button>
    </Form>
  );
}
```

### Optimistic Updates

```tsx
const deleteUser = useAction("users/delete", {
  optimistic: (input) => {
    // Immediately remove from local state
    setUsers(users => users.filter(u => u.id !== input.id));
  },
  onError: (error, input) => {
    // Revert on failure
    refetchUsers();
  }
});
```

### Action Controller

```ruby
# reactive_view/app/controllers/reactive_view/actions_controller.rb
module ReactiveView
  class ActionsController < ApplicationController
    def call
      action = ActionRegistry.find(params[:action_name])
      result = action.new(action_params, request: request).call
      render json: result
    end
    
    private
    
    def action_params
      params.require(:input).permit!
    end
  end
end
```

### Revalidation Strategy

After an action completes successfully, affected loaders should be revalidated:

```ruby
class Users::CreateAction < ReactiveView::Action
  revalidates "users/index"  # Revalidate user list after creation
  
  def call
    # ...
  end
end
```

## Related Files

- `reactive_view/lib/reactive_view/loader.rb` (reference for DSL)
- `reactive_view/lib/reactive_view/loader_registry.rb` (reference for registry)
- `reactive_view/app/controllers/reactive_view/loader_data_controller.rb`
- `reactive_view/template/src/lib/reactive-view/loader.ts`
