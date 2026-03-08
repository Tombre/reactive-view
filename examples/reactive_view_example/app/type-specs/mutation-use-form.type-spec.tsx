import type { JSX } from "@reactive-view/core";
import { UpdateForm, updateAction, useAction, useForm } from "#loaders/users/[id]";

const [UpdateMutationForm, updateSubmission] = useForm("update");
const update = useAction(updateAction);

void update({ id: 1, name: "Alice", email: "alice@example.com" });

const updateFormComponentCheck: (
  props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">
) => JSX.Element = UpdateForm;

const pendingCheck: boolean | undefined = updateSubmission.pending;
const successCheck: boolean | undefined = updateSubmission.result?.success;
const nameErrorsCheck: string[] | undefined = updateSubmission.result?.errors?.name;

// @ts-expect-error errors are string arrays, not a single string
const invalidNameErrorCheck: string | undefined = updateSubmission.result?.errors?.name;

void UpdateMutationForm;
void update;
void pendingCheck;
void successCheck;
void nameErrorsCheck;
void invalidNameErrorCheck;
void updateFormComponentCheck;
