import { createSignal } from "solid-js";
import MainLayout from "./components/MainLayout";

export default function HomePage() {
  const [count, setCount] = createSignal(0);

  return (
    <MainLayout title="Welcome to ReactiveView!">
      <p class="text-gray-700 mb-6">
        This page is rendered by <strong>SolidJS</strong> with server-side
        rendering, powered by your <strong>Rails</strong> backend.
      </p>

      <div class="bg-sky-50 border border-sky-200 rounded-lg p-5 mt-5">
        <h3 class="text-lg font-semibold text-gray-900 mb-3">Interactive Counter (Client-Side State)</h3>
        <p class="text-gray-700 mb-4">
          Count: <strong class="text-xl text-sky-600">{count()}</strong>
        </p>
        <div class="flex gap-2">
          <button
            onClick={() => setCount((c) => c + 1)}
            class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded font-medium transition-colors"
          >
            Increment
          </button>
          <button
            onClick={() => setCount(0)}
            class="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded font-medium transition-colors"
          >
            Reset
          </button>
        </div>
      </div>

      <div class="mt-8 text-gray-600">
        <h3 class="text-lg font-semibold text-gray-900 mb-3">How It Works</h3>
        <ul class="space-y-2">
          <li class="flex items-start">
            <span class="text-blue-500 mr-2">•</span>
            Pages are defined as TSX files in <code class="bg-gray-100 px-2 py-1 rounded text-sm">app/pages/</code>
          </li>
          <li class="flex items-start">
            <span class="text-blue-500 mr-2">•</span>
            Data is loaded via Ruby loaders (<code class="bg-gray-100 px-2 py-1 rounded text-sm">*.loader.rb</code>)
          </li>
          <li class="flex items-start">
            <span class="text-blue-500 mr-2">•</span>
            Full SSR with hydration for interactivity
          </li>
          <li class="flex items-start">
            <span class="text-blue-500 mr-2">•</span>
            Type-safe communication between Rails and TypeScript
          </li>
        </ul>
      </div>
    </MainLayout>
  );
}
