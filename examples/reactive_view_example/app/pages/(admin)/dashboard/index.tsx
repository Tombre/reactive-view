export default function DashboardOverview() {
  return (
    <div>
      <h1 style={{ margin: "0 0 16px 0", color: "#1f2937" }}>
        Dashboard Overview
      </h1>

      <p style={{ color: "#6b7280", "margin-bottom": "24px" }}>
        Welcome to your dashboard! This page demonstrates nested layouts in
        ReactiveView.
      </p>

      <div
        style={{
          display: "grid",
          "grid-template-columns": "repeat(auto-fit, minmax(250px, 1fr))",
          gap: "20px",
          "margin-top": "20px",
        }}
      >
        {/* Card 1 */}
        <div
          style={{
            background: "white",
            padding: "24px",
            "border-radius": "12px",
            border: "1px solid #e5e7eb",
          }}
        >
          <div style={{ color: "#6b7280", "font-size": "14px" }}>
            Total Users
          </div>
          <div
            style={{
              "font-size": "32px",
              "font-weight": "bold",
              color: "#1f2937",
              "margin-top": "8px",
            }}
          >
            1,234
          </div>
          <div
            style={{ color: "#10b981", "font-size": "14px", "margin-top": "4px" }}
          >
            +12% from last month
          </div>
        </div>

        {/* Card 2 */}
        <div
          style={{
            background: "white",
            padding: "24px",
            "border-radius": "12px",
            border: "1px solid #e5e7eb",
          }}
        >
          <div style={{ color: "#6b7280", "font-size": "14px" }}>Revenue</div>
          <div
            style={{
              "font-size": "32px",
              "font-weight": "bold",
              color: "#1f2937",
              "margin-top": "8px",
            }}
          >
            $12,345
          </div>
          <div
            style={{ color: "#10b981", "font-size": "14px", "margin-top": "4px" }}
          >
            +8% from last month
          </div>
        </div>

        {/* Card 3 */}
        <div
          style={{
            background: "white",
            padding: "24px",
            "border-radius": "12px",
            border: "1px solid #e5e7eb",
          }}
        >
          <div style={{ color: "#6b7280", "font-size": "14px" }}>
            Active Sessions
          </div>
          <div
            style={{
              "font-size": "32px",
              "font-weight": "bold",
              color: "#1f2937",
              "margin-top": "8px",
            }}
          >
            456
          </div>
          <div
            style={{ color: "#ef4444", "font-size": "14px", "margin-top": "4px" }}
          >
            -3% from last month
          </div>
        </div>
      </div>

      <div
        style={{
          "margin-top": "30px",
          background: "#eff6ff",
          padding: "20px",
          "border-radius": "12px",
          border: "1px solid #bfdbfe",
        }}
      >
        <h3 style={{ margin: "0 0 12px 0", color: "#1e40af" }}>
          How Nested Layouts Work
        </h3>
        <ul style={{ margin: 0, "padding-left": "20px", color: "#3730a3" }}>
          <li style={{ "margin-bottom": "8px" }}>
            The <code>dashboard.tsx</code> file defines the layout with sidebar
            and header
          </li>
          <li style={{ "margin-bottom": "8px" }}>
            Child pages like <code>dashboard/index.tsx</code>,{" "}
            <code>dashboard/analytics.tsx</code>, etc. are rendered in the{" "}
            <code>&lt;Outlet /&gt;</code>
          </li>
          <li style={{ "margin-bottom": "8px" }}>
            The layout persists across navigation between child routes
          </li>
          <li>
            Client-side state (like sidebar open/closed) is preserved during
            navigation
          </li>
        </ul>
      </div>
    </div>
  );
}
