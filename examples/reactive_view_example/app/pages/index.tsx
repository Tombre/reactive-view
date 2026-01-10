import { createSignal } from "solid-js";
import MainLayout from "./components/MainLayout";

export default function HomePage() {
  const [count, setCount] = createSignal(0);

  return (
    <MainLayout title="Welcome to ReactiveView!">
      <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
        <p class="text-lg text-gray-700 leading-relaxed">
          This page is rendered by <strong class="text-blue-600">SolidJS</strong> with server-side
          rendering, powered by your <strong class="text-blue-600">Rails</strong> backend.
        </p>
      </div>

      <div class="bg-gradient-to-br from-sky-50 to-blue-50 border border-sky-200 rounded-xl shadow-md p-6 mb-8">
        <h2 class="text-2xl font-bold text-gray-900 mb-4">Interactive Counter</h2>
        <p class="text-sm text-gray-600 mb-4">Client-Side State Management</p>
        <div class="bg-white rounded-lg p-6 mb-6">
          <p class="text-gray-600 mb-2">Count:</p>
          <p class="text-5xl font-bold text-blue-600">{count()}</p>
        </div>
        <div class="flex gap-3">
          <button
            onClick={() => setCount((c) => c + 1)}
            class="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            Increment
          </button>
          <button
            onClick={() => setCount(0)}
            class="flex-1 bg-gray-600 hover:bg-gray-700 text-white px-6 py-3 rounded-lg font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            Reset
          </button>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow-sm p-6">
        <h2 class="text-2xl font-bold text-gray-900 mb-6">How It Works</h2>
        <ul class="space-y-4">
          <li class="flex items-start">
            <span class="text-2xl text-blue-500 mr-4 mt-1">•</span>
            <div>
              <p class="text-gray-800 font-medium">Pages are defined as TSX files in</p>
              <code class="bg-gray-100 text-blue-600 px-3 py-1 rounded-md text-sm font-mono mt-1 inline-block">app/pages/</code>
            </div>
          </li>
          <li class="flex items-start">
            <span class="text-2xl text-blue-500 mr-4 mt-1">•</span>
            <div>
              <p class="text-gray-800 font-medium">Data is loaded via Ruby loaders</p>
              <code class="bg-gray-100 text-blue-600 px-3 py-1 rounded-md text-sm font-mono mt-1 inline-block">*.loader.rb</code>
            </div>
          </li>
          <li class="flex items-start">
            <span class="text-2xl text-blue-500 mr-4 mt-1">•</span>
            <p class="text-gray-800 font-medium">Full SSR with hydration for interactivity</p>
          </li>
          <li class="flex items-start">
            <span class="text-2xl text-blue-500 mr-4 mt-1">•</span>
            <p class="text-gray-800 font-medium">Type-safe communication between Rails and TypeScript</p>
          </li>
        </ul>
      </div>
    </MainLayout>
  );
}
