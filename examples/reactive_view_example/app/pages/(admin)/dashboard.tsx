import { A } from "@solidjs/router";
import { createSignal, type ParentProps } from "solid-js";

export default function DashboardLayout(props: ParentProps) {
  const [sidebarOpen, setSidebarOpen] = createSignal(true);

  return (
    <div
      style={{
        display: "flex",
        "min-height": "100vh",
        "font-family": "system-ui, sans-serif",
      }}
    >
      {/* Sidebar */}
      <aside
        style={{
          width: sidebarOpen() ? "250px" : "0",
          background: "#1f2937",
          color: "white",
          transition: "width 0.3s ease",
          overflow: "hidden",
          "flex-shrink": "0",
        }}
      >
        <div style={{ padding: "20px" }}>
          <h2 style={{ margin: "0 0 20px 0", "font-size": "20px" }}>
            Dashboard
          </h2>

          <nav>
            <ul style={{ "list-style": "none", padding: 0, margin: 0 }}>
              <li style={{ "margin-bottom": "8px" }}>
                <A
                  href="/dashboard"
                  end
                  activeClass="active-link"
                  style={{
                    display: "block",
                    padding: "10px 12px",
                    color: "white",
                    "text-decoration": "none",
                    "border-radius": "6px",
                    transition: "background 0.2s",
                  }}
                  onMouseOver={(e) =>
                    (e.currentTarget.style.background = "#374151")
                  }
                  onMouseOut={(e) =>
                    (e.currentTarget.style.background = "transparent")
                  }
                >
                  📊 Overview
                </A>
              </li>
              <li style={{ "margin-bottom": "8px" }}>
                <A
                  href="/dashboard/analytics"
                  activeClass="active-link"
                  style={{
                    display: "block",
                    padding: "10px 12px",
                    color: "white",
                    "text-decoration": "none",
                    "border-radius": "6px",
                    transition: "background 0.2s",
                  }}
                  onMouseOver={(e) =>
                    (e.currentTarget.style.background = "#374151")
                  }
                  onMouseOut={(e) =>
                    (e.currentTarget.style.background = "transparent")
                  }
                >
                  📈 Analytics
                </A>
              </li>
              <li style={{ "margin-bottom": "8px" }}>
                <A
                  href="/dashboard/settings"
                  activeClass="active-link"
                  style={{
                    display: "block",
                    padding: "10px 12px",
                    color: "white",
                    "text-decoration": "none",
                    "border-radius": "6px",
                    transition: "background 0.2s",
                  }}
                  onMouseOver={(e) =>
                    (e.currentTarget.style.background = "#374151")
                  }
                  onMouseOut={(e) =>
                    (e.currentTarget.style.background = "transparent")
                  }
                >
                  ⚙️ Settings
                </A>
              </li>
            </ul>
          </nav>

          <div
            style={{
              "margin-top": "30px",
              "padding-top": "20px",
              "border-top": "1px solid #374151",
            }}
          >
            <A
              href="/"
              style={{
                display: "block",
                padding: "10px 12px",
                color: "#9ca3af",
                "text-decoration": "none",
                "border-radius": "6px",
                transition: "background 0.2s",
              }}
              onMouseOver={(e) =>
                (e.currentTarget.style.background = "#374151")
              }
              onMouseOut={(e) =>
                (e.currentTarget.style.background = "transparent")
              }
            >
              ← Back to Home
            </A>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <div style={{ flex: 1, display: "flex", "flex-direction": "column" }}>
        {/* Header */}
        <header
          style={{
            background: "white",
            "border-bottom": "1px solid #e5e7eb",
            padding: "16px 24px",
            display: "flex",
            "align-items": "center",
            "justify-content": "space-between",
          }}
        >
          <button
            onClick={() => setSidebarOpen(!sidebarOpen())}
            style={{
              background: "#f3f4f6",
              border: "1px solid #d1d5db",
              padding: "8px 12px",
              "border-radius": "6px",
              cursor: "pointer",
              "font-size": "14px",
            }}
          >
            {sidebarOpen() ? "← Hide Sidebar" : "→ Show Sidebar"}
          </button>

          <div style={{ color: "#6b7280", "font-size": "14px" }}>
            Nested Layout Example
          </div>
        </header>

        {/* Child Routes */}
        <main style={{ flex: 1, padding: "24px", background: "#f9fafb" }}>
          {props.children}
        </main>
      </div>
    </div>
  );
}
