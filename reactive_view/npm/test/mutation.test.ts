import { afterEach, describe, expect, it, vi } from "vitest";

type MutationTestOptions = {
  isServer: boolean;
  headers?: Headers;
};

async function importMutationModule(options: MutationTestOptions) {
  vi.resetModules();

  const redirectMock = vi.fn((to: string, config: Record<string, unknown>) => ({
    __kind: "redirect",
    to,
    config,
  }));
  const actionMock = vi.fn(
    (fn: (arg: unknown) => Promise<unknown>, key: string) =>
      Object.assign(fn, { __key: key })
  );

  vi.doMock("solid-js/web", async () => {
    return {
      isServer: options.isServer,
      getRequestEvent: vi.fn(() => {
        if (!options.headers) return undefined;
        return { request: { headers: options.headers } };
      }),
    };
  });

  vi.doMock("@solidjs/router", () => {
    return {
      action: actionMock,
      redirect: redirectMock,
      useAction: vi.fn(),
      useSubmission: vi.fn(),
      useSubmissions: vi.fn(),
    };
  });

  const module = await import("../src/mutation");
  return { module, actionMock, redirectMock };
}

describe("mutation utilities", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    delete (globalThis as Record<string, unknown>).__RAILS_CSRF_TOKEN__;
    delete (globalThis as Record<string, unknown>).window;
    delete (globalThis as Record<string, unknown>).document;
  });

  it("creates form-data mutation actions with expected request metadata", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ success: true, id: 7 }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module, actionMock } = await importMutationModule({
      isServer: true,
      headers: new Headers({
        "x-reactive-view-rails-base-url": "https://rails.test",
        "x-reactive-view-cookies": "session=xyz",
        "x-reactive-view-csrf-token": "csrf-from-header",
      }),
    });

    const mutation = module.createMutation("users/[id]", "update") as unknown as ((formData: FormData) => Promise<unknown>) & {
      __key: string;
    };

    const formData = new FormData();
    formData.set("name", "Alice");

    await expect(mutation(formData)).resolves.toEqual({ success: true, id: 7 });
    expect(mutation.__key).toBe("users/[id]:update");
    expect(actionMock).toHaveBeenCalled();
    expect(fetchMock).toHaveBeenCalledWith(
      "https://rails.test/_reactive_view/loaders/users/[id]/mutate?_mutation=update",
      expect.objectContaining({
        method: "POST",
        body: formData,
        credentials: "include",
        headers: expect.objectContaining({
          Accept: "application/json",
          "X-Reactive-View-Client": "true",
          "X-CSRF-Token": "csrf-from-header",
          Cookie: "session=xyz",
        }),
      })
    );
  });

  it("throws router redirects when _redirect is returned", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(
        JSON.stringify({ success: true, _redirect: "/users", _revalidate: ["users/index"] }),
        {
          headers: { "content-type": "application/json" },
        }
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module, redirectMock } = await importMutationModule({ isServer: true });
    const mutation = module.createMutation("users/index") as (formData: FormData) => Promise<unknown>;

    await expect(mutation(new FormData())).rejects.toEqual({
      __kind: "redirect",
      to: "/users",
      config: { revalidate: ["users/index"] },
    });

    expect(redirectMock).toHaveBeenCalledWith("/users", {
      revalidate: ["users/index"],
    });
  });

  it("throws a fallback mutation error when response body is not JSON", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response("broken", {
        status: 500,
        statusText: "Internal Server Error",
        headers: { "content-type": "text/plain" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importMutationModule({ isServer: true });
    const mutation = module.createMutation("users/index") as (formData: FormData) => Promise<unknown>;

    await expect(mutation(new FormData())).rejects.toThrow(
      "Mutation failed: 500 Internal Server Error"
    );
  });

  it("throws payload error message for non-ok responses without field errors", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ success: false, error: "Nope" }), {
        status: 422,
        statusText: "Unprocessable Entity",
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importMutationModule({ isServer: true });
    const mutation = module.createMutation("users/index") as (formData: FormData) => Promise<unknown>;

    await expect(mutation(new FormData())).rejects.toThrow("Nope");
  });

  it("returns validation errors for non-ok responses with errors payload", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(
        JSON.stringify({ success: false, errors: { name: ["is required"] } }),
        {
          status: 422,
          statusText: "Unprocessable Entity",
          headers: { "content-type": "application/json" },
        }
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importMutationModule({ isServer: true });
    const mutation = module.createMutation("users/index") as (formData: FormData) => Promise<unknown>;

    await expect(mutation(new FormData())).resolves.toEqual({
      success: false,
      errors: { name: ["is required"] },
    });
  });

  it("creates JSON mutations with createMutation and client-side CSRF token", async () => {
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    (globalThis as Record<string, unknown>).document = {
      querySelector: vi.fn((selector: string) => {
        if (selector === 'meta[name="csrf-token"]') {
          return { getAttribute: vi.fn(() => "meta-csrf") };
        }
        return null;
      }),
    };

    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ success: true }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importMutationModule({ isServer: false });
    const mutation = module.createMutation<{ success: boolean }, { name: string }>(
      "users/index"
    ) as unknown as ((input: { name: string }) => Promise<unknown>) & {
      __key: string;
    };

    await expect(mutation({ name: "New name" })).resolves.toEqual({ success: true });
    expect(mutation.__key).toBe("users/index:mutate");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://client.test/_reactive_view/loaders/users/index/mutate?_mutation=mutate",
      expect.objectContaining({
        method: "POST",
        credentials: "include",
        body: JSON.stringify({ name: "New name" }),
        headers: expect.objectContaining({
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-Reactive-View-Client": "true",
          "X-CSRF-Token": "meta-csrf",
        }),
      })
    );
  });

  it("creates JSON mutations with JSON payload and client-side CSRF token", async () => {
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };
    (globalThis as Record<string, unknown>).document = {
      querySelector: vi.fn((selector: string) => {
        if (selector === 'meta[name="csrf-token"]') {
          return { getAttribute: vi.fn(() => "meta-csrf") };
        }
        return null;
      }),
    };

    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ success: true }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importMutationModule({ isServer: false });
    const mutation = module.createJsonMutation<{ name: string }>("users/index") as unknown as ((input: {
      name: string;
    }) => Promise<unknown>) & { __key: string };

    await expect(mutation({ name: "New name" })).resolves.toEqual({ success: true });
    expect(mutation.__key).toBe("users/index:mutate:json");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://client.test/_reactive_view/loaders/users/index/mutate?_mutation=mutate",
      expect.objectContaining({
        method: "POST",
        credentials: "include",
        body: JSON.stringify({ name: "New name" }),
        headers: expect.objectContaining({
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-Reactive-View-Client": "true",
          "X-CSRF-Token": "meta-csrf",
        }),
      })
    );
  });
});
