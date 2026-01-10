import { createSignal, createEffect, Suspense, Show } from "solid-js";
import { A, useParams } from "@solidjs/router";
import {
  useLoaderData,
  UpdateForm,
  DeleteForm,
  updateAction,
  deleteAction,
  useSubmission,
} from "#loaders/users/[id]";
import MainLayout from "../components/MainLayout";

export default function UserShowPage() {
  const params = useParams();
  const data = useLoaderData();

  const [isEditing, setIsEditing] = createSignal(false);
  const updateSubmission = useSubmission(updateAction);
  const deleteSubmission = useSubmission(deleteAction);

  // Reset editing mode on successful update
  createEffect(() => {
    if (updateSubmission.result?.success) {
      setIsEditing(false);
    }
  });

  return (
    <MainLayout>
      <A
        href="/users"
        class="inline-flex items-center text-blue-600 hover:text-blue-700 mb-6 no-underline"
      >
        <span class="mr-2">←</span> Back to Users
      </A>

      {/* Global error display for unexpected errors */}
      <Show when={updateSubmission.error || deleteSubmission.error}>
        <div class="mb-4 p-4 bg-red-100 border border-red-300 rounded-lg text-red-800">
          <h4 class="font-semibold mb-1">Error</h4>
          <p class="text-sm">
            {(updateSubmission.error as Error)?.message || 
             (deleteSubmission.error as Error)?.message || 
             "An unexpected error occurred"}
          </p>
        </div>
      </Show>

      <Suspense
        fallback={<div class="mt-5 text-gray-500">Loading user...</div>}
      >
        <Show
          when={data()?.user}
          fallback={<div class="text-red-500">User not found</div>}
        >
          {(user) => (
            <div class="mt-5">
              <div class="flex items-center justify-between mb-6">
                <h1 class="text-3xl font-bold text-gray-900">{user().name}</h1>
                <div class="space-x-2">
                  <Show when={!isEditing()}>
                    <button
                      type="button"
                      onClick={() => setIsEditing(true)}
                      class="px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100"
                    >
                      Edit
                    </button>
                  </Show>
                  <DeleteForm class="inline">
                    <input type="hidden" name="id" value={user().id} />
                    <button
                      type="submit"
                      disabled={deleteSubmission.pending}
                      class="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 rounded-lg hover:bg-red-100 disabled:opacity-50"
                      onClick={(e) => {
                        if (!confirm("Are you sure you want to delete this user?")) {
                          e.preventDefault();
                        }
                      }}
                    >
                      <Show when={deleteSubmission.pending} fallback="Delete">
                        Deleting...
                      </Show>
                    </button>
                  </DeleteForm>
                </div>
              </div>

              <Show
                when={isEditing()}
                fallback={
                  <div class="bg-white border border-gray-200 p-6 rounded-xl">
                    <div class="mb-4">
                      <label class="block text-gray-600 text-sm mb-1">ID</label>
                      <div class="font-medium text-gray-900">{user().id}</div>
                    </div>

                    <div class="mb-4">
                      <label class="block text-gray-600 text-sm mb-1">
                        Email
                      </label>
                      <div class="font-medium text-gray-900">{user().email}</div>
                    </div>

                    <div>
                      <label class="block text-gray-600 text-sm mb-1">
                        Member Since
                      </label>
                      <div class="font-medium text-gray-900">
                        {new Date(user().created_at).toLocaleDateString()}
                      </div>
                    </div>
                  </div>
                }
              >
                <UpdateForm class="bg-white border border-gray-200 p-6 rounded-xl">
                  <input type="hidden" name="id" value={user().id} />

                  {/* Validation errors from Rails */}
                  <Show when={updateSubmission.result && !updateSubmission.result.success}>
                    <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
                      <Show when={updateSubmission.result?.errors?.name}>
                        <p>Name: {updateSubmission.result?.errors?.name}</p>
                      </Show>
                      <Show when={updateSubmission.result?.errors?.email}>
                        <p>Email: {updateSubmission.result?.errors?.email}</p>
                      </Show>
                      <Show when={updateSubmission.result?.errors?.base}>
                        <p>{updateSubmission.result?.errors?.base}</p>
                      </Show>
                    </div>
                  </Show>

                  <div class="mb-4">
                    <label for="name" class="block text-gray-600 text-sm mb-1">
                      Name
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={user().name}
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>

                  <div class="mb-4">
                    <label for="email" class="block text-gray-600 text-sm mb-1">
                      Email
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      value={user().email}
                      class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                  </div>

                  <div class="flex space-x-2">
                    <button
                      type="submit"
                      disabled={updateSubmission.pending}
                      class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                    >
                      <Show when={updateSubmission.pending} fallback="Save Changes">
                        Saving...
                      </Show>
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsEditing(false)}
                      class="px-4 py-2 text-sm font-medium text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200"
                    >
                      Cancel
                    </button>
                  </div>
                </UpdateForm>
              </Show>

              <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <h3 class="text-lg font-semibold text-blue-900 mb-2">
                  Dynamic Route with Mutations
                </h3>
                <p class="text-blue-800 text-sm">
                  This page uses a dynamic route segment:{" "}
                  <code class="bg-blue-100 px-2 py-1 rounded">[id]</code>
                  <br />
                  Current ID from URL: <strong>{params.id}</strong>
                  <br />
                  <br />
                  Mutations are defined in the loader file using{" "}
                  <code class="bg-blue-100 px-2 py-1 rounded">shape :update</code>{" "}
                  and{" "}
                  <code class="bg-blue-100 px-2 py-1 rounded">shape :delete</code>,
                  which auto-generate typed{" "}
                  <code class="bg-blue-100 px-2 py-1 rounded">UpdateForm</code> and{" "}
                  <code class="bg-blue-100 px-2 py-1 rounded">DeleteForm</code>{" "}
                  components.
                </p>
              </div>
            </div>
          )}
        </Show>
      </Suspense>
    </MainLayout>
  );
}
