import { createSignal, Show } from "solid-js";

export default function DashboardSettings() {
  const [emailNotifications, setEmailNotifications] = createSignal(true);
  const [pushNotifications, setPushNotifications] = createSignal(false);
  const [darkMode, setDarkMode] = createSignal(false);
  const [saveStatus, setSaveStatus] = createSignal<"idle" | "saving" | "success">("idle");

  const handleSave = () => {
    setSaveStatus("saving");
    // Simulate API call
    setTimeout(() => {
      setSaveStatus("success");
      setTimeout(() => setSaveStatus("idle"), 3000);
    }, 500);
  };

  // Toggle Switch Component
  const Toggle = (props: { checked: boolean; onChange: (checked: boolean) => void; label: string; description: string }) => (
    <label class="flex items-center justify-between cursor-pointer py-4">
      <div class="flex-1 mr-4">
        <div class="font-medium text-gray-900">{props.label}</div>
        <div class="text-sm text-gray-500 mt-0.5">{props.description}</div>
      </div>
      <div class="relative flex-shrink-0">
        <input
          type="checkbox"
          checked={props.checked}
          onChange={(e) => props.onChange(e.target.checked)}
          class="sr-only peer"
        />
        <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-blue-500 peer-focus:ring-offset-2 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600 transition-colors"></div>
      </div>
    </label>
  );

  return (
    <div>
      {/* Page Header */}
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">Settings</h1>
        <p class="mt-1 text-gray-600">Manage your dashboard preferences and notifications.</p>
      </div>

      {/* Notifications Section */}
      <div class="bg-white rounded-xl border border-gray-200 mb-6">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Notifications</h3>
        </div>
        <div class="px-6 divide-y divide-gray-200">
          <Toggle
            checked={emailNotifications()}
            onChange={setEmailNotifications}
            label="Email Notifications"
            description="Receive notifications via email"
          />
          <Toggle
            checked={pushNotifications()}
            onChange={setPushNotifications}
            label="Push Notifications"
            description="Receive push notifications in your browser"
          />
        </div>
      </div>

      {/* Appearance Section */}
      <div class="bg-white rounded-xl border border-gray-200 mb-6">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Appearance</h3>
        </div>
        <div class="px-6">
          <Toggle
            checked={darkMode()}
            onChange={setDarkMode}
            label="Dark Mode"
            description="Use dark theme across the dashboard"
          />
        </div>
      </div>

      {/* Save Button */}
      <div class="flex items-center gap-4">
        <button
          onClick={handleSave}
          disabled={saveStatus() === "saving"}
          class="inline-flex items-center justify-center px-6 py-2.5 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors disabled:opacity-50"
        >
          <Show when={saveStatus() === "saving"} fallback="Save Changes">
            <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            Saving...
          </Show>
        </button>

        <Show when={saveStatus() === "success"}>
          <div class="flex items-center gap-2 text-sm text-emerald-600">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Settings saved successfully!
          </div>
        </Show>
      </div>

      {/* Info Box */}
      <div class="mt-8 bg-amber-50 border border-amber-200 rounded-xl p-4">
        <div class="flex gap-3">
          <svg class="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
          </svg>
          <div>
            <h4 class="text-sm font-semibold text-amber-800">Nested Layout Benefits</h4>
            <p class="text-sm text-amber-700 mt-1">
              Notice how the sidebar and header persist as you navigate between Dashboard pages.
              The layout component wraps all child routes, and client-side state (like the sidebar
              toggle and form values) is preserved during navigation. This creates a seamless user experience!
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
