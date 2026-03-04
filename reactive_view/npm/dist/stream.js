import { createSignal, createEffect, onCleanup, batch } from "solid-js";
import { isServer } from "solid-js/web";
import { getCSRFToken } from "./csrf.js";
import { getSSRRequestContext } from "./request-context.js";
export class StreamIncompleteError extends Error {
    constructor(message = "Stream ended unexpectedly before completion") {
        super(message);
        this.name = "StreamIncompleteError";
    }
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
export function createStream(loaderPath, mutationName, options) {
    // Server-side: return inert state (streams are client-only)
    if (isServer) {
        const noop = () => { };
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
    const [data, setData] = createSignal("");
    const [streaming, setStreaming] = createSignal(false);
    const [error, setError] = createSignal(null);
    const [status, setStatus] = createSignal("idle");
    const [chunks, setChunks] = createSignal([]);
    const [lastParams, setLastParams] = createSignal(null);
    let abortController = null;
    let completionPromise = null;
    let resolveCompletion = null;
    let rejectCompletion = null;
    function prepareCompletionPromise() {
        completionPromise = new Promise((resolve, reject) => {
            resolveCompletion = resolve;
            rejectCompletion = reject;
        });
    }
    function finalizeCompletionSuccess() {
        resolveCompletion?.();
        resolveCompletion = null;
        rejectCompletion = null;
    }
    function finalizeCompletionError(err) {
        rejectCompletion?.(err);
        resolveCompletion = null;
        rejectCompletion = null;
    }
    function start(params) {
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
        connectSSE(loaderPath, mutationName, params, abortController.signal, {
            onChunk(chunk) {
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
            onError(err) {
                batch(() => {
                    setError(err);
                    setStreaming(false);
                    setStatus("error");
                });
                finalizeCompletionError(err);
                options?.onError?.(err);
            },
        });
    }
    function retry(params) {
        const nextParams = params ?? lastParams();
        if (!nextParams)
            return;
        start(nextParams);
    }
    function end() {
        if (status() === "done")
            return Promise.resolve();
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
export function useStreamData(stream, options) {
    const [messages, setMessages] = createSignal([]);
    let processedChunkCount = 0;
    createEffect(() => {
        const nextChunks = stream.chunks();
        if (nextChunks.length < processedChunkCount) {
            processedChunkCount = 0;
            setMessages([]);
        }
        if (nextChunks.length === processedChunkCount)
            return;
        const parseChunk = options?.parseChunk;
        const nextMessages = [];
        for (let i = processedChunkCount; i < nextChunks.length; i += 1) {
            const chunk = nextChunks[i];
            const message = parseChunk
                ? parseChunk(chunk)
                : chunk.type === "json"
                    ? chunk.data
                    : chunk.type === "text"
                        ? chunk.chunk
                        : undefined;
            if (message !== undefined) {
                nextMessages.push(message);
            }
        }
        processedChunkCount = nextChunks.length;
        if (nextMessages.length > 0) {
            setMessages((prev) => [...prev, ...nextMessages]);
        }
    });
    return {
        messages,
        reset: () => {
            processedChunkCount = 0;
            setMessages([]);
        },
    };
}
function processSSEEventBlock(eventBlock, callbacks) {
    const trimmed = eventBlock.trim();
    if (!trimmed)
        return "continue";
    for (const line of trimmed.split("\n")) {
        if (!line.startsWith("data: "))
            continue;
        const jsonStr = line.slice(6);
        try {
            const chunk = JSON.parse(jsonStr);
            if (chunk.type === "done") {
                callbacks.onDone();
                return "done";
            }
            if (chunk.type === "error") {
                callbacks.onError(new Error(chunk.message || "Stream error from server"));
                return "error";
            }
            callbacks.onChunk(chunk);
        }
        catch {
            // Skip malformed JSON lines
        }
    }
    return "continue";
}
function drainBufferedSSEEvents(buffer, callbacks) {
    let separatorIndex = buffer.indexOf("\n\n");
    while (separatorIndex !== -1) {
        const terminal = processSSEEventBlock(buffer.slice(0, separatorIndex), callbacks);
        if (terminal !== "continue") {
            return { buffer: "", terminal };
        }
        buffer = buffer.slice(separatorIndex + 2);
        separatorIndex = buffer.indexOf("\n\n");
    }
    return { buffer, terminal: "continue" };
}
/**
 * @internal
 * Connect to the Rails streaming endpoint and parse SSE events.
 * Uses fetch + ReadableStream for broad browser compatibility.
 */
async function connectSSE(loaderPath, mutationName, params, signal, callbacks) {
    const railsBaseUrl = getRailsBaseUrl();
    const url = new URL(`/_reactive_view/loaders/${loaderPath}/stream`, railsBaseUrl);
    url.searchParams.set("_mutation", mutationName);
    const headers = {
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
        const { cookies: contextCookies } = getSSRRequestContext();
        const cookies = contextCookies || globalThis.__REACTIVE_VIEW_COOKIES__;
        if (cookies)
            headers["Cookie"] = cookies;
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
                if (errorData.error)
                    errorMessage = errorData.error;
            }
            catch {
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
                const drained = drainBufferedSSEEvents(buffer, callbacks);
                if (drained.terminal !== "continue")
                    return;
                const finalEvent = processSSEEventBlock(drained.buffer, callbacks);
                if (finalEvent !== "continue")
                    return;
                callbacks.onError(new StreamIncompleteError());
                return;
            }
            buffer += decoder.decode(value, { stream: true });
            const drained = drainBufferedSSEEvents(buffer, callbacks);
            buffer = drained.buffer;
            if (drained.terminal !== "continue")
                return;
        }
    }
    catch (err) {
        if (signal.aborted)
            return; // Expected abort -- don't report as error
        callbacks.onError(err instanceof Error ? err : new Error(String(err)));
    }
}
/**
 * @internal Get Rails base URL (same logic as loader.ts / mutation.ts)
 */
function getRailsBaseUrl() {
    if (isServer) {
        const { railsBaseUrl } = getSSRRequestContext();
        if (railsBaseUrl)
            return railsBaseUrl;
        const globalRailsUrl = globalThis.__RAILS_BASE_URL__;
        if (globalRailsUrl)
            return globalRailsUrl;
        return "http://localhost:3000";
    }
    const clientRailsUrl = window.__RAILS_BASE_URL__;
    if (clientRailsUrl)
        return clientRailsUrl;
    return window.location.origin;
}
