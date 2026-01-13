import { A, useLocation } from "@solidjs/router";

export default function Navigation() {
  const location = useLocation();
  
  const isActive = (path: string, exact = false) => {
    if (exact) {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  return (
    <nav class="bg-white/80 backdrop-blur-sm rounded-2xl py-5 mt-2 mb-16">
      <div class="flex flex-wrap items-center gap-3 px-6">
        <div class="flex flex-wrap gap-2">
          <A 
            href="/" 
            class={`px-5 py-3 rounded-lg transition-all font-semibold text-sm ${
              isActive("/", true) 
                ? "bg-blue-600 text-white" 
                : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            Home
          </A>
          <A 
            href="/about" 
            class={`px-5 py-3 rounded-lg transition-all font-semibold text-sm ${
              isActive("/about", true) 
                ? "bg-blue-600 text-white" 
                : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            About
          </A>
          <A 
            href="/users" 
            class={`px-5 py-3 rounded-lg transition-all font-semibold text-sm ${
              isActive("/users") 
                ? "bg-blue-600 text-white" 
                : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            Users
          </A>
          <A 
            href="/dashboard" 
            class={`px-5 py-3 rounded-lg transition-all font-semibold text-sm ${
              isActive("/dashboard") 
                ? "bg-blue-600 text-white" 
                : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            Dashboard
          </A>
          <A 
            href="/counter" 
            class={`px-5 py-3 rounded-lg transition-all font-semibold text-sm ${
              isActive("/counter", true) 
                ? "bg-blue-600 text-white" 
                : "text-gray-700 hover:bg-gray-100"
            }`}
          >
            Counter
          </A>
        </div>
      </div>
    </nav>
  );
}
