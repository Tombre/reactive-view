# Streaming Support Plan for ReactiveView

**Status:** Planning
**Priority:** High
**Scope:** Mutation-triggered SSE streaming (MVP), with loader-based streaming deferred to a follow-up

## Table of Contents

- [Overview](#overview)
- [Design Decisions](#design-decisions)
- [Architecture](#architecture)
- [Wire Protocol](#wire-protocol)
- [Phase 1: Ruby Streaming Infrastructure](#phase-1-ruby-streaming-infrastructure)
- [Phase 2: TypeScript Streaming Infrastructure](#phase-2-typescript-streaming-infrastructure)
- [Phase 3: TypeScript Generator Extensions](#phase-3-typescript-generator-extensions)
- [Phase 4: Example App -- AI Chat Page](#phase-4-example-app----ai-chat-page)
- [Phase 5: Testing](#phase-5-testing)
- [File Change Summary](#file-change-summary)
- [Risks & Considerations](#risks--considerations)
- [Future Work](#future-work)

---

## Overview

Add SSE-based streaming support to ReactiveView, enabling AI text streaming (and other progressive data delivery) from Rails mutation methods to SolidJS components.

**Use case:** A user submits a prompt, Rails calls an AI service, and tokens stream back to the browser in real time via Server-Sent Events.

**Scope boundaries:**

- **In scope (MVP):** Mutation-triggered streams. A mutation method like `generate` calls `render_stream` and yields text/JSON chunks over SSE. The frontend consumes this via a `useStream()` hook.
- **Out of scope (future):** Loader-based streaming (progressive page load data). The `load` method remains synchronous JSON for now. Streaming SSR (doc `docs/agent/tasks/09-streaming-ssr.md`) is a separate initiative.

---

## Design Decisions

These decisions were made during the planning conversation:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Transport | SSE (Server-Sent Events) | Simpler than WebSockets, works through proxies, unidirectional (server->client), built-in browser reconnection, no extra dependencies |
| Interaction model | Mutation-triggered | User action (form submit / programmatic call) triggers a stream. Natural fit for AI generation. Avoids complications with SSR, caching, and preloading that loader-based streaming would introduce |
| Ruby DX | Block-based yielding (`render_stream do \|out\| ... end`) | Feels Rubyish, similar to `ActionController::Live`. The block receives a writer object for sending chunks |
| Data format | Configurable (text + JSON) | `out << "text"` for plain text chunks, `out.json({...})` for structured events. Both are wrapped in SSE `data:` lines as JSON envelopes |
| Frontend hook | Tuple pattern with `.start()` escape hatch | `useStream("mutation_name")` returns `[StreamForm, stream]`, consistent with `useForm` pattern. `stream.start()` available for programmatic use |
| Endpoint location | Under existing engine (`/_reactive_view/loaders/{path}/stream`) | Consistent with `load` and `mutate` endpoints. Auth, CSRF, and cookie forwarding work the same way |
| Generated code | `useStream()` generated for all mutations initially | TypeScript generator produces streaming hooks alongside existing mutation forms. Future `stream: true` annotation can limit this to stream-capable mutations only |

---

## Architecture

### Current Request Flow (Mutations)

```
Browser                           Rails                          
  |                                 |
  |  POST /_reactive_view/          |
  |    loaders/{path}/mutate        |
  |  =============================> |
  |                                 |  LoaderDataController#mutate
  |                                 |  -> loader.update()
  |                                 |  -> MutationResult
  |  <============================= |
  |  JSON response (complete)       |
```

### New Streaming Flow

```
Browser                           Rails
  |                                 |
  |  POST /_reactive_view/          |
  |    loaders/{path}/stream        |
  |    ?_mutation=generate          |
  |  =============================> |
  |                                 |  LoaderDataController#stream
  |                                 |  -> loader.generate()
  |                                 |  -> StreamResponse (block)
  |  <-- SSE: text chunk 1 -------- |  -> writer << "The "
  |  <-- SSE: text chunk 2 -------- |  -> writer << "answer "
  |  <-- SSE: text chunk 3 -------- |  -> writer << "is 42."
  |  <-- SSE: json event ---------- |  -> writer.json({usage: {tokens: 12}})
  |  <-- SSE: done event ---------- |  -> (block ends, writer auto-closes)
  |                                 |
```

### Component Architecture

```
                     Ruby Gem (reactive_view/)
                     ========================

  loader.rb                     stream_writer.rb          stream_response.rb
  +------------------+          +------------------+      +------------------+
  | render_stream    |--------->| StreamResponse   |----->| block stored     |
  | (new method)     |          | (value object)   |      | for deferred     |
  +------------------+          +------------------+      | execution)       |
                                                          +------------------+
  loader_data_controller.rb
  +---------------------------+
  | #stream (new action)      |     +------------------+
  | - validates CSRF          |---->| StreamWriter     |
  | - calls mutation method   |     | - << (text)      |
  | - detects StreamResponse  |     | - json(data)     |
  | - sets SSE headers        |     | - event(name, d) |
  | - yields writer to block  |     | - close          |
  | - uses ActionController:: |     +------------------+
  |   Live for streaming      |            |
  +---------------------------+            |
                                           v
                                    SSE over HTTP
                                           |
                     npm package (@reactive-view/core)
                     ===================================
                                           |
  stream.ts                                |
  +---------------------------+            |
  | createStream()            |<-----------+
  | - POST fetch with         |
  |   ReadableStream reader   |
  | - parses SSE data: lines  |
  | - updates SolidJS signals |
  | - handles abort/cleanup   |
  +---------------------------+
           |
           v
  Generated per-route file (.reactive_view/types/loaders/{path}.ts)
  +---------------------------+
  | useStream("generate")     |
  | - returns [StreamForm,    |
  |   stream] tuple           |
  | - StreamForm auto-submits |
  |   and calls stream.start()|
  +---------------------------+
```

---

## Wire Protocol

The stream endpoint uses **Server-Sent Events** over a POST request. Each event is a JSON envelope on a `data:` line.

### Event Types

| Event type | Description | Payload |
|------------|-------------|---------|
| `text` | Plain text chunk (AI token) | `{ "type": "text", "chunk": "hello " }` |
| `json` | Structured data event | `{ "type": "json", "data": { "key": "value" } }` |
| `error` | Stream error | `{ "type": "error", "message": "Something went wrong" }` |
| `done` | Stream complete | `{ "type": "done" }` |
| Custom | User-defined event type | `{ "type": "custom_name", ...payload }` |

### Example SSE Response

```http
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
X-Accel-Buffering: no

data: {"type":"text","chunk":"The "}

data: {"type":"text","chunk":"answer "}

data: {"type":"text","chunk":"is "}

data: {"type":"text","chunk":"42."}

data: {"type":"json","data":{"usage":{"prompt_tokens":10,"completion_tokens":4}}}

data: {"type":"done"}

```

Each event is a single `data:` line followed by two newlines (`\n\n`), per the SSE spec. The client parses each line, extracts the JSON after `data: `, and dispatches based on the `type` field.

---

## Phase 1: Ruby Streaming Infrastructure

### 1.1 Create `ReactiveView::StreamResponse`

**File:** `reactive_view/lib/reactive_view/stream_response.rb`

A simple value object that wraps the block passed to `render_stream`. Its presence signals to the controller that this mutation wants SSE output rather than a JSON response.

```ruby
# frozen_string_literal: true

module ReactiveView
  # Value object returned by Loader#render_stream.
  # Wraps a block that will be executed with a StreamWriter
  # when the controller is ready to stream the SSE response.
  #
  # @example
  #   result = render_stream { |out| out << "hello" }
  #   result.is_a?(StreamResponse) # => true
  #   result.block.call(writer)
  class StreamResponse
    attr_reader :block

    # @param block [Proc] Block that receives a StreamWriter
    def initialize(block)
      @block = block
    end
  end
end
```

### 1.2 Create `ReactiveView::StreamWriter`

**File:** `reactive_view/lib/reactive_view/stream_writer.rb`

The writer object yielded to `render_stream` blocks. Wraps an `ActionController::Live` response stream and emits SSE-formatted events.

```ruby
# frozen_string_literal: true

module ReactiveView
  # Writer for SSE (Server-Sent Events) streaming responses.
  # Yielded to the block passed to Loader#render_stream.
  #
  # Wraps an ActionController::Live response stream and formats
  # data as SSE events (data: JSON\n\n).
  #
  # @example Sending text chunks (AI tokens)
  #   render_stream do |out|
  #     out << "Hello "
  #     out << "world!"
  #   end
  #
  # @example Sending structured JSON
  #   render_stream do |out|
  #     out << "Response text"
  #     out.json({ usage: { tokens: 42 } })
  #   end
  #
  # @example Sending custom named events
  #   render_stream do |out|
  #     out.event("progress", { percent: 50 })
  #     out.event("progress", { percent: 100 })
  #   end
  class StreamWriter
    # @param stream [ActionController::Live::Buffer] The response stream
    def initialize(stream)
      @stream = stream
      @closed = false
    end

    # Send a plain text chunk. This is the primary method for AI token streaming.
    # Each call emits one SSE event with type "text".
    #
    # @param text [String] The text chunk to send
    # @return [self] For chaining: out << "hello " << "world"
    def <<(text)
      write_event(type: "text", chunk: text.to_s)
      self
    end

    # Send a structured JSON data event.
    # Use this for metadata, progress info, or any structured payload.
    #
    # @param data [Hash, Array] The data to send
    # @return [void]
    def json(data)
      write_event(type: "json", data: data)
    end

    # Send a custom named event.
    # Use this for application-specific event types.
    #
    # @param name [String] The event type name
    # @param data [Hash] Additional event data (merged into the payload)
    # @return [void]
    def event(name, data = {})
      write_event(**{ type: name.to_s }.merge(data))
    end

    # Close the stream. Sends a "done" event first if not already closed.
    # This is called automatically by the controller's ensure block,
    # but can be called explicitly for early termination.
    #
    # @return [void]
    def close
      return if @closed

      write_event(type: "done")
      @stream.close
      @closed = true
    end

    # @return [Boolean] Whether the stream has been closed
    def closed?
      @closed
    end

    private

    # Write a single SSE event line.
    #
    # @param payload [Hash] The event payload, serialized as JSON
    # @raise [RuntimeError] If the stream is already closed
    def write_event(**payload)
      raise "Stream already closed" if @closed

      @stream.write("data: #{payload.to_json}\n\n")
    end
  end
end
```

### 1.3 Add `render_stream` to `ReactiveView::Loader`

**File:** `reactive_view/lib/reactive_view/loader.rb` (modify)

Add the `render_stream` helper method in the "Mutation Helpers" section, after `mutation_redirect`:

```ruby
# Return a streaming SSE response from a mutation method.
# The block receives a StreamWriter for sending chunks to the client.
#
# This is used for long-running operations like AI text generation
# where results should be streamed to the client as they become available.
#
# @yield [writer] Block that sends data through the stream
# @yieldparam writer [StreamWriter] Writer for sending text, JSON, or custom events
# @return [StreamResponse] A stream response object (handled by the controller)
#
# @example Stream AI-generated text
#   def generate
#     render_stream do |out|
#       AiService.chat(params[:prompt]).each_chunk do |token|
#         out << token
#       end
#     end
#   end
#
# @example Stream with metadata
#   def generate
#     render_stream do |out|
#       result = AiService.chat(params[:prompt])
#       result.each_chunk { |token| out << token }
#       out.json({ usage: result.usage })
#     end
#   end
def render_stream(&block)
  raise ArgumentError, "render_stream requires a block" unless block_given?

  StreamResponse.new(block)
end
```

### 1.4 Add `#stream` action to `LoaderDataController`

**File:** `reactive_view/app/controllers/reactive_view/loader_data_controller.rb` (modify)

Include `ActionController::Live` and add the `stream` action. The stream action:

1. Validates CSRF (POST request)
2. Resolves the loader and mutation method
3. Calls the mutation method
4. If it returns a `StreamResponse`, sets SSE headers and executes the block with a `StreamWriter`
5. If it returns something else, falls back to regular JSON

```ruby
include ActionController::Live

# POST /_reactive_view/loaders/:path/stream
# Handles SSE streaming responses from mutation methods that call render_stream.
#
# The mutation method should return a StreamResponse (via render_stream).
# If it returns a regular value, falls back to JSON response.
def stream
  loader_class = LoaderRegistry.class_for_path(loader_path)
  loader = build_loader(loader_class)

  mutation_name = params[:_mutation].presence || "stream"
  mutation_method = mutation_name.to_sym

  unless valid_mutation_method?(loader, mutation_method)
    response.headers["Content-Type"] = "application/json"
    response.stream.write({ error: "Stream mutation '#{mutation_name}' not defined" }.to_json)
    response.stream.close
    return
  end

  result = loader.public_send(mutation_method)

  unless result.is_a?(StreamResponse)
    # Not a stream response -- fall back to JSON
    response.headers["Content-Type"] = "application/json"
    response.stream.write(render_mutation_result_json(result))
    response.stream.close
    return
  end

  # Set SSE headers
  response.headers["Content-Type"] = "text/event-stream"
  response.headers["Cache-Control"] = "no-cache"
  response.headers["Connection"] = "keep-alive"
  response.headers["X-Accel-Buffering"] = "no"

  writer = StreamWriter.new(response.stream)
  begin
    result.block.call(writer)
  rescue => e
    ReactiveView.logger.error "[ReactiveView] Stream error: #{e.message}"
    ReactiveView.logger.error e.backtrace&.first(5)&.join("\n") if e.backtrace
    writer.event("error", message: e.message) unless writer.closed?
  ensure
    writer.close unless writer.closed?
  end
rescue LoaderNotFoundError => e
  response.headers["Content-Type"] = "application/json"
  response.stream.write({ error: e.message }.to_json)
  response.stream.close
rescue StandardError => e
  handle_stream_error(e)
end
```

Also add these private helper methods:

```ruby
# Serialize a mutation result to JSON string (for stream fallback).
# Mirrors render_mutation_result but returns a string instead of calling render.
def render_mutation_result_json(result)
  case result
  when MutationResult then result.to_json_hash.to_json
  when Hash then result.to_json
  when nil then { success: true }.to_json
  else { success: true, data: result }.to_json
  end
end

def handle_stream_error(error)
  ReactiveView.logger.error "[ReactiveView] Stream error: #{error.message}"
  ReactiveView.logger.error error.backtrace&.join("\n") if error.backtrace
  begin
    response.stream.write("data: #{({ type: 'error', message: error.message }).to_json}\n\n")
    response.stream.close
  rescue => e
    ReactiveView.logger.error "[ReactiveView] Failed to write stream error: #{e.message}"
  end
end
```

Update the CSRF / forgery protection at the top of the controller:

```ruby
# Current:
skip_forgery_protection only: [:show]
protect_from_forgery with: :exception, only: [:mutate]
before_action :verify_csrf_for_mutation, only: [:mutate]

# Change to:
skip_forgery_protection only: [:show]
protect_from_forgery with: :exception, only: [:mutate, :stream]
before_action :verify_csrf_for_mutation, only: [:mutate, :stream]
```

**Important note on `ActionController::Live` and `render`:** When using `ActionController::Live`, you cannot call `render` after writing to the stream. The `stream` action must only use `response.stream.write` / `response.stream.close`. This is why the error handling writes directly to the stream rather than using `render json:`.

### 1.5 Add streaming route to engine

**File:** `reactive_view/config/routes.rb` (modify)

Add the streaming route alongside the existing `load` and `mutate` routes:

```ruby
ReactiveView::Engine.routes.draw do
  # Existing routes
  get  'loaders/*path/load',   to: 'loader_data#show',   as: :loader_data
  match 'loaders/*path/mutate', to: 'loader_data#mutate',
                                 via: %i[post put patch delete], as: :loader_mutate

  # New: SSE streaming endpoint for mutations
  post 'loaders/*path/stream', to: 'loader_data#stream', as: :loader_stream
end
```

### 1.6 Register new files in main require

**File:** `reactive_view/lib/reactive_view.rb` (modify)

Add requires for the two new files, after `mutation_result`:

```ruby
require_relative 'reactive_view/mutation_result'
require_relative 'reactive_view/stream_response'   # NEW
require_relative 'reactive_view/stream_writer'      # NEW
require_relative 'reactive_view/loader_registry'
```

---

## Phase 2: TypeScript Streaming Infrastructure

### 2.1 Create `stream.ts` in npm package

**File:** `reactive_view/npm/src/stream.ts`

This file contains the core streaming primitives:

- **`StreamChunk` interface** -- The shape of each parsed SSE event
- **`StreamState` interface** -- The reactive state returned by `createStream()`
- **`createStream()` function** -- Creates a stream instance with SolidJS signals and SSE connection logic
- **`connectSSE()` internal function** -- Handles the fetch + ReadableStream parsing

```typescript
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
export interface StreamState {
  /** Accumulated text data from all "text" chunks */
  data: () => string;
  /** Whether the stream is currently active */
  streaming: () => boolean;
  /** Error if the stream failed */
  error: () => Error | null;
  /** All received chunks (text, json, and custom) */
  chunks: () => StreamChunk[];
  /** Start the stream with the given params (programmatic trigger) */
  start: (params: Record<string, unknown>) => void;
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
export function createStream(
  loaderPath: string,
  mutationName: string,
  options?: StreamOptions
): StreamState {
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

  function start(params: Record<string, unknown>) {
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

    connectSSE(loaderPath, mutationName, params, abortController.signal, {
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
    });
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
```

### 2.2 Export streaming primitives from index.ts

**File:** `reactive_view/npm/src/index.ts` (modify)

Add a new section after the Mutations exports:

```typescript
// ============================================================================
// ReactiveView -- Streaming
// ============================================================================

export {
  createStream,
} from "./stream.js";
export type { StreamState, StreamChunk, StreamOptions } from "./stream.js";
```

---

## Phase 3: TypeScript Generator Extensions

### 3.1 Generate `useStream()` for mutations

**File:** `reactive_view/lib/reactive_view/types/typescript_generator.rb` (modify)

The TypeScript generator already produces `useForm()` hooks for mutations. We extend it to also produce `useStream()` hooks.

#### Changes to `build_imports`

Add `createStream` and `StreamState` to the imports when mutations are present:

```ruby
def build_imports(has_mutations)
  imports = []

  imports << 'import { createLoaderQuery, createAsync, useParams, type AccessorWithLatest } from "@reactive-view/core";'

  if has_mutations
    imports << 'import type { JSX } from "@reactive-view/core";'
    imports << 'import { createMutation, useAction, useSubmission, useSubmissions } from "@reactive-view/core";'
    imports << 'import type { MutationResult } from "@reactive-view/core";'
    # NEW: streaming imports
    imports << 'import { createStream, type StreamState } from "@reactive-view/core";'
  end

  imports.join("\n") + "\n"
end
```

#### New method: `build_streaming_section`

Add a new method that generates the `useStream()` hook, called from `build_loader_file` after `build_mutations_section`:

```ruby
# Build the streaming section (useStream hook for mutations)
def build_streaming_section(loader)
  entries = loader[:mutation_schemas].map do |mutation_name, _schema|
    base_name = mutation_name.to_s
    { name: base_name }
  end

  mutation_names_union = entries.map { |e| "\"#{e[:name]}\"" }.join(' | ')

  <<~TYPESCRIPT

    // ============================================================================
    // Streaming (SSE)
    // ============================================================================

    /** Available stream mutation names for this route */
    type StreamMutationName = #{mutation_names_union};

    /**
     * Hook for SSE streaming from a mutation endpoint.
     * Returns a `[StreamForm, stream]` tuple similar to `useForm`.
     *
     * The `StreamForm` component handles form submission and starts the stream.
     * The `stream` object provides reactive state and a programmatic `start()` method.
     *
     * @param name - The mutation name (#{entries.map { |e| "\"#{e[:name]}\"" }.join(', ')})
     * @returns A readonly tuple of `[StreamFormComponent, StreamState]`
     *
     * @example
     * const [StreamForm, stream] = useStream("#{entries.first[:name]}");
     *
     * <StreamForm>
     *   <input name="prompt" />
     *   <button type="submit" disabled={stream.streaming()}>Send</button>
     * </StreamForm>
     *
     * <Show when={stream.data()}>
     *   <p>{stream.data()}</p>
     * </Show>
     *
     * @example Programmatic usage
     * const [, stream] = useStream("#{entries.first[:name]}");
     * stream.start({ prompt: "Hello" });
     */
    export function useStream<T extends StreamMutationName>(name: T): readonly [
      (props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">) => JSX.Element,
      StreamState
    ] {
      const stream = createStream("#{loader[:path]}", name);

      function StreamForm(
        props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">
      ) {
        return (
          <form
            {...props}
            onSubmit={(e: SubmitEvent) => {
              e.preventDefault();
              const formData = new FormData(e.target as HTMLFormElement);
              const params: Record<string, unknown> = {};
              formData.forEach((value, key) => { params[key] = value; });
              stream.start(params);
              // Call user's onSubmit if provided
              if (typeof props.onSubmit === "function") {
                (props.onSubmit as (e: SubmitEvent) => void)(e);
              }
            }}
          />
        );
      }

      return [StreamForm, stream] as const;
    }
  TYPESCRIPT
end
```

#### Update `build_loader_file` to include streaming section

```ruby
def build_loader_file(loader)
  # ... existing code ...

  # Mutation interfaces, actions, and forms
  parts << build_mutations_section(loader) if has_mutations

  # NEW: Streaming hooks for mutations
  parts << build_streaming_section(loader) if has_mutations

  parts.join("\n")
end
```

### 3.2 Example generated output

For a loader at `ai/chat` with a `generate` mutation, the generator would produce (in addition to existing mutation code):

```typescript
// ============================================================================
// Streaming (SSE)
// ============================================================================

type StreamMutationName = "generate";

export function useStream<T extends StreamMutationName>(name: T): readonly [
  (props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">) => JSX.Element,
  StreamState
] {
  const stream = createStream("ai/chat", name);

  function StreamForm(
    props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">
  ) {
    return (
      <form
        {...props}
        onSubmit={(e: SubmitEvent) => {
          e.preventDefault();
          const formData = new FormData(e.target as HTMLFormElement);
          const params: Record<string, unknown> = {};
          formData.forEach((value, key) => { params[key] = value; });
          stream.start(params);
          if (typeof props.onSubmit === "function") {
            (props.onSubmit as (e: SubmitEvent) => void)(e);
          }
        }}
      />
    );
  }

  return [StreamForm, stream] as const;
}
```

---

## Phase 4: Example App -- AI Chat Page

### 4.1 Chat loader with simulated AI streaming

**File:** `examples/reactive_view_example/app/pages/ai/chat.loader.rb`

```ruby
# frozen_string_literal: true

class Pages::Ai::ChatLoader < ReactiveView::Loader
  shape :load do
    param :greeting, ReactiveView::Types::String
    param :model, ReactiveView::Types::String
  end

  shape :generate do
    param :prompt, ReactiveView::Types::String
  end

  def load
    {
      greeting: "Hello! I'm a simulated AI assistant. Ask me anything!",
      model: "reactive-view-demo-v1"
    }
  end

  def generate
    prompt = shapes.generate(params)[:prompt]

    render_stream do |out|
      # Simulate AI response with delayed token generation
      response_text = generate_response(prompt)
      words = response_text.split(" ")

      words.each_with_index do |word, i|
        sleep(rand(0.03..0.08)) # Simulate variable token latency
        separator = i < words.length - 1 ? " " : ""
        out << "#{word}#{separator}"
      end

      # Send metadata at the end (like token usage)
      out.json({
        usage: {
          prompt_tokens: prompt.split(" ").length,
          completion_tokens: words.length,
          model: "reactive-view-demo-v1"
        }
      })
    end
  end

  private

  def generate_response(prompt)
    responses = [
      "That's an interesting question! Let me think about this carefully. " \
      "Based on my analysis, I'd say the key factors to consider are the context " \
      "of your question, the underlying assumptions, and the practical implications. " \
      "I hope this perspective is helpful for your understanding.",

      "Great question! Here's what I know about that topic. " \
      "The fundamental concept revolves around understanding how different components " \
      "interact with each other in a system. When you break it down step by step, " \
      "the solution becomes much clearer. Let me know if you'd like more details.",

      "I appreciate you asking about that! This is a topic I find fascinating. " \
      "The short answer is that it depends on your specific use case and requirements. " \
      "However, I can share some general principles that tend to apply across " \
      "most situations. Would you like me to elaborate on any particular aspect?"
    ]

    responses.sample
  end
end
```

### 4.2 Chat page component

**File:** `examples/reactive_view_example/app/pages/ai/chat.tsx`

```tsx
import {
  createSignal,
  createEffect,
  Show,
  For,
  Suspense,
} from "@reactive-view/core";
import { useLoaderData, useStream } from "#loaders/ai/chat";

interface Message {
  id: number;
  role: "user" | "assistant";
  content: string;
  streaming?: boolean;
  metadata?: {
    usage?: {
      prompt_tokens: number;
      completion_tokens: number;
      model: string;
    };
  };
}

let messageId = 0;

export default function AiChatPage() {
  const data = useLoaderData();
  const [StreamForm, stream] = useStream("generate");
  const [messages, setMessages] = createSignal<Message[]>([]);
  const [input, setInput] = createSignal("");

  // Update the current assistant message as stream data arrives
  createEffect(() => {
    const text = stream.data();
    if (!text) return;

    setMessages((prev) => {
      const last = prev[prev.length - 1];
      if (last && last.role === "assistant" && last.streaming) {
        return [...prev.slice(0, -1), { ...last, content: text }];
      }
      return prev;
    });
  });

  // Handle stream completion -- capture metadata from JSON chunks
  createEffect(() => {
    const isStreaming = stream.streaming();
    if (isStreaming) return; // Still streaming

    const allChunks = stream.chunks();
    if (allChunks.length === 0) return;

    // Find metadata from json chunks
    const jsonChunks = allChunks.filter((c) => c.type === "json");
    const metadata = jsonChunks.length > 0 ? (jsonChunks[0].data as Message["metadata"]) : undefined;

    // Mark the assistant message as done
    setMessages((prev) => {
      const last = prev[prev.length - 1];
      if (last && last.role === "assistant") {
        return [
          ...prev.slice(0, -1),
          { ...last, streaming: false, metadata: metadata ? { usage: metadata.usage } : undefined },
        ];
      }
      return prev;
    });
  });

  const handleSubmit = () => {
    const prompt = input().trim();
    if (!prompt || stream.streaming()) return;

    // Add user message
    const userMsg: Message = {
      id: ++messageId,
      role: "user",
      content: prompt,
    };

    // Add placeholder assistant message
    const assistantMsg: Message = {
      id: ++messageId,
      role: "assistant",
      content: "",
      streaming: true,
    };

    setMessages((prev) => [...prev, userMsg, assistantMsg]);
    setInput("");

    // stream.start() is called automatically by StreamForm's onSubmit
  };

  return (
    <div class="max-w-3xl mx-auto p-6">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">AI Chat</h1>
        <Suspense fallback={<p class="text-gray-400">Loading...</p>}>
          <p class="text-gray-500">{data()?.greeting}</p>
          <p class="text-xs text-gray-400 mt-1">Model: {data()?.model}</p>
        </Suspense>
      </div>

      {/* Message history */}
      <div class="space-y-4 mb-6 min-h-[200px]">
        <Show
          when={messages().length > 0}
          fallback={
            <div class="text-center text-gray-400 py-12">
              <p class="text-lg">No messages yet</p>
              <p class="text-sm mt-1">
                Type a message below to start the conversation
              </p>
            </div>
          }
        >
          <For each={messages()}>
            {(msg) => (
              <div
                class={`p-4 rounded-lg ${
                  msg.role === "user"
                    ? "bg-blue-50 border border-blue-100 ml-8"
                    : "bg-gray-50 border border-gray-100 mr-8"
                }`}
              >
                <div class="flex items-center gap-2 mb-1">
                  <span
                    class={`text-xs font-semibold uppercase tracking-wide ${
                      msg.role === "user" ? "text-blue-600" : "text-gray-600"
                    }`}
                  >
                    {msg.role === "user" ? "You" : "AI"}
                  </span>
                  <Show when={msg.streaming}>
                    <span class="text-xs text-green-500 animate-pulse">
                      streaming...
                    </span>
                  </Show>
                </div>
                <p class="text-gray-800 whitespace-pre-wrap">
                  {msg.content}
                  <Show when={msg.streaming}>
                    <span class="inline-block w-2 h-4 bg-gray-400 animate-pulse ml-0.5" />
                  </Show>
                </p>
                <Show when={msg.metadata?.usage}>
                  <div class="mt-2 text-xs text-gray-400">
                    {msg.metadata!.usage!.prompt_tokens} prompt tokens,{" "}
                    {msg.metadata!.usage!.completion_tokens} completion tokens
                  </div>
                </Show>
              </div>
            )}
          </For>
        </Show>

        {/* Error display */}
        <Show when={stream.error()}>
          <div class="p-4 rounded-lg bg-red-50 border border-red-200">
            <p class="text-red-700 text-sm">
              Error: {stream.error()?.message}
            </p>
          </div>
        </Show>
      </div>

      {/* Input form */}
      <StreamForm onSubmit={handleSubmit}>
        <div class="flex gap-3">
          <input
            name="prompt"
            type="text"
            value={input()}
            onInput={(e) => setInput(e.target.value)}
            placeholder="Type your message..."
            disabled={stream.streaming()}
            class="flex-1 border border-gray-300 rounded-lg px-4 py-2.5
                   focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent
                   disabled:bg-gray-100 disabled:text-gray-500"
          />
          <button
            type="submit"
            disabled={stream.streaming() || !input().trim()}
            class="px-6 py-2.5 bg-blue-600 text-white font-medium rounded-lg
                   hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500
                   disabled:opacity-50 disabled:cursor-not-allowed
                   transition-colors duration-150"
          >
            <Show when={!stream.streaming()} fallback="Generating...">
              Send
            </Show>
          </button>
        </div>
      </StreamForm>
    </div>
  );
}
```

### 4.3 Add navigation link

**File:** `examples/reactive_view_example/app/pages/_components/Navigation.tsx` (modify)

Add an "AI Chat" link to the existing navigation bar, alongside the other links.

---

## Phase 5: Testing

### 5.1 Ruby Unit Tests

#### `spec/reactive_view/stream_response_spec.rb`

```ruby
RSpec.describe ReactiveView::StreamResponse do
  describe "#initialize" do
    it "stores the block" do
      block = proc { |out| out << "hello" }
      response = described_class.new(block)
      expect(response.block).to eq(block)
    end
  end
end
```

#### `spec/reactive_view/stream_writer_spec.rb`

```ruby
RSpec.describe ReactiveView::StreamWriter do
  let(:mock_stream) { StringIO.new }
  let(:writer) { described_class.new(mock_stream) }

  describe "#<<" do
    it "writes a text event in SSE format" do
      writer << "hello"
      expect(mock_stream.string).to include('data: {"type":"text","chunk":"hello"}')
    end

    it "returns self for chaining" do
      result = writer << "hello"
      expect(result).to eq(writer)
    end
  end

  describe "#json" do
    it "writes a json event in SSE format" do
      writer.json({ count: 42 })
      expect(mock_stream.string).to include('"type":"json"')
      expect(mock_stream.string).to include('"data":{"count":42}')
    end
  end

  describe "#event" do
    it "writes a custom event" do
      writer.event("progress", percent: 50)
      expect(mock_stream.string).to include('"type":"progress"')
      expect(mock_stream.string).to include('"percent":50')
    end
  end

  describe "#close" do
    it "writes a done event and closes the stream" do
      allow(mock_stream).to receive(:close)
      writer.close
      expect(mock_stream.string).to include('"type":"done"')
      expect(mock_stream).to have_received(:close)
    end

    it "is idempotent" do
      allow(mock_stream).to receive(:close)
      writer.close
      writer.close
      expect(mock_stream).to have_received(:close).once
    end
  end

  describe "writing after close" do
    it "raises an error" do
      allow(mock_stream).to receive(:close)
      writer.close
      expect { writer << "hello" }.to raise_error(RuntimeError, /closed/)
    end
  end
end
```

#### `spec/reactive_view/loader_streaming_spec.rb`

Integration test verifying that `render_stream` in a mutation method produces the expected `StreamResponse`:

```ruby
RSpec.describe "Loader streaming" do
  it "render_stream returns a StreamResponse" do
    loader_class = Class.new(ReactiveView::Loader) do
      def generate
        render_stream do |out|
          out << "hello"
        end
      end
    end

    loader = loader_class.new
    result = loader.generate
    expect(result).to be_a(ReactiveView::StreamResponse)
    expect(result.block).to be_a(Proc)
  end

  it "render_stream raises without a block" do
    loader = ReactiveView::Loader.new
    expect { loader.send(:render_stream) }.to raise_error(ArgumentError)
  end
end
```

### 5.2 TypeScript Generator Tests

**File:** `spec/reactive_view/types/typescript_generator_spec.rb` (extend)

Add tests verifying that:

1. When a loader has mutations, the generated file includes `useStream`
2. The `StreamMutationName` union type lists all mutation names
3. The `createStream` import is present
4. The `StreamForm` component is generated inside `useStream`

### 5.3 Manual Testing Checklist

After implementation, verify in the example app:

- [ ] Navigate to `/ai/chat` and see the greeting from the loader
- [ ] Type a prompt and click Send
- [ ] See text stream in character by character (not all at once)
- [ ] See the streaming indicator while generation is active
- [ ] See token usage metadata after stream completes
- [ ] Submit another prompt while previous is complete
- [ ] Verify CSRF protection (request should include token)
- [ ] Verify the stream can be aborted (navigate away mid-stream)
- [ ] Check browser DevTools Network tab shows `text/event-stream` content type
- [ ] Verify SSE events are properly formatted in the response

---

## File Change Summary

| File | Action | Description |
|------|--------|-------------|
| **Ruby Gem** | | |
| `reactive_view/lib/reactive_view/stream_response.rb` | Create | Value object wrapping the stream block |
| `reactive_view/lib/reactive_view/stream_writer.rb` | Create | SSE writer yielded to `render_stream` blocks |
| `reactive_view/lib/reactive_view/loader.rb` | Modify | Add `render_stream` helper method |
| `reactive_view/lib/reactive_view.rb` | Modify | Require `stream_response` and `stream_writer` |
| `reactive_view/app/controllers/reactive_view/loader_data_controller.rb` | Modify | Add `stream` action, include `ActionController::Live`, update CSRF filters |
| `reactive_view/config/routes.rb` | Modify | Add `loaders/*path/stream` POST route |
| **npm Package** | | |
| `reactive_view/npm/src/stream.ts` | Create | `createStream()`, SSE client, `StreamState`/`StreamChunk` types |
| `reactive_view/npm/src/index.ts` | Modify | Export `createStream`, `StreamState`, `StreamChunk`, `StreamOptions` |
| **TypeScript Generator** | | |
| `reactive_view/lib/reactive_view/types/typescript_generator.rb` | Modify | Add `build_streaming_section`, update `build_imports` and `build_loader_file` |
| **Example App** | | |
| `examples/reactive_view_example/app/pages/ai/chat.loader.rb` | Create | AI chat loader with simulated streaming |
| `examples/reactive_view_example/app/pages/ai/chat.tsx` | Create | AI chat page component |
| `examples/reactive_view_example/app/pages/_components/Navigation.tsx` | Modify | Add AI Chat nav link |
| **Tests** | | |
| `reactive_view/spec/reactive_view/stream_response_spec.rb` | Create | StreamResponse unit tests |
| `reactive_view/spec/reactive_view/stream_writer_spec.rb` | Create | StreamWriter unit tests |
| `reactive_view/spec/reactive_view/loader_streaming_spec.rb` | Create | Integration test for render_stream |
| `reactive_view/spec/reactive_view/types/typescript_generator_spec.rb` | Modify | Extend with streaming generation tests |

**Total: 9 new files, 7 modified files**

---

## Risks & Considerations

### 1. Puma Thread Pool Exhaustion

`ActionController::Live` ties up a Puma thread for the duration of the stream. For an AI response that takes 10 seconds, that's one thread blocked for 10 seconds. With Puma's default of 5 threads, 5 concurrent streams could exhaust the pool.

**Mitigation:** Document thread pool sizing recommendations. For production with heavy streaming, users should increase `threads` in `puma.rb` or use a separate Puma instance for streaming endpoints. This is standard Rails advice for any `ActionController::Live` usage.

### 2. SSR Behavior

During SSR, the SolidStart daemon renders the page on the server. If a component calls `useStream()`, the `createStream` function detects `isServer` and returns inert (no-op) signals. The stream is inherently client-only -- it only activates after hydration when the user interacts with the form.

### 3. CSRF for POST SSE

The stream endpoint is POST-based (mutations are state-changing). CSRF protection uses the same `X-CSRF-Token` header approach that already works for mutations. The `StreamForm` component needs to read the CSRF token from the meta tag and include it in the request -- this is handled by `getCSRFToken()` in `stream.ts`.

### 4. Proxy Buffering

Nginx, CloudFlare, and other reverse proxies may buffer SSE responses. The `X-Accel-Buffering: no` header handles Nginx. Other proxies may need configuration. This should be documented.

### 5. Connection Cleanup

Streams must be properly cleaned up:
- **Client side:** SolidJS `onCleanup` in `createStream()` aborts the fetch on component unmount
- **Server side:** The `ensure` block in the controller's `stream` action closes the writer/stream
- **Network disconnection:** When the client disconnects, writing to `response.stream` raises `IOError`, caught by the `rescue` block

### 6. JSON Parsing in Body

The `stream` action receives POST body as JSON (for programmatic `start()` calls) or as form data (from `StreamForm`). The controller's `build_loader` method uses `params` which Rails automatically parses from either format. The `shapes.generate(params)` call in the loader works the same way it does for regular mutations.

### 7. ActionController::Live + Other Actions

Including `ActionController::Live` in `LoaderDataController` affects all actions in that controller. Specifically, it changes how response buffering works. The existing `show` and `mutate` actions should continue to work correctly because they use `render json:` which is compatible with Live, but this should be tested carefully.

**Alternative:** If `ActionController::Live` causes issues with existing actions, we could extract the `stream` action into a separate `StreamController` that includes `ActionController::Live` independently. This is a clean separation but adds another controller file.

---

## Future Work

### Loader-Based Streaming (Phase 2)

After the mutation streaming MVP, extend to support streamed loader data for progressive page loads:

```ruby
shape :load do
  param :user, Types::Hash.schema(...)              # immediate
  param :ai_summary, Types::Stream[Types::String]   # deferred/streamed
end

def load
  {
    user: { id: 1, name: "Alice" },
    ai_summary: stream { |out| AiService.summarize(user).each { |t| out << t } }
  }
end
```

This requires deeper changes to the loader data pipeline (initial JSON + follow-up SSE for deferred fields), the type system (`Types::Stream` wrapper), and the frontend (`useLoaderData` returning mixed immediate + streamed fields).

### Stream Annotation on Shapes

Add a `stream: true` flag to the shape DSL so the TypeScript generator only produces `useStream()` for mutations that actually support streaming:

```ruby
shape :generate, stream: true do
  param :prompt, Types::String
end
```

### Reconnection / Resume

Implement SSE `Last-Event-ID` support for resumable streams. The server would track event IDs and allow clients to reconnect mid-stream (useful for flaky mobile connections).

### Binary / File Streaming

Extend the protocol to support binary chunks (images, audio) for multimodal AI responses. Would require a different content type or base64 encoding within the SSE envelope.
