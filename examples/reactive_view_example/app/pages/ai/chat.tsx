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
