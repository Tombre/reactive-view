import { For } from "solid-js";
import { useLoaderData } from "#loaders/(admin)/dashboard/analytics";
import { useNavigate } from "@solidjs/router";

export default function DashboardAnalytics() {
  const loaderData = useLoaderData();
  const navigate = useNavigate();

  const data = () =>
    loaderData() || {
      chart_data: [],
      top_pages: [],
      traffic_sources: [],
      total_views: 0,
      period: "week",
    };

  const selectedPeriod = () => data().period;

  const setSelectedPeriod = (period: string) => {
    navigate(`?period=${period}`, { replace: true });
  };

  const maxValue = () => {
    const chartData = data().chart_data;
    return chartData.length > 0 ? Math.max(...chartData.map((d) => d.value)) : 1;
  };

  const getBarHeight = (value: number) => {
    const maxHeight = 140;
    return Math.round((value / maxValue()) * maxHeight);
  };

  const periodButtonClass = (period: string) => {
    const base = "px-4 py-2 text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2";
    if (selectedPeriod() === period) {
      return `${base} bg-blue-600 text-white`;
    }
    return `${base} bg-white text-gray-700 hover:bg-gray-50`;
  };

  return (
    <div>
      {/* Page Header */}
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Analytics</h1>
          <p class="mt-1 text-gray-600">
            Viewing analytics for: <span class="font-medium">{selectedPeriod()}</span>
            {" | "}
            Total views: <span class="font-medium">{data().total_views.toLocaleString()}</span>
          </p>
        </div>

        {/* Period Selector - Segmented Control */}
        <div class="inline-flex rounded-lg border border-gray-300 overflow-hidden">
          <button
            onClick={() => setSelectedPeriod("week")}
            class={`${periodButtonClass("week")} rounded-none border-r border-gray-300`}
          >
            Week
          </button>
          <button
            onClick={() => setSelectedPeriod("month")}
            class={`${periodButtonClass("month")} rounded-none border-r border-gray-300`}
          >
            Month
          </button>
          <button
            onClick={() => setSelectedPeriod("year")}
            class={`${periodButtonClass("year")} rounded-none`}
          >
            Year
          </button>
        </div>
      </div>

      {/* Chart Card */}
      <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-6">
          Page Views - {selectedPeriod().charAt(0).toUpperCase() + selectedPeriod().slice(1)}
        </h3>

        <div class="flex items-end gap-4 h-48 px-4">
          <For each={data().chart_data}>
            {(item) => (
              <div class="flex-1 flex flex-col items-center justify-end gap-2">
                <span class="text-xs font-semibold text-gray-900">{item.value}</span>
                <div
                  class="w-full bg-blue-500 rounded-t-md transition-all duration-300 ease-out min-h-1"
                  style={{ height: `${getBarHeight(item.value)}px` }}
                  title={`${item.value} views`}
                />
                <span class="text-xs text-gray-600 font-medium">{item.label}</span>
              </div>
            )}
          </For>
        </div>
      </div>

      {/* Data Tables Grid */}
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Pages */}
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <h4 class="text-sm font-semibold text-gray-900">Top Pages</h4>
          </div>
          <div class="divide-y divide-gray-200">
            <For each={data().top_pages}>
              {(page) => (
                <div class="px-6 py-3 flex items-center justify-between hover:bg-gray-50 transition-colors">
                  <span class="text-sm text-gray-700 font-mono">{page.path}</span>
                  <span class="text-sm font-medium text-gray-900">
                    {page.views.toLocaleString()} views
                  </span>
                </div>
              )}
            </For>
          </div>
        </div>

        {/* Traffic Sources */}
        <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
            <h4 class="text-sm font-semibold text-gray-900">Traffic Sources</h4>
          </div>
          <div class="divide-y divide-gray-200">
            <For each={data().traffic_sources}>
              {(source) => (
                <div class="px-6 py-3 hover:bg-gray-50 transition-colors">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm text-gray-700">{source.source}</span>
                    <span class="text-sm font-medium text-gray-900">{source.percentage}%</span>
                  </div>
                  <div class="w-full bg-gray-100 rounded-full h-1.5">
                    <div
                      class="bg-blue-500 h-1.5 rounded-full transition-all duration-300"
                      style={{ width: `${source.percentage}%` }}
                    />
                  </div>
                </div>
              )}
            </For>
          </div>
        </div>
      </div>
    </div>
  );
}
