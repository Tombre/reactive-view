import { A, useLocation } from "@solidjs/router";

export default function Navigation() {
  const location = useLocation();
  
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

  return (
    <header class="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          {/* Logo / Brand */}
          <A href="/" class="flex items-center gap-2 text-gray-900 hover:text-gray-700 transition-colors">
            <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
              <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <span class="font-bold text-lg">ReactiveView</span>
          </A>

          {/* Navigation Links */}
          <nav class="flex items-center gap-2">
            <A href="/" class={navLinkClass("/", true)}>
              Home
            </A>
            <A href="/about" class={navLinkClass("/about", true)}>
              About
            </A>
            <A href="/users" class={navLinkClass("/users")}>
              Users
            </A>
            <A href="/dashboard" class={navLinkClass("/dashboard")}>
              Dashboard
            </A>
            <A href="/counter" class={navLinkClass("/counter", true)}>
              Counter
            </A>
          </nav>
        </div>
      </div>
    </header>
  );
}
