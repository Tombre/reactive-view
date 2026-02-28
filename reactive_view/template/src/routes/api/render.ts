import type { APIEvent } from "@solidjs/start/server";

const RAILS_BASE_URL_HEADER = "x-reactive-view-rails-base-url";
const RAILS_COOKIES_HEADER = "x-reactive-view-cookies";
const RAILS_CSRF_TOKEN_HEADER = "x-reactive-view-csrf-token";

/**
 * API endpoint for Rails to request page renders.
 * Rails calls this endpoint with the path to render and cookies for authentication.
 * 
 * This endpoint:
 * 1. Receives the render request from Rails
 * 2. Forwards Rails context via internal request headers
 * 3. Internally renders the requested route
 * 4. Returns the HTML to Rails
 */
export async function POST(event: APIEvent): Promise<Response> {
  try {
    const body = await event.request.json();
    const { path, loader_path, rails_base_url, cookies, csrf_token } = body;

    if (!path) {
      return new Response(
        JSON.stringify({ error: "Path is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Build the internal URL to render using the request's own origin
    // This ensures we use the same host/port that successfully received this request
    const requestUrl = new URL(event.request.url);
    const renderUrl = new URL(path, requestUrl.origin);

    const renderHeaders: Record<string, string> = {
      "Accept": "text/html",
      "User-Agent": event.request.headers.get("User-Agent") || "",
    };

    if (rails_base_url) {
      renderHeaders[RAILS_BASE_URL_HEADER] = String(rails_base_url);
    }

    if (cookies) {
      renderHeaders[RAILS_COOKIES_HEADER] = String(cookies);
    }

    if (csrf_token) {
      renderHeaders[RAILS_CSRF_TOKEN_HEADER] = String(csrf_token);
    }

    // Make an internal request to render the page
    const renderResponse = await fetch(renderUrl.toString(), {
      method: "GET",
      headers: renderHeaders,
    });

    if (!renderResponse.ok) {
      // Return error details for debugging
      const errorText = await renderResponse.text();
      return new Response(
        JSON.stringify({ 
          error: "Render failed", 
          status: renderResponse.status,
          details: errorText.substring(0, 500)
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Return the rendered HTML
    const html = await renderResponse.text();
    const clientRailsUrlScript = `<script>window.__RAILS_BASE_URL__=${JSON.stringify(rails_base_url)};</script>`;

    const htmlWithRailsBaseUrl = html.includes("</head>")
      ? html.replace("</head>", `${clientRailsUrlScript}</head>`)
      : `${clientRailsUrlScript}${html}`;
    
    return new Response(htmlWithRailsBaseUrl, {
      status: 200,
      headers: { 
        "Content-Type": "text/html; charset=utf-8",
      },
    });
  } catch (error) {
    console.error("[ReactiveView] Render error:", error);
    
    return new Response(
      JSON.stringify({ 
        error: "Internal render error", 
        message: error instanceof Error ? error.message : String(error)
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}

/**
 * Health check endpoint for Rails to verify the daemon is running
 */
export function GET(): Response {
  return new Response(
    JSON.stringify({ 
      status: "ok", 
      service: "reactive-view-daemon",
      timestamp: new Date().toISOString()
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
}
