import MainLayout from "./components/MainLayout";

export default function AboutPage() {
  return (
    <MainLayout title="About ReactiveView">
      <p class="text-gray-700 mb-6">
        ReactiveView is a Ruby on Rails "view framework" gem for creating modern 
        reactive frontends for your Rails application.
      </p>

      <h2 class="text-2xl font-bold text-gray-900 mb-4">Features</h2>
      <ul class="space-y-3 mb-8">
        <li class="flex items-start">
          <span class="text-green-500 mr-3 mt-1">✓</span>
          <div>
            <strong class="text-gray-900">SSR</strong> - Server-side rendering with SolidJS hydration
          </div>
        </li>
        <li class="flex items-start">
          <span class="text-green-500 mr-3 mt-1">✓</span>
          <div>
            <strong class="text-gray-900">Type Safety</strong> - Automatic TypeScript types from Ruby loaders
          </div>
        </li>
        <li class="flex items-start">
          <span class="text-green-500 mr-3 mt-1">✓</span>
          <div>
            <strong class="text-gray-900">File-based Routing</strong> - SolidStart-style routing from <code class="bg-gray-100 px-2 py-1 rounded text-sm">app/pages/</code>
          </div>
        </li>
        <li class="flex items-start">
          <span class="text-green-500 mr-3 mt-1">✓</span>
          <div>
            <strong class="text-gray-900">Rails Integration</strong> - Use Rails for auth, models, and business logic
          </div>
        </li>
      </ul>

      <h2 class="text-2xl font-bold text-gray-900 mb-4">Architecture</h2>
      <p class="text-gray-700 mb-4">
        ReactiveView works by coordinating between Rails and a SolidStart daemon:
      </p>
      <ol class="space-y-2 text-gray-700">
        <li class="flex">
          <span class="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0">1</span>
          Rails receives the HTTP request
        </li>
        <li class="flex">
          <span class="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0">2</span>
          Your loader runs (auth, data fetching, etc.)
        </li>
        <li class="flex">
          <span class="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0">3</span>
          Rails asks SolidStart to render the page
        </li>
        <li class="flex">
          <span class="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0">4</span>
          SolidStart calls back to Rails for loader data
        </li>
        <li class="flex">
          <span class="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0">5</span>
          Rendered HTML is returned to the client
        </li>
        <li class="flex">
          <span class="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0">6</span>
          SolidJS hydrates for client-side interactivity
        </li>
      </ol>
    </MainLayout>
  );
}
