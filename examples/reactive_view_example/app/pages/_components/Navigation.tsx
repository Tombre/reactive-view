import { A, Show, useLocation } from "@reactive-view/core";
import { useForm, useLoaderData } from "#loaders/navigation_state";

export default function Navigation() {
  const location = useLocation();
  const authState = useLoaderData();
  const [LogoutForm, logoutSubmission] = useForm("logout");

  const isActive = (path: string, exact = false) => {
    if (exact) {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  const navLinkClass = (path: string, exact = false) => {
    const base = "px-4 py-2 text-sm font-medium rounded-lg transition-colors";
    if (isActive(path, exact)) {
      return `${base} text-blue-700 bg-blue-50`;
    }
    return `${base} text-gray-600 hover:bg-gray-100 hover:text-gray-900`;
  };

  const isAuthenticated = () => authState()?.authenticated === true;
  const userName = () => authState()?.name || authState()?.email || "Account";
  const userInitial = () => userName().trim().charAt(0).toUpperCase() || "A";

  return (
    <header class="sticky top-0 z-50 px-8 py-4">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16 gap-x-12">
          {/* Logo / Brand */}
          <A
            href="/"
            class="flex items-center gap-2 text-gray-900 hover:text-gray-700 transition-colors"
          >
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
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
            </div>
            <span class="font-bold text-lg">ReactiveView</span>
          </A>

          {/* Navigation Links */}
          <nav class="flex items-center gap-4">
            <A href="/" class={navLinkClass("/", true)}>
              Home
            </A>
            <A href="/about" class={navLinkClass("/about", true)}>
              About
            </A>
            <A href="/users" class={navLinkClass("/users")}>
              Users
            </A>
            <A href="/dashboard" class={navLinkClass("/dashboard")} preload={isAuthenticated()}>
              Dashboard
            </A>
            <A href="/counter" class={navLinkClass("/counter", true)}>
              Counter
            </A>
            <A href="/ai/chat" class={navLinkClass("/ai/chat", true)}>
              AI Chat
            </A>
          </nav>

          <Show
            when={isAuthenticated()}
            fallback={
              <div class="flex items-center gap-2">
                <A href="/login" class={navLinkClass("/login", true)}>
                  Sign In
                </A>
                <A
                  href="/register"
                  class="px-4 py-2 text-sm font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 transition-colors"
                >
                  Create Account
                </A>
              </div>
            }
          >
            <div class="flex items-center gap-3">
              <span class="text-sm text-gray-500">Signed in as {userName()}</span>
              <LogoutForm class="inline">
                <button
                  type="submit"
                  disabled={logoutSubmission.pending}
                  class="px-3 py-2 text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors disabled:opacity-60"
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
          </Show>
        </div>
      </div>
    </header>
  );
}
