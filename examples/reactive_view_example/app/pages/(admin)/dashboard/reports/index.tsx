import { For } from "@reactive-view/core";

const summaryCards = [
  {
    label: "Published Reports",
    value: "18",
    detail: "+3 this week",
  },
  {
    label: "Avg. Time to Generate",
    value: "2m 14s",
    detail: "12% faster",
  },
  {
    label: "Stakeholder Views",
    value: "4,892",
    detail: "+22% month over month",
  },
];

export default function DashboardReportsSummaryPage() {
  return (
    <div>
      <h2 class="text-lg font-semibold text-gray-900">Reports Summary</h2>
      <p class="mt-1 text-sm text-gray-600">
        This page lives at <code class="font-mono">/dashboard/reports</code> and is
        wrapped by both <code class="font-mono">dashboard.tsx</code> and
        <code class="font-mono">dashboard/reports.tsx</code> layouts.
      </p>

      <div class="mt-6 grid gap-4 sm:grid-cols-3">
        <For each={summaryCards}>
          {(card) => (
            <article class="rounded-lg border border-gray-200 bg-gray-50 p-4">
              <p class="text-xs uppercase tracking-wide text-gray-500">{card.label}</p>
              <p class="mt-2 text-2xl font-bold text-gray-900">{card.value}</p>
              <p class="mt-1 text-sm text-emerald-700">{card.detail}</p>
            </article>
          )}
        </For>
      </div>
    </div>
  );
}
