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
const pendingCheck: boolean = generateSubmission.pending;
const successCheck: boolean | undefined = generateSubmission.result?.success;

void formComponentCheck;
void GenerateForm;
void pendingCheck;
void successCheck;
