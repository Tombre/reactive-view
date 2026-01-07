import { createSignal } from "solid-js";

export default function DashboardSettings() {
  const [emailNotifications, setEmailNotifications] = createSignal(true);
  const [pushNotifications, setPushNotifications] = createSignal(false);
  const [darkMode, setDarkMode] = createSignal(false);
  const [saveStatus, setSaveStatus] = createSignal<string | null>(null);

  const handleSave = () => {
    setSaveStatus("Saving...");
    // Simulate API call
    setTimeout(() => {
      setSaveStatus("Settings saved successfully!");
      setTimeout(() => setSaveStatus(null), 3000);
    }, 500);
  };

  return (
    <div>
      <h1 style={{ margin: "0 0 16px 0", color: "#1f2937" }}>Settings</h1>

      <p style={{ color: "#6b7280", "margin-bottom": "24px" }}>
        Manage your dashboard preferences and notifications.
      </p>

      {/* Notifications Section */}
      <div
        style={{
          background: "white",
          padding: "24px",
          "border-radius": "12px",
          border: "1px solid #e5e7eb",
          "margin-bottom": "20px",
        }}
      >
        <h3 style={{ margin: "0 0 16px 0", color: "#1f2937" }}>
          Notifications
        </h3>

        <div style={{ display: "flex", "flex-direction": "column", gap: "16px" }}>
          <label
            style={{
              display: "flex",
              "align-items": "center",
              "justify-content": "space-between",
              cursor: "pointer",
            }}
          >
            <div>
              <div style={{ "font-weight": "500", color: "#1f2937" }}>
                Email Notifications
              </div>
              <div style={{ "font-size": "14px", color: "#6b7280" }}>
                Receive notifications via email
              </div>
            </div>
            <input
              type="checkbox"
              checked={emailNotifications()}
              onChange={(e) => setEmailNotifications(e.currentTarget.checked)}
              style={{
                width: "20px",
                height: "20px",
                cursor: "pointer",
              }}
            />
          </label>

          <label
            style={{
              display: "flex",
              "align-items": "center",
              "justify-content": "space-between",
              cursor: "pointer",
            }}
          >
            <div>
              <div style={{ "font-weight": "500", color: "#1f2937" }}>
                Push Notifications
              </div>
              <div style={{ "font-size": "14px", color: "#6b7280" }}>
                Receive push notifications in your browser
              </div>
            </div>
            <input
              type="checkbox"
              checked={pushNotifications()}
              onChange={(e) => setPushNotifications(e.currentTarget.checked)}
              style={{
                width: "20px",
                height: "20px",
                cursor: "pointer",
              }}
            />
          </label>
        </div>
      </div>

      {/* Appearance Section */}
      <div
        style={{
          background: "white",
          padding: "24px",
          "border-radius": "12px",
          border: "1px solid #e5e7eb",
          "margin-bottom": "20px",
        }}
      >
        <h3 style={{ margin: "0 0 16px 0", color: "#1f2937" }}>Appearance</h3>

        <label
          style={{
            display: "flex",
            "align-items": "center",
            "justify-content": "space-between",
            cursor: "pointer",
          }}
        >
          <div>
            <div style={{ "font-weight": "500", color: "#1f2937" }}>
              Dark Mode
            </div>
            <div style={{ "font-size": "14px", color: "#6b7280" }}>
              Use dark theme across the dashboard
            </div>
          </div>
          <input
            type="checkbox"
            checked={darkMode()}
            onChange={(e) => setDarkMode(e.currentTarget.checked)}
            style={{
              width: "20px",
              height: "20px",
              cursor: "pointer",
            }}
          />
        </label>
      </div>

      {/* Save Button */}
      <div style={{ display: "flex", "align-items": "center", gap: "12px" }}>
        <button
          onClick={handleSave}
          style={{
            background: "#3b82f6",
            color: "white",
            border: "none",
            padding: "12px 24px",
            "border-radius": "8px",
            cursor: "pointer",
            "font-size": "16px",
            "font-weight": "500",
          }}
        >
          Save Changes
        </button>

        {saveStatus() && (
          <span
            style={{
              color: saveStatus()?.includes("success") ? "#10b981" : "#6b7280",
              "font-size": "14px",
            }}
          >
            {saveStatus()}
          </span>
        )}
      </div>

      {/* Info Box */}
      <div
        style={{
          "margin-top": "30px",
          background: "#fef3c7",
          padding: "20px",
          "border-radius": "12px",
          border: "1px solid #fde68a",
        }}
      >
        <h4 style={{ margin: "0 0 8px 0", color: "#92400e" }}>
          💡 Nested Layout Benefits
        </h4>
        <p style={{ margin: 0, color: "#78350f", "font-size": "14px" }}>
          Notice how the sidebar and header persist as you navigate between
          Dashboard pages. The layout component wraps all child routes, and
          client-side state (like the sidebar toggle and form values) is
          preserved during navigation. This creates a seamless user experience!
        </p>
      </div>
    </div>
  );
}
