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
export declare class StreamIncompleteError extends Error {
    constructor(message?: string);
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
export interface UseStreamDataOptions<TMessage = unknown> {
    /**
     * Optional parser for incoming chunks.
     * Return undefined to skip a chunk.
     */
    parseChunk?: (chunk: StreamChunk) => TMessage | undefined;
}
export interface StreamDataState<TMessage = unknown> {
    messages: () => TMessage[];
    reset: () => void;
}
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
export declare function createStream<TParams = Record<string, unknown>>(loaderPath: string, mutationName: string, options?: StreamOptions): StreamState<TParams>;
export declare function useStreamData<TParams, TMessage = unknown>(stream: StreamState<TParams>, options?: UseStreamDataOptions<TMessage>): StreamDataState<TMessage>;
//# sourceMappingURL=stream.d.ts.map