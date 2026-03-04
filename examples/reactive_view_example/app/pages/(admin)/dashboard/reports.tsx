import { A, useLocation, type ParentProps } from "@reactive-view/core";

export default function DashboardReportsLayout(props: ParentProps) {
  const location = useLocation();

  const tabClass = (path: string) => {
    const base =
      "inline-flex items-center rounded-md px-3 py-2 text-sm font-medium transition-colors";

    if (location.pathname === path) {
      return `${base} bg-blue-100 text-blue-800`;
    }

    return `${base} text-gray-600 hover:bg-gray-100 hover:text-gray-900`;
  };

  return (
    <section class="space-y-6">
      <header class="rounded-xl border border-blue-200 bg-blue-50 p-5">
        <h1 class="text-2xl font-bold text-blue-900">Reports</h1>
        <p class="mt-1 text-sm text-blue-800">
          This is a nested layout under <code class="font-mono">/dashboard</code>.
          The top dashboard layout still renders the sidebar and header, while this
          reports layout adds report-specific tabs.
        </p>

        <nav class="mt-4 flex flex-wrap gap-2" aria-label="Reports sections">
          <A href="/dashboard/reports" end class={tabClass("/dashboard/reports")}>
            Summary
          </A>
          <A
            href="/dashboard/reports/sources"
            class={tabClass("/dashboard/reports/sources")}
          >
            Sources
          </A>
        </nav>
      </header>

      <div class="rounded-xl border border-gray-200 bg-white p-6">{props.children}</div>
    </section>
  );
}
