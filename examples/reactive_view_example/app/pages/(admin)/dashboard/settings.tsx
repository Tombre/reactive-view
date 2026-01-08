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
      <h1 class="text-2xl font-bold text-gray-900 mb-4">Settings</h1>

      <p class="text-gray-600 mb-6">
        Manage your dashboard preferences and notifications.
      </p>

      {/* Notifications Section */}
      <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm mb-5">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">
          Notifications
        </h3>

        <div class="space-y-4">
          <label class="flex items-center justify-between cursor-pointer">
            <div>
              <div class="font-medium text-gray-900">
                Email Notifications
              </div>
              <div class="text-sm text-gray-600">
                Receive notifications via email
              </div>
            </div>
            <input
              type="checkbox"
              checked={emailNotifications()}
              onChange={(e) => setEmailNotifications(e.target.checked)}
              class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
            />
          </label>

          <label class="flex items-center justify-between cursor-pointer">
            <div>
              <div class="font-medium text-gray-900">
                Push Notifications
              </div>
              <div class="text-sm text-gray-600">
                Receive push notifications in your browser
              </div>
            </div>
            <input
              type="checkbox"
              checked={pushNotifications()}
              onChange={(e) => setPushNotifications(e.target.checked)}
              class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
            />
          </label>
        </div>
      </div>

      {/* Appearance Section */}
      <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm mb-5">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Appearance</h3>

        <label class="flex items-center justify-between cursor-pointer">
          <div>
            <div class="font-medium text-gray-900">
              Dark Mode
            </div>
            <div class="text-sm text-gray-600">
              Use dark theme across the dashboard
            </div>
          </div>
          <input
            type="checkbox"
            checked={darkMode()}
            onChange={(e) => setDarkMode(e.target.checked)}
            class="w-5 h-5 text-blue-600 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
          />
        </label>
      </div>

      {/* Save Button */}
      <div class="flex items-center gap-3">
        <button
          onClick={handleSave}
          class="bg-blue-500 hover:bg-blue-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
        >
          Save Changes
        </button>

        {saveStatus() && (
          <span class={`text-sm ${
            saveStatus()?.includes("success") ? "text-emerald-600" : "text-gray-600"
          }`}>
            {saveStatus()}
          </span>
        )}
      </div>

      {/* Info Box */}
      <div class="mt-8 bg-amber-50 border border-amber-200 p-5 rounded-xl">
        <h4 class="text-lg font-semibold text-amber-800 mb-2">
          💡 Nested Layout Benefits
        </h4>
        <p class="text-amber-700 text-sm m-0">
          Notice how the sidebar and header persist as you navigate between
          Dashboard pages. The layout component wraps all child routes, and
          client-side state (like the sidebar toggle and form values) is
          preserved during navigation. This creates a seamless user experience!
        </p>
      </div>
    </div>
  );
}
