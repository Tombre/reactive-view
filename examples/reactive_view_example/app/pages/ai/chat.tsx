import {
  createSignal,
  Show,
  For,
  Suspense,
  useStreamData,
} from "@reactive-view/core";
import type { StreamDataMessage } from "@reactive-view/core";
import { useLoaderData, useForm, useStream } from "#loaders/ai/chat";

type StreamParams = { prompt: string };
type StreamUsage = {
  prompt_tokens: number;
  completion_tokens: number;
  model: string;
};
type StreamJsonEvent = { usage?: StreamUsage };

interface Message {
  id: number;
  role: "user" | "assistant";
  content: string;
  status: "streaming" | "done" | "error";
  events: StreamJsonEvent[];
  error?: string;
  metadata?: {
    usage?: StreamUsage;
  };
}

export default function AiChatPage() {
  const data = useLoaderData();
  const stream = useStream("generate");
  const StreamForm = useForm(stream);
  const [input, setInput] = createSignal("");
  const streamData = useStreamData<StreamParams, StreamJsonEvent, Message["metadata"]>(stream, {
    getUserContent: (params: StreamParams) => params.prompt,
    parseJsonChunk: (chunk: { data?: unknown }) => chunk.data as StreamJsonEvent,
    extractMeta: (events: StreamJsonEvent[]) => ({ usage: events[0]?.usage }),
  });

  const messages = () =>
    streamData.messages().map((message: StreamDataMessage<StreamJsonEvent, Message["metadata"]>): Message => ({
      ...message,
      metadata: message.meta,
    }));

  const handleSubmit = () => {
    const prompt = input().trim();
    if (!prompt || stream.streaming()) return;
    setInput("");
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
                  <Show when={msg.status === "streaming"}>
                    <span class="text-xs text-green-500 animate-pulse">
                      streaming...
                    </span>
                  </Show>
                  <Show when={msg.status === "error"}>
                    <span class="text-xs text-red-500">failed</span>
                  </Show>
                </div>
                <p class="text-gray-800 whitespace-pre-wrap">
                  {msg.content}
                  <Show when={msg.status === "streaming"}>
                    <span class="inline-block w-2 h-4 bg-gray-400 animate-pulse ml-0.5" />
                  </Show>
                </p>
                <Show when={msg.status === "error" && msg.role === "assistant"}>
                  <div class="mt-2">
                    <button
                      type="button"
                      class="text-xs text-red-600 hover:text-red-700 underline"
                      onClick={() => streamData.retry()}
                      disabled={stream.streaming()}
                    >
                      Retry
                    </button>
                  </div>
                </Show>
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
        <Show when={streamData.error()}>
          <div class="p-4 rounded-lg bg-red-50 border border-red-200">
            <p class="text-red-700 text-sm">
              Error: {streamData.error()?.message}
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
