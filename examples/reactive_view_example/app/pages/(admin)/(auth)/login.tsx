import { useLoaderData } from "#loaders/(admin)/(auth)/login";

export default function AdminAuthLogin() {
  const loaderData = useLoaderData();
  const data = () => loaderData() || { require_2fa: false, session_timeout: 30 };

  return (
    <div style={{ padding: "40px", "max-width": "400px", margin: "0 auto" }}>
      <h1 style={{ color: "#1f2937", "margin-bottom": "24px" }}>Admin Login</h1>
      
      <div
        style={{
          background: "white",
          padding: "24px",
          "border-radius": "12px",
          border: "1px solid #e5e7eb",
        }}
      >
        <form>
          <div style={{ "margin-bottom": "16px" }}>
            <label
              style={{
                display: "block",
                "margin-bottom": "8px",
                "font-weight": "500",
                color: "#374151",
              }}
            >
              Email
            </label>
            <input
              type="email"
              placeholder="admin@example.com"
              style={{
                width: "100%",
                padding: "8px 12px",
                border: "1px solid #d1d5db",
                "border-radius": "6px",
                "font-size": "14px",
              }}
            />
          </div>

          <div style={{ "margin-bottom": "16px" }}>
            <label
              style={{
                display: "block",
                "margin-bottom": "8px",
                "font-weight": "500",
                color: "#374151",
              }}
            >
              Password
            </label>
            <input
              type="password"
              placeholder="••••••••"
              style={{
                width: "100%",
                padding: "8px 12px",
                border: "1px solid #d1d5db",
                "border-radius": "6px",
                "font-size": "14px",
              }}
            />
          </div>

          {data().require_2fa ? (
            <div
              style={{
                background: "#fffbeb",
                border: "1px solid #fbbf24",
                padding: "12px",
                "border-radius": "6px",
                "margin-bottom": "16px",
                "font-size": "14px",
                color: "#92400e",
              }}
            >
              Two-factor authentication is required
            </div>
          ) : null}

          <button
            type="submit"
            style={{
              width: "100%",
              padding: "10px",
              background: "#3b82f6",
              color: "white",
              border: "none",
              "border-radius": "6px",
              "font-size": "14px",
              "font-weight": "500",
              cursor: "pointer",
            }}
          >
            Sign In
          </button>
        </form>

        <p
          style={{
            "margin-top": "16px",
            "font-size": "12px",
            color: "#6b7280",
            "text-align": "center",
          }}
        >
          Session timeout: {data().session_timeout} minutes
        </p>
      </div>
    </div>
  );
}
