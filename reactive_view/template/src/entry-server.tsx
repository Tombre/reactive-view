// @refresh reload
import { createHandler, StartServer } from "@solidjs/start/server";

/**
 * Get CSRF token from Rails context (stored during SSR render request)
 * This token is injected into a meta tag for client-side mutation requests
 */
function getCSRFToken(): string {
  return (globalThis as any).__RAILS_CSRF_TOKEN__ || "";
}

export default createHandler(() => (
  <StartServer
    document={({ assets, children, scripts }) => (
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <meta name="csrf-token" content={getCSRFToken()} />
          <link rel="icon" href="/favicon.ico" />
          {assets}
        </head>
        <body>
          <div id="app">{children}</div>
          {scripts}
        </body>
      </html>
    )}
  />
));
