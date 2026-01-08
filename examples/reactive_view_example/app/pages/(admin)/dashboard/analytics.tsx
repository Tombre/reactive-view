import { createSignal, For } from "solid-js";
import { useLoaderData } from "#loaders/(admin)/dashboard/analytics";
import { useNavigate, useSearchParams } from "@solidjs/router";

export default function DashboardAnalytics() {
  const loaderData = useLoaderData();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  
  // useLoaderData returns an Accessor, so we need to call it
  const data = () => loaderData() || {
    chart_data: [],
    top_pages: [],
    traffic_sources: [],
    total_views: 0,
    period: "week"
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
    // Calculate height in pixels (max 160px to leave room for labels)
    const maxHeight = 160;
    return Math.round((value / maxValue()) * maxHeight);
  };

  return (
    <div>
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Analytics</h1>

        <div class="flex gap-2">
          <button
            onClick={() => setSelectedPeriod("week")}
            class={`px-4 py-2 rounded-md border text-sm font-medium transition-colors ${
              selectedPeriod() === "week" 
                ? "bg-blue-500 text-white border-blue-500" 
                : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
            }`}
          >
            Week
          </button>
          <button
            onClick={() => setSelectedPeriod("month")}
            class={`px-4 py-2 rounded-md border text-sm font-medium transition-colors ${
              selectedPeriod() === "month" 
                ? "bg-blue-500 text-white border-blue-500" 
                : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
            }`}
          >
            Month
          </button>
          <button
            onClick={() => setSelectedPeriod("year")}
            class={`px-4 py-2 rounded-md border text-sm font-medium transition-colors ${
              selectedPeriod() === "year" 
                ? "bg-blue-500 text-white border-blue-500" 
                : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
            }`}
          >
            Year
          </button>
        </div>
      </div>

      <div class="flex flex-wrap gap-6 mb-6 text-gray-600">
        <p class="m-0">
          Viewing analytics for: <strong>{selectedPeriod()}</strong>
        </p>
        <p class="m-0">
          Total views: <strong>{data().total_views.toLocaleString()}</strong>
        </p>
      </div>

      {/* Simple Bar Chart */}
      <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm mb-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-5">
          Page Views - {selectedPeriod().charAt(0).toUpperCase() + selectedPeriod().slice(1)}
        </h3>

        <div class="flex items-end gap-3 h-50">
          <For each={data().chart_data}>
            {(item) => (
              <div class="flex-1 flex flex-col items-center justify-end gap-2">
                <div
                  class="w-full bg-blue-500 rounded-t transition-all duration-300 ease-out relative min-h-1"
                  style={{
                    height: `${getBarHeight(item.value)}px`,
                  }}
                  title={`${item.value} views`}
                >
                  <div
                    class="absolute -top-6 left-1/2 transform -translate-x-1/2 text-xs font-bold text-gray-900"
                  >
                    {item.value}
                  </div>
                </div>
                <div class="text-xs text-gray-600 font-medium">
                  {item.label}
                </div>
              </div>
            )}
          </For>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-5 mt-6">
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm">
          <h4 class="text-lg font-semibold text-gray-900 mb-3">Top Pages</h4>
          <div class="text-sm text-gray-600">
            <For each={data().top_pages}>
              {(page, index) => (
                <div class={`flex justify-between py-2 ${
                  index() < data().top_pages.length - 1 ? "border-b border-gray-100" : ""
                }`}>
                  <span>{page.path}</span>
                  <strong>{page.views.toLocaleString()} views</strong>
                </div>
              )}
            </For>
          </div>
        </div>

        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm">
          <h4 class="text-lg font-semibold text-gray-900 mb-3">
            Traffic Sources
          </h4>
          <div class="text-sm text-gray-600">
            <For each={data().traffic_sources}>
              {(source, index) => (
                <div class={`flex justify-between py-2 ${
                  index() < data().traffic_sources.length - 1 ? "border-b border-gray-100" : ""
                }`}>
                  <span>{source.source}</span>
                  <strong>{source.percentage}%</strong>
                </div>
              )}
            </For>
          </div>
        </div>
      </div>
    </div>
  );
}
