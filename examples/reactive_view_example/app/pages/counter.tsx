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
      <div class="bg-white rounded-2xl shadow-sm p-8">
        <p class="text-gray-700 mb-8 text-base">
          This page demonstrates SolidJS reactivity with signals and effects.
          The counter state is managed entirely on the client side.
        </p>

        <div class="bg-gradient-to-br from-amber-50 to-orange-50 border-2 border-amber-200 rounded-2xl p-12 text-center my-8 shadow-sm">
          <div class="text-7xl font-bold text-amber-900 mb-3">
            {count()}
          </div>
          <p class="text-amber-700 text-sm font-medium tracking-wider uppercase">Current Count</p>
        </div>

        <div class="flex flex-wrap justify-center gap-3 mb-10">
          <button 
            onClick={() => setCount(c => c - 1)}
            class="bg-red-500 hover:bg-red-600 text-white px-8 py-3.5 rounded-xl font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            - Decrement
          </button>
          
          <button 
            onClick={() => setCount(0)}
            class="bg-gray-600 hover:bg-gray-700 text-white px-8 py-3.5 rounded-xl font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            Reset
          </button>
          
          <button 
            onClick={() => setCount(c => c + 1)}
            class="bg-green-500 hover:bg-green-600 text-white px-8 py-3.5 rounded-xl font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            + Increment
          </button>
        </div>

        <div class={`mt-8 p-6 rounded-xl text-center transition-all ${
          autoIncrement() ? "bg-green-50 border-2 border-green-300 shadow-sm" : "bg-gray-50 border-2 border-gray-200"
        }`}>
          <label class="cursor-pointer select-none flex items-center justify-center gap-3">
            <input 
              type="checkbox" 
              checked={autoIncrement()}
              onChange={(e) => setAutoIncrement(e.target.checked)}
              class="w-5 h-5 cursor-pointer"
            />
            <span class="text-gray-800 font-medium">Auto-increment every second (using SolidJS effects)</span>
          </label>
        </div>

        <div class="mt-10">
          <h3 class="text-xl font-bold text-gray-900 mb-4">How This Works</h3>
          <pre class="bg-gray-900 text-gray-100 p-6 rounded-xl overflow-auto text-sm leading-relaxed shadow-md">
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
      </div>
    </MainLayout>
  );
}
