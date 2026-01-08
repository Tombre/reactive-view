import { Suspense, Show } from "solid-js";
import { A, useParams } from "@solidjs/router";
import { useLoaderData } from "#loaders/users/[id]";
import MainLayout from "../components/MainLayout";

export default function UserShowPage() {
  const params = useParams();
  const data = useLoaderData();

  return (
    <MainLayout>
      <A href="/users" class="inline-flex items-center text-blue-600 hover:text-blue-700 mb-6 no-underline">
        <span class="mr-2">←</span> Back to Users
      </A>

      <Suspense
        fallback={<div class="mt-5 text-gray-500">Loading user...</div>}
      >
        <Show when={data()?.user} fallback={<div class="text-red-500">User not found</div>}>
          {(user) => (
            <div class="mt-5">
              <h1 class="text-3xl font-bold text-gray-900 mb-6">{user().name}</h1>

              <div class="bg-white border border-gray-200 p-6 rounded-xl mt-4">
                <div class="mb-4">
                  <label class="block text-gray-600 text-sm mb-1">
                    ID
                  </label>
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

              <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <h3 class="text-lg font-semibold text-blue-900 mb-2">
                  Dynamic Route
                </h3>
                <p class="text-blue-800 text-sm">
                  This page uses a dynamic route segment: <code class="bg-blue-100 px-2 py-1 rounded">[id]</code>
                  <br />
                  Current ID from URL: <strong>{params.id}</strong>
                </p>
              </div>
            </div>
          )}
        </Show>
      </Suspense>
    </MainLayout>
  );
}
