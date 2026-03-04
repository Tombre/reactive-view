import { For } from "@reactive-view/core";

const sources = [
  { name: "Warehouse", owner: "Data Team", freshness: "5 min" },
  { name: "Billing", owner: "Finance", freshness: "15 min" },
  { name: "Application Logs", owner: "Platform", freshness: "1 min" },
];

export default function DashboardReportsSourcesPage() {
  return (
    <div>
      <h2 class="text-lg font-semibold text-gray-900">Report Sources</h2>
      <p class="mt-1 text-sm text-gray-600">
        This child route (<code class="font-mono">/dashboard/reports/sources</code>)
        reuses the same nested reports layout tabs while only the panel content changes.
      </p>

      <div class="mt-6 overflow-hidden rounded-lg border border-gray-200">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
          <thead class="bg-gray-50 text-left text-xs uppercase tracking-wide text-gray-500">
            <tr>
              <th class="px-4 py-3">Source</th>
              <th class="px-4 py-3">Owner</th>
              <th class="px-4 py-3">Freshness</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <For each={sources}>
              {(source) => (
                <tr>
                  <td class="px-4 py-3 font-medium text-gray-900">{source.name}</td>
                  <td class="px-4 py-3 text-gray-600">{source.owner}</td>
                  <td class="px-4 py-3 text-gray-600">{source.freshness}</td>
                </tr>
              )}
            </For>
          </tbody>
        </table>
      </div>
    </div>
  );
}
