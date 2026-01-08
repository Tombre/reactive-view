import { A, useLocation } from "@solidjs/router";
import { createSignal, type ParentProps } from "solid-js";
import "~/styles/tailwind.css";

export default function DashboardLayout(props: ParentProps) {
  const [sidebarOpen, setSidebarOpen] = createSignal(true);
  const location = useLocation();

  const isActive = (path: string, exact = false) => {
    if (exact) {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div class="flex min-h-screen font-sans">
      {/* Sidebar */}
      <aside class={`${sidebarOpen() ? "w-64" : "w-0"} bg-gray-800 text-white transition-all duration-300 overflow-hidden flex-shrink-0`}>
        <div class="p-5">
          <h2 class="text-xl font-semibold mb-5">
            Dashboard
          </h2>

          <nav>
            <ul class="space-y-2">
              <li>
                <A
                  href="/dashboard"
                  end
                  class={`block px-3 py-2.5 rounded-md text-sm font-medium transition-colors ${
                    isActive("/dashboard", true) 
                      ? "bg-gray-700 text-white" 
                      : "text-gray-300 hover:bg-gray-700 hover:text-white"
                  }`}
                >
                  📊 Overview
                </A>
              </li>
              <li>
                <A
                  href="/dashboard/analytics"
                  class={`block px-3 py-2.5 rounded-md text-sm font-medium transition-colors ${
                    isActive("/dashboard/analytics", true) 
                      ? "bg-gray-700 text-white" 
                      : "text-gray-300 hover:bg-gray-700 hover:text-white"
                  }`}
                >
                  📈 Analytics
                </A>
              </li>
              <li>
                <A
                  href="/dashboard/settings"
                  class={`block px-3 py-2.5 rounded-md text-sm font-medium transition-colors ${
                    isActive("/dashboard/settings", true) 
                      ? "bg-gray-700 text-white" 
                      : "text-gray-300 hover:bg-gray-700 hover:text-white"
                  }`}
                >
                  ⚙️ Settings
                </A>
              </li>
            </ul>
          </nav>

          <div class="mt-8 pt-5 border-t border-gray-700">
            <A
              href="/"
              class="block px-3 py-2.5 text-gray-400 hover:bg-gray-700 hover:text-white rounded-md text-sm transition-colors no-underline"
            >
              ← Back to Home
            </A>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <div class="flex-1 flex flex-col">
        {/* Header */}
        <header class="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen())}
            class="bg-gray-100 border border-gray-300 px-3 py-2 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors"
          >
            {sidebarOpen() ? "← Hide Sidebar" : "→ Show Sidebar"}
          </button>

          <div class="text-gray-500 text-sm">
            Nested Layout Example
          </div>
        </header>

        {/* Child Routes */}
        <main class="flex-1 p-6 bg-gray-50">
          {props.children}
        </main>
      </div>
    </div>
  );
}
