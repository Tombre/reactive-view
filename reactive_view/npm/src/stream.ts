import { createSignal, onCleanup, batch } from "solid-js";
import { isServer } from "solid-js/web";
import { getCSRFToken } from "./csrf.js";

// ============================================================================
// Types
// ============================================================================

/**
 * A single chunk received from the SSE stream.
 * The `type` field determines how the chunk is interpreted.
 */
export interface StreamChunk {
  /** Event type: "text", "json", "error", "done", or custom */
  type: string;
  /** Text content (for type "text") */
  chunk?: string;
  /** Structured data (for type "json") */
  data?: unknown;
  /** Error message (for type "error") */
  message?: string;
  /** Additional fields for custom event types */
  [key: string]: unknown;
}

/**
 * Reactive state for a stream connection.
 * All properties are SolidJS accessors (signals) that update as chunks arrive.
 */
export interface StreamState<TParams = Record<string, unknown>> {
  /** Accumulated text data from all "text" chunks */
  data: () => string;
  /** Whether the stream is currently active */
  streaming: () => boolean;
  /** Error if the stream failed */
  error: () => Error | null;
  /** All received chunks (text, json, and custom) */
  chunks: () => StreamChunk[];
  /** Start the stream with the given params (programmatic trigger) */
  start: (params: TParams) => void;
  /** Abort the current stream */
  abort: () => void;
}

/**
 * Options for createStream.
 */
export interface StreamOptions {
  /**
   * Called for each chunk received. Use for custom accumulation logic.
   * The default behavior accumulates "text" chunks into the `data` signal.
   */
  onChunk?: (chunk: StreamChunk) => void;
  /**
   * Called when the stream completes (receives "done" event).
   */
  onDone?: () => void;
  /**
   * Called when the stream encounters an error.
   */
  onError?: (error: Error) => void;
}

// ============================================================================
// Core Stream Factory
// ============================================================================

/**
 * Create a streaming connection to a Rails mutation endpoint.
 *
 * Returns reactive state that updates as SSE chunks arrive from the server.
 * The stream is initiated by calling `start()` or by submitting a `StreamForm`.
 *
 * @param loaderPath - The loader route path (e.g., "ai/chat")
 * @param mutationName - The mutation method name (e.g., "generate")
 * @param options - Optional callbacks for chunk handling
 * @returns StreamState with reactive signals and control methods
 *
 * @example
 * const stream = createStream("ai/chat", "generate");
 * stream.start({ prompt: "Hello" });
 * // stream.data() updates as text arrives
 * // stream.streaming() is true while active
 */
export function createStream<TParams = Record<string, unknown>>(
  loaderPath: string,
  mutationName: string,
  options?: StreamOptions
): StreamState<TParams> {
  // Server-side: return inert state (streams are client-only)
  if (isServer) {
    const noop = () => {};
    return {
      data: () => "",
      streaming: () => false,
      error: () => null,
      chunks: () => [],
      start: noop,
      abort: noop,
    };
  }

  const [data, setData] = createSignal<string>("");
  const [streaming, setStreaming] = createSignal(false);
  const [error, setError] = createSignal<Error | null>(null);
  const [chunks, setChunks] = createSignal<StreamChunk[]>([]);

  let abortController: AbortController | null = null;

  function start(params: TParams) {
    // Abort any existing stream
    abort();

    // Reset state
    batch(() => {
      setData("");
      setError(null);
      setChunks([]);
      setStreaming(true);
    });

    abortController = new AbortController();

    connectSSE(
      loaderPath,
      mutationName,
      params as Record<string, unknown>,
      abortController.signal,
      {
        onChunk(chunk: StreamChunk) {
          batch(() => {
            setChunks((prev) => [...prev, chunk]);
            if (chunk.type === "text" && chunk.chunk) {
              setData((prev) => prev + chunk.chunk);
            }
            options?.onChunk?.(chunk);
          });
        },
        onDone() {
          setStreaming(false);
          options?.onDone?.();
        },
        onError(err: Error) {
          batch(() => {
            setError(err);
            setStreaming(false);
          });
          options?.onError?.(err);
        },
      }
    );
  }

  function abort() {
    if (abortController) {
      abortController.abort();
      abortController = null;
    }
    setStreaming(false);
  }

  // Auto-cleanup on component unmount
  onCleanup(abort);

  return { data, streaming, error, chunks, start, abort };
}

