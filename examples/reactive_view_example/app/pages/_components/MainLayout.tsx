import { type ParentProps } from "@reactive-view/core";
import Navigation from "./Navigation";
import "../_styles/tailwind.css";

interface MainLayoutProps extends ParentProps {
  title?: string;
  description?: string;
  showNav?: boolean;
}

export default function MainLayout(props: MainLayoutProps) {
  return (
    <div class="min-h-screen bg-gray-50">
      {props.showNav !== false && <Navigation />}

      <main class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {props.title && (
          <div class="mb-8">
            <h1 class="text-2xl font-bold text-gray-900">{props.title}</h1>
            {props.description && (
              <p class="mt-1 text-gray-600">{props.description}</p>
            )}
          </div>
        )}

        <div class="space-y-6">{props.children}</div>
      </main>
    </div>
  );
}
