export default function DashboardOverview() {
  return (
    <div>
      <h1 class="text-2xl font-bold text-gray-900 mb-4">
        Dashboard Overview
      </h1>

      <p class="text-gray-600 mb-6">
        Welcome to your dashboard! This page demonstrates nested layouts in
        ReactiveView.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 mt-5">
        {/* Card 1 */}
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <div class="text-gray-600 text-sm">
            Total Users
          </div>
          <div class="text-3xl font-bold text-gray-900 mt-2">
            1,234
          </div>
          <div class="text-emerald-600 text-sm mt-1">
            +12% from last month
          </div>
        </div>

        {/* Card 2 */}
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <div class="text-gray-600 text-sm">Revenue</div>
          <div class="text-3xl font-bold text-gray-900 mt-2">
            $12,345
          </div>
          <div class="text-emerald-600 text-sm mt-1">
            +8% from last month
          </div>
        </div>

        {/* Card 3 */}
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <div class="text-gray-600 text-sm">
            Active Sessions
          </div>
          <div class="text-3xl font-bold text-gray-900 mt-2">
            456
          </div>
          <div class="text-red-500 text-sm mt-1">
            -3% from last month
          </div>
        </div>
      </div>

      <div class="mt-8 bg-blue-50 border border-blue-200 p-5 rounded-xl">
        <h3 class="text-lg font-semibold text-blue-900 mb-3">
          How Nested Layouts Work
        </h3>
        <ul class="space-y-2 text-blue-800">
          <li class="flex items-start">
            <span class="text-blue-500 mr-2 mt-1">•</span>
            The <code class="bg-blue-100 px-2 py-1 rounded text-sm">dashboard.tsx</code> file defines the layout with sidebar and header
          </li>
          <li class="flex items-start">
            <span class="text-blue-500 mr-2 mt-1">•</span>
            Child pages like <code class="bg-blue-100 px-2 py-1 rounded text-sm">dashboard/index.tsx</code>, <code class="bg-blue-100 px-2 py-1 rounded text-sm">dashboard/analytics.tsx</code>, etc. are rendered in the <code class="bg-blue-100 px-2 py-1 rounded text-sm">&lt;Outlet /&gt;</code>
          </li>
          <li class="flex items-start">
            <span class="text-blue-500 mr-2 mt-1">•</span>
            The layout persists across navigation between child routes
          </li>
          <li class="flex items-start">
            <span class="text-blue-500 mr-2 mt-1">•</span>
            Client-side state (like sidebar open/closed) is preserved during navigation
          </li>
        </ul>
      </div>
    </div>
  );
}
