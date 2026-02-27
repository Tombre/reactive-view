import type { JSX } from "@reactive-view/core";
import { useStreamData } from "@reactive-view/core";
import { useForm, useStream } from "#loaders/ai/chat";

const stream = useStream("generate");

stream.start({ prompt: "hello" });

// @ts-expect-error prompt is required
stream.start({});

// @ts-expect-error prompt must be a string
stream.start({ prompt: 123 });

const StreamForm = useForm(stream);
const formComponentCheck: (
  props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">
) => JSX.Element = StreamForm;

// @ts-expect-error useForm(stream) returns a Form component, not a tuple
const [BadForm] = useForm(stream);

const [GenerateForm, generateSubmission] = useForm("generate");
const pendingCheck: boolean = generateSubmission.pending;
const successCheck: boolean | undefined = generateSubmission.result?.success;

const streamData = useStreamData<
  { prompt: string },
  { usage?: { prompt_tokens: number } },
  { usage?: { prompt_tokens: number } }
>(stream, {
  getUserContent: (params: { prompt: string }) => params.prompt,
  parseJsonChunk: (chunk: { data?: unknown }) =>
    chunk.data as { usage?: { prompt_tokens: number } },
  extractMeta: (events: Array<{ usage?: { prompt_tokens: number } }>) => ({
    usage: events[0]?.usage,
  }),
});

streamData.send({ prompt: "typed" });

// @ts-expect-error prompt is required for send
streamData.send({});

const firstMessageStatus:
  | "streaming"
  | "done"
  | "error"
  | undefined = streamData.messages()[0]?.status;

void formComponentCheck;
void GenerateForm;
void pendingCheck;
void successCheck;
void firstMessageStatus;
