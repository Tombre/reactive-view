import { createSignal } from "@reactive-view/core";
import MainLayout from "./_components/MainLayout";

export default function HomePage() {
  const [count, setCount] = createSignal(0);

  return (
    <MainLayout>
      {/* Hero Section */}
      <div class="bg-white rounded-xl border border-gray-200 p-8">
        <span class="inline-block text-xs font-semibold text-blue-600 uppercase tracking-wider mb-3">
          Getting Started
        </span>
        <h1 class="text-3xl font-bold text-gray-900 mb-4">
          Welcome to ReactiveView
        </h1>
        <p class="text-lg text-gray-600 max-w-2xl">
          A fully server-rendered SolidJS experience powered by Rails. Build
          modern, reactive frontends while keeping all your business logic in
          Ruby.
        </p>
      </div>

      {/* Interactive Counter Demo */}
      <div class="bg-white rounded-xl border border-gray-200 p-8">
        <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6 mb-6">
          <div>
            <span class="inline-block text-xs font-semibold text-blue-600 uppercase tracking-wider mb-2">
              Demo
            </span>
            <h2 class="text-xl font-bold text-gray-900">Interactive Counter</h2>
            <p class="text-gray-600 mt-1">
              Client-side state management with SolidJS signals
            </p>
          </div>
          <div class="bg-gray-50 rounded-xl px-6 py-4 text-center min-w-32">
            <p class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
              Count
            </p>
            <p class="text-4xl font-bold text-blue-600">{count()}</p>
          </div>
        </div>

        <div class="bg-gray-50 rounded-lg p-4 mb-6">
          <p class="text-sm text-gray-600">
            Tap the controls below to see how client state updates without
            losing the server-rendered feel.
          </p>
        </div>

        <div class="flex flex-col sm:flex-row gap-3">
          <button
            onClick={() => setCount((c) => c + 1)}
            class="flex-1 inline-flex items-center justify-center px-6 py-3 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            Increment
          </button>
          <button
            onClick={() => setCount(0)}
            class="flex-1 inline-flex items-center justify-center px-6 py-3 bg-white text-gray-700 text-sm font-medium rounded-lg border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            Reset
          </button>
        </div>
      </div>

      {/* Architecture Section */}
      <div class="bg-white rounded-xl border border-gray-200 p-8">
        <span class="inline-block text-xs font-semibold text-blue-600 uppercase tracking-wider mb-3">
          Architecture
        </span>
        <h2 class="text-xl font-bold text-gray-900 mb-2">
          How ReactiveView Fits Together
        </h2>
        <p class="text-gray-600 mb-8">
          Each page combines Rails loaders with SolidJS components for a fully
          typed bridge between backend and frontend.
        </p>

        <div class="grid gap-6 md:grid-cols-2">
          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
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
                  d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 mb-1">
                Pages in familiar directories
              </h3>
              <p class="text-sm text-gray-600">
                Author interactive views under{" "}
                <code class="px-1.5 py-0.5 bg-gray-100 text-gray-800 rounded text-xs font-mono">
                  app/pages/
                </code>
              </p>
            </div>
          </div>

          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
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
                  d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"
                />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 mb-1">
                Loaders keep Ruby in the loop
              </h3>
              <p class="text-sm text-gray-600">
                Define data contracts with{" "}
                <code class="px-1.5 py-0.5 bg-gray-100 text-gray-800 rounded text-xs font-mono">
                  *.loader.rb
                </code>{" "}
                files
              </p>
            </div>
          </div>

          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
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
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 mb-1">
                SSR + hydration by default
              </h3>
              <p class="text-sm text-gray-600">
                Instant paint with SolidJS while preserving client-side
                interactivity
              </p>
            </div>
          </div>

          <div class="flex gap-4">
            <div class="flex-shrink-0 w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
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
                  d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900 mb-1">
                Type-safe by design
              </h3>
              <p class="text-sm text-gray-600">
                Rails loaders and SolidJS share types for correct data flow
              </p>
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
