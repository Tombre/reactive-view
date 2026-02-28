import { useForm } from "#loaders/users/[id]";

const [UpdateForm, updateSubmission] = useForm("update");

const pendingCheck: boolean | undefined = updateSubmission.pending;
const successCheck: boolean | undefined = updateSubmission.result?.success;
const nameErrorsCheck: string[] | undefined = updateSubmission.result?.errors?.name;

// @ts-expect-error errors are string arrays, not a single string
const invalidNameErrorCheck: string | undefined = updateSubmission.result?.errors?.name;

void UpdateForm;
void pendingCheck;
void successCheck;
void nameErrorsCheck;
void invalidNameErrorCheck;
