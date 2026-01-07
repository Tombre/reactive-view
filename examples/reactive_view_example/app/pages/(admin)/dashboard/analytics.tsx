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

  return (
    <div>
      <div
        style={{
          display: "flex",
          "align-items": "center",
          "justify-content": "space-between",
          "margin-bottom": "24px",
        }}
      >
        <h1 style={{ margin: 0, color: "#1f2937" }}>Analytics</h1>

        <div style={{ display: "flex", gap: "8px" }}>
          <button
            onClick={() => setSelectedPeriod("week")}
            style={{
              padding: "8px 16px",
              "border-radius": "6px",
              border: "1px solid #d1d5db",
              background: selectedPeriod() === "week" ? "#3b82f6" : "white",
              color: selectedPeriod() === "week" ? "white" : "#374151",
              cursor: "pointer",
              "font-size": "14px",
            }}
          >
            Week
          </button>
          <button
            onClick={() => setSelectedPeriod("month")}
            style={{
              padding: "8px 16px",
              "border-radius": "6px",
              border: "1px solid #d1d5db",
              background: selectedPeriod() === "month" ? "#3b82f6" : "white",
              color: selectedPeriod() === "month" ? "white" : "#374151",
              cursor: "pointer",
              "font-size": "14px",
            }}
          >
            Month
          </button>
          <button
            onClick={() => setSelectedPeriod("year")}
            style={{
              padding: "8px 16px",
              "border-radius": "6px",
              border: "1px solid #d1d5db",
              background: selectedPeriod() === "year" ? "#3b82f6" : "white",
              color: selectedPeriod() === "year" ? "white" : "#374151",
              cursor: "pointer",
              "font-size": "14px",
            }}
          >
            Year
          </button>
        </div>
      </div>

      <div
        style={{
          display: "flex",
          gap: "24px",
          "margin-bottom": "24px",
        }}
      >
        <p style={{ color: "#6b7280", margin: 0 }}>
          Viewing analytics for: <strong>{selectedPeriod()}</strong>
        </p>
        <p style={{ color: "#6b7280", margin: 0 }}>
          Total views: <strong>{data().total_views.toLocaleString()}</strong>
        </p>
      </div>

      {/* Simple Bar Chart */}
      <div
        style={{
          background: "white",
          padding: "24px",
          "border-radius": "12px",
          border: "1px solid #e5e7eb",
        }}
      >
        <h3 style={{ margin: "0 0 20px 0", color: "#1f2937" }}>
          Page Views - {selectedPeriod().charAt(0).toUpperCase() + selectedPeriod().slice(1)}
        </h3>

        <div
          style={{
            display: "flex",
            "align-items": "flex-end",
            gap: "12px",
            height: "200px",
          }}
        >
          <For each={data().chart_data}>
            {(item) => (
              <div
                style={{
                  flex: 1,
                  display: "flex",
                  "flex-direction": "column",
                  "align-items": "center",
                  gap: "8px",
                }}
              >
                <div
                  style={{
                    width: "100%",
                    background: "#3b82f6",
                    "border-radius": "4px 4px 0 0",
                    transition: "height 0.3s ease",
                    height: `${(item.value / maxValue()) * 100}%`,
                    position: "relative",
                  }}
                  title={`${item.value} views`}
                >
                  <div
                    style={{
                      position: "absolute",
                      top: "-24px",
                      left: "50%",
                      transform: "translateX(-50%)",
                      "font-size": "12px",
                      "font-weight": "bold",
                      color: "#1f2937",
                    }}
                  >
                    {item.value}
                  </div>
                </div>
                <div
                  style={{
                    "font-size": "12px",
                    color: "#6b7280",
                    "font-weight": "500",
                  }}
                >
                  {item.label}
                </div>
              </div>
            )}
          </For>
        </div>
      </div>

      <div
        style={{
          "margin-top": "24px",
          display: "grid",
          "grid-template-columns": "repeat(auto-fit, minmax(300px, 1fr))",
          gap: "20px",
        }}
      >
        <div
          style={{
            background: "white",
            padding: "20px",
            "border-radius": "12px",
            border: "1px solid #e5e7eb",
          }}
        >
          <h4 style={{ margin: "0 0 12px 0", color: "#1f2937" }}>Top Pages</h4>
          <div style={{ "font-size": "14px", color: "#6b7280" }}>
            <For each={data().top_pages}>
              {(page, index) => (
                <div
                  style={{
                    display: "flex",
                    "justify-content": "space-between",
                    padding: "8px 0",
                    "border-bottom": index() < data().top_pages.length - 1 ? "1px solid #f3f4f6" : "none",
                  }}
                >
                  <span>{page.path}</span>
                  <strong>{page.views.toLocaleString()} views</strong>
                </div>
              )}
            </For>
          </div>
        </div>

        <div
          style={{
            background: "white",
            padding: "20px",
            "border-radius": "12px",
            border: "1px solid #e5e7eb",
          }}
        >
          <h4 style={{ margin: "0 0 12px 0", color: "#1f2937" }}>
            Traffic Sources
          </h4>
          <div style={{ "font-size": "14px", color: "#6b7280" }}>
            <For each={data().traffic_sources}>
              {(source, index) => (
                <div
                  style={{
                    display: "flex",
                    "justify-content": "space-between",
                    padding: "8px 0",
                    "border-bottom": index() < data().traffic_sources.length - 1 ? "1px solid #f3f4f6" : "none",
                  }}
                >
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
