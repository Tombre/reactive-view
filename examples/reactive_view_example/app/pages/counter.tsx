import { createSignal, createEffect, onCleanup } from "solid-js";
import MainLayout from "./components/MainLayout";

export default function CounterPage() {
  const [count, setCount] = createSignal(0);
  const [autoIncrement, setAutoIncrement] = createSignal(false);

  // Demo of SolidJS effects
  createEffect(() => {
    if (autoIncrement()) {
      const interval = setInterval(() => {
        setCount(c => c + 1);
      }, 1000);

      onCleanup(() => clearInterval(interval));
    }
  });

  return (
    <MainLayout title="Reactive Counter Demo">
      <p class="text-gray-700 mb-6">
        This page demonstrates SolidJS reactivity with signals and effects.
        The counter state is managed entirely on the client side.
      </p>

      <div class="bg-amber-50 border border-amber-200 rounded-xl p-8 text-center my-8">
        <div class="text-6xl font-bold text-amber-800 mb-2">
          {count()}
        </div>
        <p class="text-stone-600 text-sm">Current Count</p>
      </div>

      <div class="flex flex-wrap justify-center gap-3 mb-8">
        <button 
          onClick={() => setCount(c => c - 1)}
          class="bg-red-500 hover:bg-red-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
        >
          - Decrement
        </button>
        
        <button 
          onClick={() => setCount(0)}
          class="bg-gray-500 hover:bg-gray-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
        >
          Reset
        </button>
        
        <button 
          onClick={() => setCount(c => c + 1)}
          class="bg-green-500 hover:bg-green-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
        >
          + Increment
        </button>
      </div>

      <div class={`mt-8 p-5 rounded-lg text-center transition-colors ${
        autoIncrement() ? "bg-green-50 border border-green-200" : "bg-gray-100 border border-gray-200"
      }`}>
        <label class="cursor-pointer select-none flex items-center justify-center gap-2">
          <input 
            type="checkbox" 
            checked={autoIncrement()}
            onChange={(e) => setAutoIncrement(e.target.checked)}
            class="w-4 h-4"
          />
          <span class="text-gray-700">Auto-increment every second (using SolidJS effects)</span>
        </label>
      </div>

      <div class="mt-8 text-gray-600">
        <h3 class="text-lg font-semibold text-gray-900 mb-3">How This Works</h3>
        <pre class="bg-gray-800 text-gray-100 p-4 rounded-lg overflow-auto text-sm">
{`const [count, setCount] = createSignal(0);
const [autoIncrement, setAutoIncrement] = createSignal(false);

createEffect(() => {
  if (autoIncrement()) {
    const interval = setInterval(() => {
      setCount(c => c + 1);
    }, 1000);
    onCleanup(() => clearInterval(interval));
  }
});`}
        </pre>
      </div>
    </MainLayout>
  );
}
