// @refresh reload
import { createHandler, StartServer } from "@solidjs/start/server";
import { getRequestEvent } from "solid-js/web";

const RAILS_CSRF_TOKEN_HEADER = "x-reactive-view-csrf-token";

/**
 * Get CSRF token from Rails context (stored during SSR render request)
 * This token is injected into a meta tag for client-side mutation requests
 */
function getCSRFToken(): string {
  const event = getRequestEvent();
  const headerToken = event?.request.headers.get(RAILS_CSRF_TOKEN_HEADER);
  if (headerToken) return headerToken;

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
