import {
  createSignal,
  createEffect,
  Show,
  For,
  Suspense,
} from "@reactive-view/core";
import { useLoaderData, useForm, useStream } from "#loaders/ai/chat";
import "../_styles/tailwind.css";

interface ChatMessage {
  id: number;
  role: "user" | "assistant";
  content: string;
  pending?: boolean;
  failed?: boolean;
}

let nextMessageId = 0;

export default function AiChatPage() {
  const data = useLoaderData();
  const stream = useStream("generate");
  const StreamForm = useForm(stream);
  const [input, setInput] = createSignal("");
  const [history, setHistory] = createSignal<ChatMessage[]>([]);

  createEffect(() => {
    const streamedText = stream
      .messages()
      .map((chunk) => chunk.word)
      .join("");

    setHistory((prev) => {
      const last = prev[prev.length - 1];
      if (!last || last.role != "assistant" || !last.pending) {
        return prev;
      }

      return [...prev.slice(0, -1), { ...last, content: streamedText }];
    });
  });

  createEffect(() => {
    const status = stream.status();
    if (status == "streaming" || status == "idle") return;

    setHistory((prev) => {
      const last = prev[prev.length - 1];
      if (!last || last.role != "assistant" || !last.pending) {
        return prev;
      }

      return [
        ...prev.slice(0, -1),
        {
          ...last,
          pending: false,
          failed: status == "error",
        },
      ];
    });
  });

  const handleSubmit = () => {
    const prompt = input().trim();
    if (!prompt || stream.streaming()) return;

    setHistory((prev) => [
      ...prev,
      {
        id: ++nextMessageId,
        role: "user",
        content: prompt,
      },
      {
        id: ++nextMessageId,
        role: "assistant",
        content: "",
        pending: true,
      },
    ]);

    setInput("");
  };

  const retry = () => {
    if (stream.streaming()) return;

    setHistory((prev) => {
      const last = prev[prev.length - 1];
      if (!last || last.role != "assistant") {
        return prev;
      }

      return [
        ...prev.slice(0, -1),
        {
          ...last,
          content: "",
          pending: true,
          failed: false,
        },
      ];
    });

    stream.retry();
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

      <div class="space-y-4 mb-6 min-h-[200px]">
        <Show
          when={history().length > 0}
          fallback={
            <div class="text-center text-gray-400 py-12">
              <p class="text-lg">No messages yet</p>
              <p class="text-sm mt-1">
                Type a message below to start the conversation
              </p>
            </div>
          }
        >
          <For each={history()}>
            {(msg) => (
              <div
                class={`p-4 rounded-lg ${
                  msg.role == "user"
                    ? "bg-blue-50 border border-blue-100 ml-8"
                    : "bg-gray-50 border border-gray-100 mr-8"
                }`}
              >
                <div class="flex items-center gap-2 mb-1">
                  <span
                    class={`text-xs font-semibold uppercase tracking-wide ${
                      msg.role == "user" ? "text-blue-600" : "text-gray-600"
                    }`}
                  >
                    {msg.role == "user" ? "You" : "AI"}
                  </span>

                  <Show when={msg.pending}>
                    <span class="text-xs text-green-500 animate-pulse">
                      streaming...
                    </span>
                  </Show>

                  <Show when={msg.failed}>
                    <span class="text-xs text-red-500">failed</span>
                  </Show>
                </div>

                <p class="text-gray-800 whitespace-pre-wrap">
                  {msg.content}
                  <Show when={msg.pending}>
                    <span class="inline-block w-2 h-4 bg-gray-400 animate-pulse ml-0.5" />
                  </Show>
                </p>
              </div>
            )}
          </For>
        </Show>

        <Show when={stream.error()}>
          <div class="p-4 rounded-lg bg-red-50 border border-red-200">
            <p class="text-red-700 text-sm">Error: {stream.error()?.message}</p>
            <button
              type="button"
              class="mt-2 text-sm text-red-700 underline hover:text-red-800"
              onClick={retry}
              disabled={stream.streaming()}
            >
              Retry
            </button>
          </div>
        </Show>
      </div>

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
