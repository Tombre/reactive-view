export default function DashboardOverview() {
  return (
    <div>
      {/* Page Header */}
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">Dashboard Overview</h1>
        <p class="mt-1 text-gray-600">
          Welcome to your dashboard! This page demonstrates nested layouts in ReactiveView.
        </p>
      </div>

      {/* Stats Grid */}
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {/* Total Users */}
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            </div>
            <span class="text-sm font-medium text-gray-500">Total Users</span>
          </div>
          <div class="text-3xl font-bold text-gray-900">1,234</div>
          <div class="flex items-center gap-1 mt-2 text-sm text-emerald-600">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
            </svg>
            <span>12% from last month</span>
          </div>
        </div>

        {/* Revenue */}
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <span class="text-sm font-medium text-gray-500">Revenue</span>
          </div>
          <div class="text-3xl font-bold text-gray-900">$12,345</div>
          <div class="flex items-center gap-1 mt-2 text-sm text-emerald-600">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
            </svg>
            <span>8% from last month</span>
          </div>
        </div>

        {/* Active Sessions */}
        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <span class="text-sm font-medium text-gray-500">Active Sessions</span>
          </div>
          <div class="text-3xl font-bold text-gray-900">456</div>
          <div class="flex items-center gap-1 mt-2 text-sm text-red-600">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
            </svg>
            <span>3% from last month</span>
          </div>
        </div>
      </div>

      {/* Info Box */}
      <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
        <div class="flex gap-3">
          <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <h4 class="text-sm font-semibold text-blue-900">How Nested Layouts Work</h4>
            <ul class="mt-2 text-sm text-blue-700 space-y-1">
              <li class="flex items-start gap-2">
                <span class="text-blue-500 mt-0.5">1.</span>
                <span>
                  The <code class="px-1 py-0.5 bg-blue-100 text-blue-800 rounded text-xs font-mono">dashboard.tsx</code> file defines the layout with sidebar and header
                </span>
              </li>
              <li class="flex items-start gap-2">
                <span class="text-blue-500 mt-0.5">2.</span>
                <span>
                  Child pages like <code class="px-1 py-0.5 bg-blue-100 text-blue-800 rounded text-xs font-mono">dashboard/index.tsx</code> are rendered in the outlet
                </span>
              </li>
              <li class="flex items-start gap-2">
                <span class="text-blue-500 mt-0.5">3.</span>
                <span>The layout persists across navigation between child routes</span>
              </li>
              <li class="flex items-start gap-2">
                <span class="text-blue-500 mt-0.5">4.</span>
                <span>Client-side state (like sidebar toggle) is preserved during navigation</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