// ============================================================================
// SSE Connection (internal)
// ============================================================================

/** @internal Callbacks for the SSE connection */
interface SSECallbacks {
  onChunk: (chunk: StreamChunk) => void;
  onDone: () => void;
  onError: (error: Error) => void;
}

/**
 * @internal
 * Connect to the Rails streaming endpoint and parse SSE events.
 * Uses fetch + ReadableStream for broad browser compatibility.
 */
async function connectSSE(
  loaderPath: string,
  mutationName: string,
  params: Record<string, unknown>,
  signal: AbortSignal,
  callbacks: SSECallbacks
): Promise<void> {
  const railsBaseUrl = getRailsBaseUrl();
  const url = new URL(
    `/_reactive_view/loaders/${loaderPath}/stream`,
    railsBaseUrl
  );
  url.searchParams.set("_mutation", mutationName);

  const headers: Record<string, string> = {
    Accept: "text/event-stream",
    "Content-Type": "application/json",
  };

  // Add CSRF token
  const csrfToken = getCSRFToken();
  if (csrfToken) {
    headers["X-CSRF-Token"] = csrfToken;
  }

  // SSR cookie forwarding (shouldn't happen in practice since streams
  // are client-only, but included for completeness)
  if (isServer) {
    const cookies = (globalThis as any).__REACTIVE_VIEW_COOKIES__;
    if (cookies) headers["Cookie"] = cookies;
  }

  try {
    const response = await fetch(url.toString(), {
      method: "POST",
      headers,
      body: JSON.stringify(params),
      credentials: "include",
      signal,
    });

    if (!response.ok) {
      let errorMessage = `Stream failed: ${response.status} ${response.statusText}`;
      try {
        const errorData = await response.json();
        if (errorData.error) errorMessage = errorData.error;
      } catch {
        // Could not parse error JSON -- use status text
      }
      throw new Error(errorMessage);
    }

    if (!response.body) {
      throw new Error("Stream response has no body");
    }

    // Read the stream using ReadableStream API
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      // SSE events are separated by double newlines
      const events = buffer.split("\n\n");
      // Last element might be incomplete -- keep it in the buffer
      buffer = events.pop() || "";

      for (const event of events) {
        const trimmed = event.trim();
        if (!trimmed) continue;

        // Parse each line in the event (SSE can have multi-line data)
        for (const line of trimmed.split("\n")) {
          if (line.startsWith("data: ")) {
            const jsonStr = line.slice(6);
            try {
              const chunk: StreamChunk = JSON.parse(jsonStr);

              if (chunk.type === "done") {
                callbacks.onDone();
                return;
              }
              if (chunk.type === "error") {
                callbacks.onError(
                  new Error(chunk.message || "Stream error from server")
                );
                return;
              }
              callbacks.onChunk(chunk);
            } catch {
              // Skip malformed JSON lines
            }
          }
        }
      }
    }

    // Stream ended without a "done" event (connection closed)
    callbacks.onDone();
  } catch (err) {
    if (signal.aborted) return; // Expected abort -- don't report as error
    callbacks.onError(err instanceof Error ? err : new Error(String(err)));
  }
}

/**
 * @internal Get Rails base URL (same logic as loader.ts / mutation.ts)
 */
function getRailsBaseUrl(): string {
  if (isServer) {
    const globalRailsUrl = (globalThis as any).__RAILS_BASE_URL__;
    if (globalRailsUrl) return globalRailsUrl;
    return "http://localhost:3000";
  }
  return window.location.origin;
}
