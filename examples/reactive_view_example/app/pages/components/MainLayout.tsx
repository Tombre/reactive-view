import { A, useLocation } from "@solidjs/router";
import { type ParentProps } from "solid-js";
import "~/styles/tailwind.css";

interface MainLayoutProps extends ParentProps {
  title?: string;
  showNav?: boolean;
}

export default function MainLayout(props: MainLayoutProps) {
  const location = useLocation();
  
  const isActive = (path: string, exact = false) => {
    if (exact) {
      return location.pathname === path;
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div class="min-h-screen bg-gray-50 font-sans">
      <div class="max-w-4xl mx-auto px-10 py-10">
        {props.showNav !== false && (
          <nav class="bg-gray-100 p-4 rounded-lg mb-5">
            <div class="flex flex-wrap gap-4">
              <A 
                href="/" 
                class={`px-3 py-1 rounded transition-colors ${
                  isActive("/", true) 
                    ? "bg-blue-500 text-white font-semibold" 
                    : "text-gray-700 hover:bg-gray-200"
                }`}
              >
                Home
              </A>
              <A 
                href="/about" 
                class={`px-3 py-1 rounded transition-colors ${
                  isActive("/about", true) 
                    ? "bg-blue-500 text-white font-semibold" 
                    : "text-gray-700 hover:bg-gray-200"
                }`}
              >
                About
              </A>
              <A 
                href="/users" 
                class={`px-3 py-1 rounded transition-colors ${
                  isActive("/users") 
                    ? "bg-blue-500 text-white font-semibold" 
                    : "text-gray-700 hover:bg-gray-200"
                }`}
              >
                Users
              </A>
              <A 
                href="/dashboard" 
                class={`px-3 py-1 rounded transition-colors ${
                  isActive("/dashboard") 
                    ? "bg-blue-500 text-white font-semibold" 
                    : "text-gray-700 hover:bg-gray-200"
                }`}
              >
                Dashboard
              </A>
              <A 
                href="/counter" 
                class={`px-3 py-1 rounded transition-colors ${
                  isActive("/counter", true) 
                    ? "bg-blue-500 text-white font-semibold" 
                    : "text-gray-700 hover:bg-gray-200"
                }`}
              >
                Counter
              </A>
            </div>
          </nav>
        )}
        
        {props.title && (
          <h1 class="text-3xl font-bold text-gray-900 mb-6">{props.title}</h1>
        )}
        
        {props.children}
      </div>
    </div>
  );
}