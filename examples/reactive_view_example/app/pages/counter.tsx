import { createSignal, createEffect, onCleanup } from "solid-js";
import MainLayout from "./components/MainLayout";

export default function CounterPage() {
  const [count, setCount] = createSignal(0);
  const [autoIncrement, setAutoIncrement] = createSignal(false);

  // Demo of SolidJS effects
  createEffect(() => {
    if (autoIncrement()) {
      const interval = setInterval(() => {
        setCount((c) => c + 1);
      }, 1000);

      onCleanup(() => clearInterval(interval));
    }
  });

  return (
    <MainLayout
      title="Reactive Counter Demo"
      description="This page demonstrates SolidJS reactivity with signals and effects."
    >
      <div class="bg-white rounded-xl border border-gray-200 p-8">
        {/* Counter Display */}
        <div class="bg-gray-50 rounded-xl p-8 text-center mb-8">
          <div class="text-6xl font-bold text-gray-900 mb-2">{count()}</div>
          <p class="text-sm font-medium text-gray-500 uppercase tracking-wider">
            Current Count
          </p>
        </div>

        {/* Counter Controls */}
        <div class="flex flex-wrap justify-center gap-3 mb-8">
          <button
            onClick={() => setCount((c) => c - 1)}
            class="inline-flex items-center justify-center px-6 py-3 bg-white text-gray-700 text-sm font-medium rounded-lg border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
            </svg>
            Decrement
          </button>

          <button
            onClick={() => setCount(0)}
            class="inline-flex items-center justify-center px-6 py-3 bg-gray-600 text-white text-sm font-medium rounded-lg hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-colors"
          >
            Reset
          </button>

          <button
            onClick={() => setCount((c) => c + 1)}
            class="inline-flex items-center justify-center px-6 py-3 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Increment
          </button>
        </div>

        {/* Auto-increment Toggle */}
        <div
          class={`p-4 rounded-xl text-center transition-all ${
            autoIncrement()
              ? "bg-blue-50 border-2 border-blue-200"
              : "bg-gray-50 border-2 border-transparent"
          }`}
        >
          <label class="inline-flex items-center gap-3 cursor-pointer select-none">
            {/* Custom Toggle Switch */}
            <div class="relative">
              <input
                type="checkbox"
                checked={autoIncrement()}
                onChange={(e) => setAutoIncrement(e.target.checked)}
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-blue-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
            </div>
            <span class="text-gray-700 font-medium">
              Auto-increment every second
            </span>
            <span class="text-xs text-gray-500">(using SolidJS effects)</span>
          </label>
        </div>
      </div>

      {/* Code Example */}
      <div class="bg-white rounded-xl border border-gray-200 p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">How This Works</h3>
        <pre class="bg-gray-900 text-gray-100 p-4 rounded-xl overflow-x-auto text-sm leading-relaxed">
          <code>{`const [count, setCount] = createSignal(0);
const [autoIncrement, setAutoIncrement] = createSignal(false);

createEffect(() => {
  if (autoIncrement()) {
    const interval = setInterval(() => {
      setCount(c => c + 1);
    }, 1000);
    onCleanup(() => clearInterval(interval));
  }
});`}</code>
        </pre>
      </div>

      {/* Info Box */}
      <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <div class="flex gap-3">
          <svg
            class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <h4 class="text-sm font-semibold text-blue-900">Client-Side State</h4>
            <p class="text-sm text-blue-700 mt-1">
              The counter state is managed entirely on the client side using SolidJS signals.
              The page is initially server-rendered, then hydrated for interactivity.
            </p>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
