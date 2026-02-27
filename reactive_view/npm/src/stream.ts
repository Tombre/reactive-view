import { createSignal, createEffect, onCleanup, batch } from "solid-js";
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

export type StreamStatus = "idle" | "streaming" | "done" | "error" | "aborted";

export class StreamIncompleteError extends Error {
  constructor(message = "Stream ended unexpectedly before completion") {
    super(message);
    this.name = "StreamIncompleteError";
  }
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
  /** Current stream lifecycle status */
  status: () => StreamStatus;
  /** All received chunks (text, json, and custom) */
  chunks: () => StreamChunk[];
  /** Last params used to start the stream */
  lastParams: () => TParams | null;
  /** Start the stream with the given params (programmatic trigger) */
  start: (params: TParams) => void;
  /** Retry using last params (or explicit params override) */
  retry: (params?: TParams) => void;
  /** Resolves on done, rejects on error/abort */
  end: () => Promise<void>;
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

export interface StreamDataMessage<TJson = unknown, TMeta = unknown> {
  id: number;
  role: "user" | "assistant";
  content: string;
  status: "streaming" | "done" | "error";
  events: TJson[];
  meta?: TMeta;
  error?: string;
}

export interface UseStreamDataOptions<
  TParams,
  TJson = unknown,
  TMeta = unknown,
> {
  getUserContent?: (params: TParams) => string | undefined;
  parseJsonChunk?: (chunk: StreamChunk) => TJson | undefined;
  extractMeta?: (events: TJson[]) => TMeta | undefined;
}

export interface StreamDataState<TParams, TJson = unknown, TMeta = unknown> {
  messages: () => StreamDataMessage<TJson, TMeta>[];
  state: () => StreamStatus;
  error: () => Error | null;
  send: (params: TParams) => void;
  retry: (params?: TParams) => void;
  reset: () => void;
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
      status: () => "idle",
      chunks: () => [],
      lastParams: () => null,
      start: noop,
      retry: noop,
      end: async () => {
        throw new Error("Cannot await stream completion on the server");
      },
      abort: noop,
    };
  }

  const [data, setData] = createSignal<string>("");
  const [streaming, setStreaming] = createSignal(false);
  const [error, setError] = createSignal<Error | null>(null);
  const [status, setStatus] = createSignal<StreamStatus>("idle");
  const [chunks, setChunks] = createSignal<StreamChunk[]>([]);
  const [lastParams, setLastParams] = createSignal<TParams | null>(null);

  let abortController: AbortController | null = null;
  let completionPromise: Promise<void> | null = null;
  let resolveCompletion: (() => void) | null = null;
  let rejectCompletion: ((error: Error) => void) | null = null;

  function prepareCompletionPromise() {
    completionPromise = new Promise<void>((resolve, reject) => {
      resolveCompletion = resolve;
      rejectCompletion = reject;
    });
  }

  function finalizeCompletionSuccess() {
    resolveCompletion?.();
    resolveCompletion = null;
    rejectCompletion = null;
  }

  function finalizeCompletionError(err: Error) {
    rejectCompletion?.(err);
    resolveCompletion = null;
    rejectCompletion = null;
  }

  function start(params: TParams) {
    // Abort any existing stream
    abort();

    // Reset state
    batch(() => {
      setData("");
      setError(null);
      setChunks([]);
      setStreaming(true);
      setStatus("streaming");
      setLastParams(() => params);
    });
    prepareCompletionPromise();

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
          batch(() => {
            setStreaming(false);
            setStatus("done");
          });
          finalizeCompletionSuccess();
          options?.onDone?.();
        },
        onError(err: Error) {
          batch(() => {
            setError(err);
            setStreaming(false);
            setStatus("error");
          });
          finalizeCompletionError(err);
          options?.onError?.(err);
        },
      }
    );
  }

  function retry(params?: TParams) {
    const nextParams = params ?? lastParams();
    if (!nextParams) return;
    start(nextParams);
  }

  function end() {
    if (status() === "done") return Promise.resolve();
    if (status() === "error") {
      return Promise.reject(error() ?? new Error("Stream failed"));
    }
    if (status() === "aborted") {
      return Promise.reject(new Error("Stream aborted"));
    }
    if (!completionPromise) {
      return Promise.reject(new Error("No active stream"));
    }
    return completionPromise;
  }

  function abort() {
    const shouldSetAborted = streaming();
    if (abortController) {
      abortController.abort();
      abortController = null;
    }
    batch(() => {
      setStreaming(false);
      if (shouldSetAborted) {
        setStatus("aborted");
      }
    });
    if (shouldSetAborted) {
      finalizeCompletionError(new Error("Stream aborted"));
    }
  }

  // Auto-cleanup on component unmount
  onCleanup(abort);

  return {
    data,
    streaming,
    error,
    status,
    chunks,
    lastParams,
    start,
    retry,
    end,
    abort,
  };
}

