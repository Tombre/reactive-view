import { For, Suspense } from "solid-js";
import { A } from "@solidjs/router";
import { useLoaderData } from "#loaders/users/index";
import MainLayout from "../components/MainLayout";

export default function UsersIndexPage() {
  const data = useLoaderData();

  // Generate initials from name
  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  // Generate a consistent color based on name
  const getAvatarColor = (name: string) => {
    const colors = [
      "bg-blue-100 text-blue-700",
      "bg-emerald-100 text-emerald-700",
      "bg-purple-100 text-purple-700",
      "bg-amber-100 text-amber-700",
      "bg-rose-100 text-rose-700",
      "bg-cyan-100 text-cyan-700",
    ];
    const index = name.charCodeAt(0) % colors.length;
    return colors[index];
  };

  return (
    <MainLayout
      title="All Users"
      description="This page demonstrates loading data from a Rails loader."
    >
      <Suspense
        fallback={
          <div class="bg-white rounded-xl border border-gray-200 p-8">
            <div class="animate-pulse space-y-4">
              <div class="h-4 bg-gray-200 rounded w-1/4"></div>
              <div class="space-y-3">
                <div class="h-16 bg-gray-100 rounded-lg"></div>
                <div class="h-16 bg-gray-100 rounded-lg"></div>
                <div class="h-16 bg-gray-100 rounded-lg"></div>
              </div>
            </div>
          </div>
        }
      >
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          {/* Header */}
          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <div class="flex items-center justify-between">
              <p class="text-sm text-gray-600">
                Showing <span class="font-medium text-gray-900">{data()?.users?.length || 0}</span> of{" "}
                <span class="font-medium text-gray-900">{data()?.total || 0}</span> users
              </p>
            </div>
          </div>

          {/* User List */}
          <div class="divide-y divide-gray-200">
            <For each={data()?.users || []}>
              {(user) => (
                <A
                  href={`/users/${user.id}`}
                  class="flex items-center gap-4 px-6 py-4 hover:bg-gray-50 transition-colors group"
                >
                  {/* Avatar */}
                  <div
                    class={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-semibold flex-shrink-0 ${getAvatarColor(user.name)}`}
                  >
                    {getInitials(user.name)}
                  </div>

                  {/* User Info */}
                  <div class="flex-1 min-w-0">
                    <p class="font-medium text-gray-900 group-hover:text-blue-600 transition-colors truncate">
                      {user.name}
                    </p>
                    <p class="text-sm text-gray-500 truncate">{user.email}</p>
                  </div>

                  {/* Chevron */}
                  <svg
                    class="w-5 h-5 text-gray-400 group-hover:text-blue-500 transition-colors flex-shrink-0"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </A>
              )}
            </For>
          </div>
        </div>

        {/* Info Box */}
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
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
              <h4 class="text-sm font-semibold text-blue-900">Loader Data Source</h4>
              <p class="text-sm text-blue-700 mt-1">
                User data is loaded from{" "}
                <code class="px-1.5 py-0.5 bg-blue-100 text-blue-800 rounded text-xs font-mono">
                  app/pages/users/index.loader.rb
                </code>
              </p>
            </div>
          </div>
        </div>
      </Suspense>
    </MainLayout>
  );
}
