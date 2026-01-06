import type { APIEvent } from "@solidjs/start/server";

/**
 * API endpoint for Rails to request page renders.
 * Rails calls this endpoint with the path to render and cookies for authentication.
 * 
 * This endpoint:
 * 1. Receives the render request from Rails
 * 2. Stores cookies for authenticated loader data requests
 * 3. Internally renders the requested route
 * 4. Returns the HTML to Rails
 */
export async function POST(event: APIEvent): Promise<Response> {
  try {
    const body = await event.request.json();
    const { path, loader_path, rails_base_url, cookies } = body;

    if (!path) {
      return new Response(
        JSON.stringify({ error: "Path is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Store the cookies and Rails URL for this request
    // These will be accessed by useLoaderData during SSR
    (globalThis as any).__REACTIVE_VIEW_COOKIES__ = cookies;
    (globalThis as any).__RAILS_BASE_URL__ = rails_base_url;

    // Build the internal URL to render using the request's own origin
    // This ensures we use the same host/port that successfully received this request
    const requestUrl = new URL(event.request.url);
    const renderUrl = new URL(path, requestUrl.origin);

    // Make an internal request to render the page
    const renderResponse = await fetch(renderUrl.toString(), {
      method: "GET",
      headers: {
        "Accept": "text/html",
        // Pass through any relevant headers
        "User-Agent": event.request.headers.get("User-Agent") || "",
      },
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
    
    return new Response(html, {
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
  } finally {
    // Clean up global state
    delete (globalThis as any).__REACTIVE_VIEW_COOKIES__;
    delete (globalThis as any).__RAILS_BASE_URL__;
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
