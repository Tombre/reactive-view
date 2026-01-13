import MainLayout from "./components/MainLayout";

export default function AboutPage() {
  return (
    <MainLayout
      title="About ReactiveView"
      description="A Ruby on Rails view framework gem for creating modern reactive frontends."
    >
      {/* Features Section */}
      <div class="bg-white rounded-xl border border-gray-200 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-6">Features</h2>
        <div class="grid gap-4 sm:grid-cols-2">
          <div class="flex items-start gap-3 p-4 bg-gray-50 rounded-lg">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900">SSR</h3>
              <p class="text-sm text-gray-600 mt-0.5">Server-side rendering with SolidJS hydration</p>
            </div>
          </div>

          <div class="flex items-start gap-3 p-4 bg-gray-50 rounded-lg">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900">Type Safety</h3>
              <p class="text-sm text-gray-600 mt-0.5">Automatic TypeScript types from Ruby loaders</p>
            </div>
          </div>

          <div class="flex items-start gap-3 p-4 bg-gray-50 rounded-lg">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900">File-based Routing</h3>
              <p class="text-sm text-gray-600 mt-0.5">
                SolidStart-style routing from <code class="px-1 py-0.5 bg-white text-gray-800 rounded text-xs font-mono">app/pages/</code>
              </p>
            </div>
          </div>

          <div class="flex items-start gap-3 p-4 bg-gray-50 rounded-lg">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <h3 class="font-semibold text-gray-900">Rails Integration</h3>
              <p class="text-sm text-gray-600 mt-0.5">Use Rails for auth, models, and business logic</p>
            </div>
          </div>
        </div>
      </div>

      {/* Architecture Section */}
      <div class="bg-white rounded-xl border border-gray-200 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-2">Architecture</h2>
        <p class="text-gray-600 mb-6">
          ReactiveView works by coordinating between Rails and a SolidStart daemon:
        </p>
        
        <div class="relative">
          {/* Timeline line */}
          <div class="absolute left-4 top-6 bottom-6 w-0.5 bg-gray-200" />
          
          <div class="space-y-4">
            <div class="relative flex items-start gap-4 pl-2">
              <div class="flex-shrink-0 w-5 h-5 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center z-10">
                1
              </div>
              <p class="text-gray-700 pt-0.5">Rails receives the HTTP request</p>
            </div>

            <div class="relative flex items-start gap-4 pl-2">
              <div class="flex-shrink-0 w-5 h-5 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center z-10">
                2
              </div>
              <p class="text-gray-700 pt-0.5">Your loader runs (auth, data fetching, etc.)</p>
            </div>

            <div class="relative flex items-start gap-4 pl-2">
              <div class="flex-shrink-0 w-5 h-5 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center z-10">
                3
              </div>
              <p class="text-gray-700 pt-0.5">Rails asks SolidStart to render the page</p>
            </div>

            <div class="relative flex items-start gap-4 pl-2">
              <div class="flex-shrink-0 w-5 h-5 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center z-10">
                4
              </div>
              <p class="text-gray-700 pt-0.5">SolidStart calls back to Rails for loader data</p>
            </div>

            <div class="relative flex items-start gap-4 pl-2">
              <div class="flex-shrink-0 w-5 h-5 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center z-10">
                5
              </div>
              <p class="text-gray-700 pt-0.5">Rendered HTML is returned to the client</p>
            </div>

            <div class="relative flex items-start gap-4 pl-2">
              <div class="flex-shrink-0 w-5 h-5 rounded-full bg-blue-600 text-white text-xs font-bold flex items-center justify-center z-10">
                6
              </div>
              <p class="text-gray-700 pt-0.5">SolidJS hydrates for client-side interactivity</p>
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
