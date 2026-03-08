import { A, Show, createSignal } from "@reactive-view/core";
import { createMutation, useAction } from "@reactive-view/core";
import { useLoaderData } from "#loaders/(admin)/(auth)/register";
import "../../_styles/tailwind.css";

type BeginRegisterInput = {
  name: string;
  email: string;
};

type BeginRegisterResult = {
  success: boolean;
  errors?: Record<string, string[]>;
  public_key?: PublicKeyCredentialCreationOptionsJSON;
  challenge?: string;
  challenge_hmac?: string;
};

type FinishRegisterInput = {
  credential_json: unknown;
  challenge: string;
  challenge_hmac: string;
};

type FinishRegisterResult = {
  success: boolean;
  errors?: Record<string, string[]>;
};

const beginRegisterAction = createMutation<BeginRegisterResult, BeginRegisterInput>(
  "(admin)/(auth)/register",
  "begin_register"
);

const finishRegisterAction = createMutation<FinishRegisterResult, FinishRegisterInput>(
  "(admin)/(auth)/register",
  "finish_register"
);

function formatErrors(errors?: Record<string, string[]>): string | null {
  if (!errors) return null;

  const messages = Object.values(errors).flat();
  return messages.length > 0 ? messages.join(" ") : null;
}

export default function AdminAuthRegister() {
  const data = useLoaderData();
  const beginRegister = useAction(beginRegisterAction);
  const finishRegister = useAction(finishRegisterAction);

  const [name, setName] = createSignal("");
  const [email, setEmail] = createSignal("");
  const [pending, setPending] = createSignal(false);
  const [error, setError] = createSignal<string | null>(null);

  const supportsPasskeys = () => {
    if (data()?.supports_passkeys === false) return false;
    if (typeof window === "undefined") return true;

    return Boolean(
      window.PublicKeyCredential &&
        "parseCreationOptionsFromJSON" in window.PublicKeyCredential &&
        typeof navigator.credentials?.create === "function"
    );
  };

  const handleCreateAccount = async (event: SubmitEvent) => {
    event.preventDefault();
    setError(null);

    const normalizedName = name().trim();
    const normalizedEmail = email().trim().toLowerCase();

    if (!normalizedName || !normalizedEmail) {
      setError("Name and email are required");
      return;
    }

    if (!supportsPasskeys()) {
      setError("This browser does not support passkeys");
      return;
    }

    setPending(true);

    try {
      const beginResult = await beginRegister({
        name: normalizedName,
        email: normalizedEmail,
      });
      const beginPayload = beginResult as BeginRegisterResult;

      if (!beginPayload.success || !beginPayload.public_key || !beginPayload.challenge || !beginPayload.challenge_hmac) {
        setError(formatErrors(beginPayload.errors) || "Could not start account creation");
        return;
      }

      const createOptions = PublicKeyCredential.parseCreationOptionsFromJSON(beginPayload.public_key);
      const credential = await navigator.credentials.create({ publicKey: createOptions });
      if (!(credential instanceof PublicKeyCredential)) {
        setError("Passkey registration was cancelled");
        return;
      }

      const finishResult = await finishRegister({
        credential_json: credential.toJSON(),
        challenge: beginPayload.challenge,
        challenge_hmac: beginPayload.challenge_hmac,
      });
      const finishPayload = finishResult as FinishRegisterResult;

      if (!finishPayload.success) {
        setError(formatErrors(finishPayload.errors) || "Could not finish account creation");
      }
    } catch (caught) {
      if (caught instanceof DOMException && caught.name === "NotAllowedError") {
        setError("Passkey registration was cancelled");
        return;
      }

      const message = caught instanceof Error ? caught.message : "Could not create account";
      setError(message);
    } finally {
      setPending(false);
    }
  };

  return (
    <div class="min-h-screen bg-gray-50 flex items-center justify-center px-4 py-10">
      <div class="w-full max-w-md">
        <div class="mb-8 text-center">
          <h1 class="text-3xl font-semibold text-gray-900">Create account</h1>
          <p class="mt-2 text-sm text-gray-600">Register with your email and create your first passkey.</p>
        </div>

        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <form onSubmit={handleCreateAccount} class="space-y-4">
            <div>
              <label for="name" class="block mb-2 font-medium text-gray-700 text-sm">
                Full name
              </label>
              <input
                id="name"
                type="text"
                value={name()}
                onInput={(event) => setName(event.currentTarget.value)}
                placeholder="Alex Johnson"
                autocomplete="name"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label for="email" class="block mb-2 font-medium text-gray-700 text-sm">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email()}
                onInput={(event) => setEmail(event.currentTarget.value)}
                placeholder="you@example.com"
                autocomplete="email"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <Show when={error()}>
              <div class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-md px-3 py-2">
                {error()}
              </div>
            </Show>

            <Show when={supportsPasskeys()} fallback={<p class="text-sm text-amber-700">Passkeys are not available in this environment.</p>}>
              <button
                type="submit"
                disabled={pending()}
                class="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-60"
              >
                <Show when={pending()} fallback="Create account with passkey">
                  Waiting for passkey...
                </Show>
              </button>
            </Show>
          </form>

          <p class="mt-5 text-sm text-center text-gray-600">
            Already have an account?{" "}
            <A href="/login" class="text-blue-700 hover:text-blue-800 font-medium">
              Sign in
            </A>
          </p>
        </div>
      </div>
    </div>
  );
}
