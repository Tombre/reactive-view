import { createSignal, createEffect, Suspense, Show, A, useParams } from "@reactive-view/core";
import { useLoaderData, useForm } from "#loaders/users/[id]";
import MainLayout from "../_components/MainLayout";

export default function UserShowPage() {
  const params = useParams();
  const data = useLoaderData();

  const [isEditing, setIsEditing] = createSignal(false);
  const [UpdateForm, updateSubmission] = useForm("update");
  const [DeleteForm, deleteSubmission] = useForm("delete");

  // Reset editing mode on successful update
  createEffect(() => {
    if (updateSubmission.result?.success) {
      setIsEditing(false);
    }
  });

  // Generate initials from name
  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  return (
    <MainLayout>
      {/* Back Link */}
      <A
        href="/users"
        class="inline-flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700 transition-colors mb-6"
      >
        <svg
          class="w-4 h-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M10 19l-7-7m0 0l7-7m-7 7h18"
          />
        </svg>
        Back to Users
      </A>

      {/* Global error display */}
      <Show when={updateSubmission.error || deleteSubmission.error}>
        <div class="mb-6 bg-red-50 border border-red-200 rounded-xl p-4">
          <div class="flex gap-3">
            <svg
              class="w-5 h-5 text-red-600 flex-shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <div>
              <h4 class="text-sm font-semibold text-red-900">Error</h4>
              <p class="text-sm text-red-700 mt-1">
                {(updateSubmission.error as Error)?.message ||
                  (deleteSubmission.error as Error)?.message ||
                  "An unexpected error occurred"}
              </p>
            </div>
          </div>
        </div>
      </Show>

      <Suspense
        fallback={
          <div class="bg-white rounded-xl border border-gray-200 p-8">
            <div class="animate-pulse space-y-4">
              <div class="flex items-center gap-4">
                <div class="w-16 h-16 bg-gray-200 rounded-full"></div>
                <div class="space-y-2">
                  <div class="h-6 bg-gray-200 rounded w-32"></div>
                  <div class="h-4 bg-gray-200 rounded w-48"></div>
                </div>
              </div>
            </div>
          </div>
        }
      >
        <Show
          when={data()?.user}
          fallback={
            <div class="bg-red-50 border border-red-200 rounded-xl p-4">
              <p class="text-red-700">User not found</p>
            </div>
          }
        >
          {(user) => (
            <>
              {/* Page Header */}
              <div class="flex items-start justify-between mb-6">
                <div class="flex items-center gap-4">
                  <div class="w-16 h-16 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-xl font-bold">
                    {getInitials(user().name)}
                  </div>
                  <div>
                    <h1 class="text-2xl font-bold text-gray-900">
                      {user().name}
                    </h1>
                    <p class="text-gray-500">{user().email}</p>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <Show when={!isEditing()}>
                    <button
                      type="button"
                      onClick={() => setIsEditing(true)}
                      class="inline-flex items-center justify-center px-4 py-2.5 bg-white text-gray-700 text-sm font-medium rounded-lg border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                    >
                      <svg
                        class="w-4 h-4 mr-2"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                        />
                      </svg>
                      Edit
                    </button>
                  </Show>
                  <DeleteForm class="inline">
                    <input type="hidden" name="id" value={user().id} />
                    <button
                      type="submit"
                      disabled={deleteSubmission.pending}
                      class="inline-flex items-center justify-center px-4 py-2.5 text-red-600 text-sm font-medium rounded-lg hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors disabled:opacity-50"
                      onClick={(e) => {
                        if (
                          !confirm("Are you sure you want to delete this user?")
                        ) {
                          e.preventDefault();
                        }
                      }}
                    >
                      <svg
                        class="w-4 h-4 mr-2"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                        />
                      </svg>
                      <Show when={deleteSubmission.pending} fallback="Delete">
                        Deleting...
                      </Show>
                    </button>
                  </DeleteForm>
                </div>
              </div>

              {/* Content */}
              <Show
                when={isEditing()}
                fallback={
                  <div class="bg-white rounded-xl border border-gray-200 p-6">
                    <h2 class="text-lg font-semibold text-gray-900 mb-4">
                      User Details
                    </h2>
                    <dl class="grid gap-4 sm:grid-cols-2">
                      <div>
                        <dt class="text-sm font-medium text-gray-500">ID</dt>
                        <dd class="mt-1 text-gray-900">{user().id}</dd>
                      </div>
                      <div>
                        <dt class="text-sm font-medium text-gray-500">Email</dt>
                        <dd class="mt-1 text-gray-900">{user().email}</dd>
                      </div>
                      <div>
                        <dt class="text-sm font-medium text-gray-500">
                          Member Since
                        </dt>
                        <dd class="mt-1 text-gray-900">
                          {new Date(user().created_at).toLocaleDateString()}
                        </dd>
                      </div>
                    </dl>
                  </div>
                }
              >
                {/* Edit Form */}
                <div class="bg-white rounded-xl border border-gray-200 p-6">
                  <div class="flex items-center justify-between mb-6">
                    <h2 class="text-lg font-semibold text-gray-900">
                      Edit User
                    </h2>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      Editing
                    </span>
                  </div>

                  <UpdateForm>
                    <input type="hidden" name="id" value={user().id} />

                    {/* Validation errors */}
                    <Show
                      when={
                        updateSubmission.result &&
                        !updateSubmission.result.success
                      }
                    >
                      <div class="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
                        <div class="flex gap-3">
                          <svg
                            class="w-5 h-5 text-red-600 flex-shrink-0"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                          </svg>
                          <div class="text-sm text-red-700">
                            <Show when={updateSubmission.result?.errors?.name}>
                              <p>
                                Name: {updateSubmission.result?.errors?.name}
                              </p>
                            </Show>
                            <Show when={updateSubmission.result?.errors?.email}>
                              <p>
                                Email: {updateSubmission.result?.errors?.email}
                              </p>
                            </Show>
                            <Show when={updateSubmission.result?.errors?.base}>
                              <p>{updateSubmission.result?.errors?.base}</p>
                            </Show>
                          </div>
                        </div>
                      </div>
                    </Show>

                    <div class="space-y-4">
                      <div>
                        <label
                          for="name"
                          class="block text-sm font-medium text-gray-700 mb-1.5"
                        >
                          Name
                        </label>
                        <input
                          type="text"
                          id="name"
                          name="name"
                          value={user().name}
                          class="w-full px-3 py-2.5 bg-white border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-shadow"
                        />
                      </div>

                      <div>
                        <label
                          for="email"
                          class="block text-sm font-medium text-gray-700 mb-1.5"
                        >
                          Email
                        </label>
                        <input
                          type="email"
                          id="email"
                          name="email"
                          value={user().email}
                          class="w-full px-3 py-2.5 bg-white border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-shadow"
                        />
                      </div>
                    </div>

                    <div class="flex items-center gap-3 mt-6 pt-6 border-t border-gray-200">
                      <button
                        type="submit"
                        disabled={updateSubmission.pending}
                        class="inline-flex items-center justify-center px-4 py-2.5 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors disabled:opacity-50"
                      >
                        <Show
                          when={updateSubmission.pending}
                          fallback="Save Changes"
                        >
                          Saving...
                        </Show>
                      </button>
                      <button
                        type="button"
                        onClick={() => setIsEditing(false)}
                        class="inline-flex items-center justify-center px-4 py-2.5 text-gray-600 text-sm font-medium rounded-lg hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
                      >
                        Cancel
                      </button>
                    </div>
                  </UpdateForm>
                </div>
              </Show>

              {/* Info Box */}
              <div class="mt-6 bg-blue-50 border border-blue-200 rounded-xl p-4">
                <div class="flex gap-3">
                  <svg
                    class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <div>
                    <h4 class="text-sm font-semibold text-blue-900">
                      Dynamic Route with Mutations
                    </h4>
                    <p class="text-sm text-blue-700 mt-1">
                      This page uses a dynamic route segment{" "}
                      <code class="px-1.5 py-0.5 bg-blue-100 text-blue-800 rounded text-xs font-mono">
                        [id]
                      </code>
                      . Current ID: <strong>{params.id}</strong>
                    </p>
                    <p class="text-sm text-blue-700 mt-2">
                      Mutations are defined using{" "}
                      <code class="px-1.5 py-0.5 bg-blue-100 text-blue-800 rounded text-xs font-mono">
                        shape :update
                      </code>{" "}
                      and{" "}
                      <code class="px-1.5 py-0.5 bg-blue-100 text-blue-800 rounded text-xs font-mono">
                        shape :delete
                      </code>
                      , which auto-generate typed form components.
                    </p>
                  </div>
                </div>
              </div>
            </>
          )}
        </Show>
      </Suspense>
    </MainLayout>
  );
}
