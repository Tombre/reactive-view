import { createRoot } from "solid-js";
import { afterEach, describe, expect, it, vi } from "vitest";

type StreamTestOptions = {
  isServer: boolean;
  headers?: Headers;
};

async function importStreamModule(options: StreamTestOptions) {
  vi.resetModules();

  vi.doMock("solid-js/web", async () => {
    const actual = await vi.importActual<typeof import("solid-js/web")>("solid-js/web");
    return {
      ...actual,
      isServer: options.isServer,
      getRequestEvent: vi.fn(() => {
        if (!options.headers) return undefined;
        return { request: { headers: options.headers } };
      }),
    };
  });

  return import("../src/stream");
}

function createSSEStream(chunks: string[], close = true): ReadableStream<Uint8Array> {
  const encoder = new TextEncoder();
  return new ReadableStream<Uint8Array>({
    start(controller) {
      for (const chunk of chunks) {
        controller.enqueue(encoder.encode(chunk));
      }
      if (close) controller.close();
    },
  });
}

function createRootValue<T>(factory: () => T): { value: T; dispose: () => void } {
  let dispose!: () => void;
  let value!: T;

  createRoot((cleanup) => {
    dispose = cleanup;
    value = factory();
  });

  return { value, dispose };
}

describe("stream utilities", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    delete (globalThis as Record<string, unknown>).window;
    delete (globalThis as Record<string, unknown>).document;
  });

  it("returns inert stream state on server", async () => {
    const module = await importStreamModule({ isServer: true });
    const stream = module.createStream("ai/chat", "generate");

    expect(stream.status()).toBe("idle");
    expect(stream.streaming()).toBe(false);
    expect(stream.data()).toBe("");
    await expect(stream.end()).rejects.toThrow("Cannot await stream completion on the server");
  });

  it("streams text chunks and resolves on done", async () => {
    const module = await importStreamModule({ isServer: false });
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    (globalThis as Record<string, unknown>).document = {
      querySelector: vi.fn(() => ({ getAttribute: vi.fn(() => "token-1") })),
    };

    const fetchMock = vi.fn(async () => {
      return new Response(
        createSSEStream([
          'data: {"type":"text","chunk":"Hello"}\n\n',
          'data: {"type":"json","data":{"kind":"meta"}}\n\n',
          'data: {"type":"done"}\n\n',
        ]),
        {
          headers: { "content-type": "text/event-stream" },
        }
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const { value: stream, dispose } = createRootValue(() =>
      module.createStream<{ prompt: string }>("ai/chat", "generate")
    );

    try {
      stream.start({ prompt: "Hi" });
      await expect(stream.end()).resolves.toBeUndefined();

      expect(stream.status()).toBe("done");
      expect(stream.streaming()).toBe(false);
      expect(stream.data()).toBe("Hello");
      expect(stream.chunks()).toEqual([
        { type: "text", chunk: "Hello" },
        { type: "json", data: { kind: "meta" } },
      ]);
      expect(fetchMock).toHaveBeenCalledWith(
        "https://client.test/_reactive_view/loaders/ai/chat/stream?_mutation=generate",
        expect.objectContaining({
          method: "POST",
          credentials: "include",
          body: JSON.stringify({ prompt: "Hi" }),
          headers: expect.objectContaining({
            Accept: "text/event-stream",
            "Content-Type": "application/json",
            "X-CSRF-Token": "token-1",
          }),
        })
      );
    } finally {
      dispose();
    }
  });

  it("propagates stream error events", async () => {
    const module = await importStreamModule({ isServer: false });
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        return new Response(createSSEStream(['data: {"type":"error","message":"boom"}\n\n']), {
          headers: { "content-type": "text/event-stream" },
        });
      })
    );

    const { value: stream, dispose } = createRootValue(() => module.createStream("ai/chat", "generate"));

    try {
      stream.start({});
      await expect(stream.end()).rejects.toThrow("boom");
      expect(stream.status()).toBe("error");
      expect(stream.error()?.message).toBe("boom");
    } finally {
      dispose();
    }
  });

  it("raises StreamIncompleteError when stream closes before done", async () => {
    const module = await importStreamModule({ isServer: false });
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => {
        return new Response(createSSEStream(['data: {"type":"text","chunk":"partial"}\n\n']), {
          headers: { "content-type": "text/event-stream" },
        });
      })
    );

    const { value: stream, dispose } = createRootValue(() => module.createStream("ai/chat", "generate"));

    try {
      stream.start({});
      await expect(stream.end()).rejects.toBeInstanceOf(module.StreamIncompleteError);
      expect(stream.status()).toBe("error");
    } finally {
      dispose();
    }
  });

  it("aborts in-flight streams and rejects end", async () => {
    const module = await importStreamModule({ isServer: false });
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    vi.stubGlobal(
      "fetch",
      vi.fn(
        async () =>
          await new Promise<Response>(() => {
            // Keep pending to simulate in-flight request
          })
      )
    );

    const { value: stream, dispose } = createRootValue(() => module.createStream("ai/chat", "generate"));

    try {
      stream.start({ prompt: "abort" });
      const pending = stream.end();
      stream.abort();

      await expect(pending).rejects.toThrow("Stream aborted");
      expect(stream.status()).toBe("aborted");
      expect(stream.streaming()).toBe(false);
    } finally {
      dispose();
    }
  });

  it("retries with last params when retry is called without args", async () => {
    const module = await importStreamModule({ isServer: false });
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    const fetchMock = vi.fn(async () => {
      return new Response(createSSEStream(['data: {"type":"done"}\n\n']), {
        headers: { "content-type": "text/event-stream" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { value: stream, dispose } = createRootValue(() => module.createStream("ai/chat", "generate"));

    try {
      stream.start({ prompt: "again" });
      await stream.end();

      stream.retry();
      await stream.end();

      expect(fetchMock).toHaveBeenCalledTimes(2);
      expect(fetchMock).toHaveBeenNthCalledWith(
        1,
        expect.any(String),
        expect.objectContaining({ body: JSON.stringify({ prompt: "again" }) })
      );
      expect(fetchMock).toHaveBeenNthCalledWith(
        2,
        expect.any(String),
        expect.objectContaining({ body: JSON.stringify({ prompt: "again" }) })
      );
    } finally {
      dispose();
    }
  });

  it("extracts message arrays via useStreamData", async () => {
    vi.resetModules();
    vi.doMock("solid-js", () => {
      return {
        createSignal<T>(initial: T) {
          let value = initial;
          return [
            () => value,
            (next: T | ((prev: T) => T)) => {
              value = typeof next === "function" ? (next as (prev: T) => T)(value) : next;
            },
          ] as const;
        },
        createEffect: (fn: () => void) => fn(),
        onCleanup: vi.fn(),
        batch: <T>(fn: () => T) => fn(),
      };
    });
    vi.doMock("solid-js/web", () => ({
      isServer: false,
      getRequestEvent: vi.fn(() => undefined),
    }));

    const module = await import("../src/stream");

    const fakeStream = {
      data: () => "",
      streaming: () => false,
      error: () => null,
      status: () => "idle" as const,
      chunks: () => [
        { type: "text", chunk: "hello" },
        { type: "json", data: { id: 1 } },
        { type: "custom" },
      ],
      lastParams: () => null,
      start: () => {},
      retry: () => {},
      end: async () => {},
      abort: () => {},
    };

    const streamData = module.useStreamData(fakeStream);
    expect(streamData.messages()).toEqual(["hello", { id: 1 }]);

    streamData.reset();
    expect(streamData.messages()).toEqual([]);
  });
});
