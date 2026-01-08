import { useLoaderData } from "#loaders/(admin)/(auth)/login";
import "~/styles/tailwind.css";

export default function AdminAuthLogin() {
  const loaderData = useLoaderData();
  const data = () => loaderData() || { require_2fa: false, session_timeout: 30 };

  return (
    <div class="min-h-screen bg-gray-50 font-sans flex items-center justify-center px-4">
      <div class="w-full max-w-md">
        <h1 class="text-2xl font-bold text-gray-900 mb-6 text-center">Admin Login</h1>
        
        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <form>
            <div class="mb-4">
              <label class="block mb-2 font-medium text-gray-700 text-sm">
                Email
              </label>
              <input
                type="email"
                placeholder="admin@example.com"
                class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div class="mb-4">
              <label class="block mb-2 font-medium text-gray-700 text-sm">
                Password
              </label>
              <input
                type="password"
                placeholder="••••••••"
                class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {data().require_2fa && (
              <div class="bg-yellow-50 border border-yellow-300 p-3 rounded-md mb-4 text-sm text-yellow-800">
                Two-factor authentication is required
              </div>
            )}

            <button
              type="submit"
              class="w-full py-2.5 bg-blue-500 hover:bg-blue-600 text-white rounded-md text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              Sign In
            </button>
          </form>

          <p class="mt-4 text-xs text-gray-600 text-center">
            Session timeout: {data().session_timeout} minutes
          </p>
        </div>
      </div>
    </div>
  );
}
