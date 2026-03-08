import { A, Show, createSignal } from "@reactive-view/core";
import { createMutation, useAction } from "@reactive-view/core";
import { useLoaderData } from "#loaders/(admin)/(auth)/login";
import "../../_styles/tailwind.css";

type BeginSignInInput = {
  email: string;
};

type BeginSignInResult = {
  success: boolean;
  errors?: Record<string, string[]>;
  public_key?: PublicKeyCredentialRequestOptionsJSON;
  challenge?: string;
  challenge_hmac?: string;
};

type FinishSignInInput = {
  email: string;
  credential_json: unknown;
  challenge: string;
  challenge_hmac: string;
};

type FinishSignInResult = {
  success: boolean;
  errors?: Record<string, string[]>;
};

const beginSignInAction = createMutation<BeginSignInResult, BeginSignInInput>(
  "(admin)/(auth)/login",
  "begin_sign_in"
);

const finishSignInAction = createMutation<FinishSignInResult, FinishSignInInput>(
  "(admin)/(auth)/login",
  "finish_sign_in"
);

function formatErrors(errors?: Record<string, string[]>): string | null {
  if (!errors) return null;

  const messages = Object.values(errors).flat();
  return messages.length > 0 ? messages.join(" ") : null;
}

export default function AdminAuthLogin() {
  const data = useLoaderData();
  const beginSignIn = useAction(beginSignInAction);
  const finishSignIn = useAction(finishSignInAction);

  const [email, setEmail] = createSignal("");
  const [pending, setPending] = createSignal(false);
  const [error, setError] = createSignal<string | null>(null);

  const supportsPasskeys = () => {
    if (data()?.supports_passkeys === false) return false;
    if (typeof window === "undefined") return true;

    return Boolean(
      window.PublicKeyCredential &&
        "parseRequestOptionsFromJSON" in window.PublicKeyCredential &&
        typeof navigator.credentials?.get === "function"
    );
  };

  const handleSignIn = async (event: SubmitEvent) => {
    event.preventDefault();
    setError(null);

    const normalizedEmail = email().trim().toLowerCase();
    if (!normalizedEmail) {
      setError("Email is required");
      return;
    }

    if (!supportsPasskeys()) {
      setError("This browser does not support passkeys");
      return;
    }

    setPending(true);

    try {
      const beginResult = await beginSignIn({ email: normalizedEmail });
      const beginPayload = beginResult as BeginSignInResult;

      if (!beginPayload.success || !beginPayload.public_key || !beginPayload.challenge || !beginPayload.challenge_hmac) {
        setError(formatErrors(beginPayload.errors) || "Could not start sign-in");
        return;
      }

      const requestOptions = PublicKeyCredential.parseRequestOptionsFromJSON(beginPayload.public_key);
      const credential = await navigator.credentials.get({ publicKey: requestOptions });
      if (!(credential instanceof PublicKeyCredential)) {
        setError("Passkey sign-in was cancelled");
        return;
      }

      const credentialJson = credential.toJSON();

      const finishResult = await finishSignIn({
        email: normalizedEmail,
        credential_json: credentialJson,
        challenge: beginPayload.challenge,
        challenge_hmac: beginPayload.challenge_hmac,
      });

      const finishPayload = finishResult as FinishSignInResult;

      if (!finishPayload.success) {
        setError(formatErrors(finishPayload.errors) || "Sign-in failed");
      }
    } catch (caught) {
      if (caught instanceof DOMException && caught.name === "NotAllowedError") {
        setError("Passkey sign-in was cancelled");
        return;
      }

      const message = caught instanceof Error ? caught.message : "Sign-in failed";
      setError(message);
    } finally {
      setPending(false);
    }
  };

  return (
    <div class="min-h-screen bg-gray-50 flex items-center justify-center px-4 py-10">
      <div class="w-full max-w-md">
        <div class="mb-8 text-center">
          <h1 class="text-3xl font-semibold text-gray-900">Sign in with passkey</h1>
          <p class="mt-2 text-sm text-gray-600">
            Enter your email, then confirm with your passkey.
          </p>
        </div>

        <div class="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <form onSubmit={handleSignIn} class="space-y-4">
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
                autocomplete="email webauthn"
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
                <Show when={pending()} fallback="Continue with passkey">
                  Waiting for passkey...
                </Show>
              </button>
            </Show>
          </form>

          <p class="mt-5 text-sm text-center text-gray-600">
            New here?{" "}
            <A href="/register" class="text-blue-700 hover:text-blue-800 font-medium">
              Create an account
            </A>
          </p>
        </div>
      </div>
    </div>
  );
}
