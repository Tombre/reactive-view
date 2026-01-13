import { createSignal } from "solid-js";
import MainLayout from "./components/MainLayout";

export default function HomePage() {
  const [count, setCount] = createSignal(0);

  return (
    <MainLayout title="Explore ReactiveView">
      <section class="bg-white rounded-2xl shadow-sm p-8">
        <p class="text-base text-gray-600 uppercase tracking-[0.2em] font-semibold mb-2">Getting started</p>
        <h2 class="text-3xl font-semibold text-gray-900 leading-tight mb-4">
          Welcome to a fully server-rendered SolidJS experience powered by Rails.
        </h2>
        <p class="text-lg text-gray-700 leading-relaxed">
          This page is rendered by <strong class="text-blue-600">SolidJS</strong> with server-side
          rendering, powered by your <strong class="text-blue-600">Rails</strong> backend.
        </p>
      </section>

      <section class="bg-gradient-to-br from-sky-50 to-blue-50 border border-sky-200 rounded-2xl shadow-md p-8">
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-6 mb-6">
          <div>
            <p class="text-xs font-semibold text-blue-500 uppercase tracking-[0.3em] mb-2">Demo</p>
            <h2 class="text-3xl font-bold text-gray-900">Interactive Counter</h2>
            <p class="text-sm text-gray-600">Client-side state management</p>
          </div>
          <div class="bg-white/70 rounded-xl px-5 py-3 text-right">
            <p class="text-xs text-gray-500 uppercase tracking-widest">Current count</p>
            <p class="text-4xl font-bold text-blue-600">{count()}</p>
          </div>
        </div>
        <div class="bg-white rounded-xl p-6 mb-6 border border-white/60 shadow-sm">
          <p class="text-gray-600 mb-2">Tap the controls below to see how client state updates without losing the server-rendered feel.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
          <button
            onClick={() => setCount((c) => c + 1)}
            class="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-8 py-3.5 rounded-xl font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            Increment
          </button>
          <button
            onClick={() => setCount(0)}
            class="flex-1 bg-gray-800 hover:bg-gray-900 text-white px-8 py-3.5 rounded-xl font-semibold transition-all shadow-md hover:shadow-lg active:scale-95"
          >
            Reset
          </button>
        </div>
      </section>

      <section class="bg-white rounded-2xl shadow-sm p-8">
        <p class="text-xs font-semibold text-blue-500 uppercase tracking-[0.3em] mb-2">Architecture</p>
        <h2 class="text-3xl font-bold text-gray-900 mb-4">How ReactiveView Fits Together</h2>
        <p class="text-gray-600 mb-8">Each page combines Rails loaders with SolidJS components to give you a fully typed bridge between the backend and frontend.</p>
        <ul class="space-y-6">
          <li class="flex gap-4">
            <div class="w-3 h-3 mt-2 rounded-full bg-blue-500" />
            <div>
              <p class="text-gray-900 font-semibold mb-1">Pages live in familiar directories</p>
              <p class="text-gray-600">Author interactive views under <code class="bg-gray-100 text-blue-600 px-3 py-1 rounded-md text-sm font-mono">app/pages/</code>.</p>
            </div>
          </li>
          <li class="flex gap-4">
            <div class="w-3 h-3 mt-2 rounded-full bg-blue-500" />
            <div>
              <p class="text-gray-900 font-semibold mb-1">Loaders keep Ruby in the loop</p>
              <p class="text-gray-600">Define data contracts alongside components with <code class="bg-gray-100 text-blue-600 px-3 py-1 rounded-md text-sm font-mono">*.loader.rb</code>.</p>
            </div>
          </li>
          <li class="flex gap-4">
            <div class="w-3 h-3 mt-2 rounded-full bg-blue-500" />
            <div>
              <p class="text-gray-900 font-semibold mb-1">SSR + hydration by default</p>
              <p class="text-gray-600">Enjoy instant paint with SolidJS while preserving client-side interactivity.</p>
            </div>
          </li>
          <li class="flex gap-4">
            <div class="w-3 h-3 mt-2 rounded-full bg-blue-500" />
            <div>
              <p class="text-gray-900 font-semibold mb-1">Type-safe by design</p>
              <p class="text-gray-600">Rail's loaders and SolidJS share types ensuring your data flow stays correct.</p>
            </div>
          </li>
        </ul>
      </section>
    </MainLayout>
  );
}