export function useStreamData<TParams, TJson = unknown, TMeta = unknown>(
  stream: StreamState<TParams>,
  options?: UseStreamDataOptions<TParams, TJson, TMeta>
): StreamDataState<TParams, TJson, TMeta> {
  const [messages, setMessages] = createSignal<StreamDataMessage<TJson, TMeta>[]>(
    []
  );
  let nextMessageId = 0;
  let managedStart = false;

  function replaceLastStreamingAssistant(
    updater: (
      message: StreamDataMessage<TJson, TMeta>
    ) => StreamDataMessage<TJson, TMeta>
  ) {
    setMessages((prev) => {
      const index = prev.findLastIndex(
        (msg) => msg.role === "assistant" && msg.status === "streaming"
      );
      if (index < 0) return prev;
      const updated = [...prev];
      updated[index] = updater(updated[index]);
      return updated;
    });
  }

  function appendAssistantPlaceholder() {
    const assistant: StreamDataMessage<TJson, TMeta> = {
      id: ++nextMessageId,
      role: "assistant",
      content: "",
      status: "streaming",
      events: [],
    };
    setMessages((prev) => [...prev, assistant]);
  }

  function send(params: TParams) {
    if (stream.streaming()) return;

    const userContent = options?.getUserContent?.(params);
    if (userContent) {
      const userMessage: StreamDataMessage<TJson, TMeta> = {
        id: ++nextMessageId,
        role: "user",
        content: userContent,
        status: "done",
        events: [],
      };
      setMessages((prev) => [...prev, userMessage]);
    }

    appendAssistantPlaceholder();
    managedStart = true;
    stream.start(params);
  }

  function retry(params?: TParams) {
    if (stream.streaming()) return;
    const nextParams = params ?? stream.lastParams();
    if (!nextParams) return;
    appendAssistantPlaceholder();
    managedStart = true;
    stream.start(nextParams);
  }

  function reset() {
    setMessages([]);
  }

  createEffect(() => {
    const status = stream.status();
    if (status !== "streaming" || managedStart) return;

    const params = stream.lastParams();
    if (!params) return;

    const userContent = options?.getUserContent?.(params);
    if (userContent) {
      const userMessage: StreamDataMessage<TJson, TMeta> = {
        id: ++nextMessageId,
        role: "user",
        content: userContent,
        status: "done",
        events: [],
      };
      setMessages((prev) => [...prev, userMessage]);
    }

    appendAssistantPlaceholder();
  });

  createEffect(() => {
    const text = stream.data();
    replaceLastStreamingAssistant((message) => ({ ...message, content: text }));
  });

  createEffect(() => {
    const status = stream.status();
    if (status === "idle" || status === "streaming") return;
    managedStart = false;

    const parsedEvents = stream
      .chunks()
      .filter((chunk) => chunk.type === "json")
      .map((chunk) => {
        if (options?.parseJsonChunk) {
          return options.parseJsonChunk(chunk);
        }
        return chunk.data as TJson;
      })
      .filter((event): event is TJson => event !== undefined);

    replaceLastStreamingAssistant((message) => ({
      ...message,
      status: status === "done" ? "done" : "error",
      events: parsedEvents,
      meta: options?.extractMeta?.(parsedEvents),
      error: status === "error" ? stream.error()?.message : undefined,
    }));
  });

  return {
    messages,
    state: stream.status,
    error: stream.error,
    send,
    retry,
    reset,
  };
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

function processSSEEventBlock(
  eventBlock: string,
  callbacks: SSECallbacks
): "done" | "error" | "continue" {
  const trimmed = eventBlock.trim();
  if (!trimmed) return "continue";

  for (const line of trimmed.split("\n")) {
    if (!line.startsWith("data: ")) continue;

    const jsonStr = line.slice(6);
    try {
      const chunk: StreamChunk = JSON.parse(jsonStr);

      if (chunk.type === "done") {
        callbacks.onDone();
        return "done";
      }
      if (chunk.type === "error") {
        callbacks.onError(new Error(chunk.message || "Stream error from server"));
        return "error";
      }
      callbacks.onChunk(chunk);
    } catch {
      // Skip malformed JSON lines
    }
  }

  return "continue";
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
      if (done) {
        buffer += decoder.decode();
        const terminal = processSSEEventBlock(buffer, callbacks);
        if (terminal !== "continue") return;
        callbacks.onError(new StreamIncompleteError());
        return;
      }

      buffer += decoder.decode(value, { stream: true });

      // SSE events are separated by double newlines
      const events = buffer.split("\n\n");
      // Last element might be incomplete -- keep it in the buffer
      buffer = events.pop() || "";

      for (const event of events) {
        const terminal = processSSEEventBlock(event, callbacks);
        if (terminal !== "continue") return;
      }
    }
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
