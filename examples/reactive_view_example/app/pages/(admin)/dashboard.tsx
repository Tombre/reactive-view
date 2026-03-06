import { A, useLocation, createSignal, Show, type ParentProps } from "@reactive-view/core";
import { useForm, useLoaderData } from "#loaders/(admin)/dashboard";
import "../_styles/tailwind.css";

export default function DashboardLayout(props: ParentProps) {
  const data = useLoaderData();
  const [LogoutForm, logoutSubmission] = useForm("logout");
  const [sidebarOpen, setSidebarOpen] = createSignal(true);
  const location = useLocation();

  const isActive = (path: string, exact = false) => {
    if (exact) {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  const navLinkClass = (path: string, exact = false) => {
    const base =
      "flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-lg transition-colors";
    if (isActive(path, exact)) {
      return `${base} text-blue-700 bg-blue-50`;
    }
    return `${base} text-gray-600 hover:bg-gray-100 hover:text-gray-900`;
  };

  const userName = () => data()?.name || "User";
  const userInitial = () => userName().trim().charAt(0).toUpperCase() || "U";

  return (
    <div class="flex min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside
        class={`${
          sidebarOpen() ? "w-64" : "w-0"
        } bg-white border-r border-gray-200 transition-all duration-300 overflow-hidden flex-shrink-0`}
      >
        <div class="p-6">
          {/* Sidebar Header */}
          <div class="flex items-center gap-3 mb-8">
            <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <svg
                class="w-5 h-5 text-white"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"
                />
              </svg>
            </div>
            <span class="text-lg font-semibold text-gray-900">Dashboard</span>
          </div>

          {/* Navigation */}
          <nav class="space-y-1">
            <A href="/dashboard" end class={navLinkClass("/dashboard", true)}>
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z"
                />
              </svg>
              Overview
            </A>
            <A
              href="/dashboard/analytics"
              class={navLinkClass("/dashboard/analytics", true)}
            >
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                />
              </svg>
              Analytics
            </A>
            <A
              href="/dashboard/settings"
              class={navLinkClass("/dashboard/settings", true)}
            >
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              Settings
            </A>
            <A href="/dashboard/reports" class={navLinkClass("/dashboard/reports")}>
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              Reports
            </A>
          </nav>

          {/* Back to Home */}
          <div class="mt-8 pt-6 border-t border-gray-200">
            <A
              href="/"
              class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium text-gray-500 hover:bg-gray-100 hover:text-gray-700 rounded-lg transition-colors"
            >
              <svg
                class="w-5 h-5"
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
              Back to Home
            </A>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <div class="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <header class="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen())}
            class="inline-flex items-center justify-center p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
            aria-label={sidebarOpen() ? "Hide sidebar" : "Show sidebar"}
          >
            <Show
              when={sidebarOpen()}
              fallback={
                <svg
                  class="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                </svg>
              }
            >
              <svg
                class="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 19l-7-7 7-7m8 14l-7-7 7-7"
                />
              </svg>
            </Show>
          </button>

          <div class="flex items-center gap-4">
            <span class="text-sm text-gray-500">Signed in as {userName()}</span>
            <LogoutForm class="inline">
              <button
                type="submit"
                disabled={logoutSubmission.pending}
                class="inline-flex items-center justify-center px-3 py-2 text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors disabled:opacity-60"
              >
                <Show when={logoutSubmission.pending} fallback="Sign out">
                  Signing out...
                </Show>
              </button>
            </LogoutForm>
            <div class="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-sm font-semibold">
              {userInitial()}
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main class="flex-1 p-6 overflow-auto">{props.children}</main>
      </div>
    </div>
  );
}
