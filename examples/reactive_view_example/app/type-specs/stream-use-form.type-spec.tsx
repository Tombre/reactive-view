import type { JSX } from "@reactive-view/core";
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
const pendingCheck: boolean | undefined = generateSubmission.pending;
const successCheck: boolean | undefined = generateSubmission.result?.success;

const firstWord: string | undefined = stream.messages()[0]?.word;

// @ts-expect-error word is the only streamed field
const unexpectedRole = stream.messages()[0]?.role;

void formComponentCheck;
void GenerateForm;
void pendingCheck;
void successCheck;
void firstWord;
void unexpectedRole;
