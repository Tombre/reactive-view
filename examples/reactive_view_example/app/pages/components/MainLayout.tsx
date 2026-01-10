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
    <div class="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {props.showNav !== false && (
          <nav class="bg-white shadow-sm rounded-lg mb-8 p-2">
            <div class="flex flex-wrap gap-2">
              <A 
                href="/" 
                class={`px-4 py-2 rounded-md transition-all font-medium text-sm ${
                  isActive("/", true) 
                    ? "bg-blue-600 text-white shadow-md" 
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                Home
              </A>
              <A 
                href="/about" 
                class={`px-4 py-2 rounded-md transition-all font-medium text-sm ${
                  isActive("/about", true) 
                    ? "bg-blue-600 text-white shadow-md" 
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                About
              </A>
              <A 
                href="/users" 
                class={`px-4 py-2 rounded-md transition-all font-medium text-sm ${
                  isActive("/users") 
                    ? "bg-blue-600 text-white shadow-md" 
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                Users
              </A>
              <A 
                href="/dashboard" 
                class={`px-4 py-2 rounded-md transition-all font-medium text-sm ${
                  isActive("/dashboard") 
                    ? "bg-blue-600 text-white shadow-md" 
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                Dashboard
              </A>
              <A 
                href="/counter" 
                class={`px-4 py-2 rounded-md transition-all font-medium text-sm ${
                  isActive("/counter", true) 
                    ? "bg-blue-600 text-white shadow-md" 
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                Counter
              </A>
            </div>
          </nav>
        )}
        
        {props.title && (
          <h1 class="text-4xl font-bold text-gray-900 mb-8 tracking-tight">{props.title}</h1>
        )}
        
        {props.children}
      </div>
    </div>
  );
}