import { afterEach, describe, expect, it, vi } from "vitest";

async function importCsrfModule(options: {
  isServer: boolean;
  headers?: Headers;
}) {
  vi.resetModules();

  vi.doMock("solid-js/web", async () => {
    const actual = await vi.importActual<typeof import("solid-js/web")>("solid-js/web");
    return {
      ...actual,
      isServer: options.isServer,
      getRequestEvent: vi.fn(() => {
        if (!options.headers) return undefined;
        return { request: { headers: options.headers } };
      }),
    };
  });

  return import("../src/csrf");
}

describe("csrf utilities", () => {
  afterEach(() => {
    delete (globalThis as Record<string, unknown>).__RAILS_CSRF_TOKEN__;
    delete (globalThis as Record<string, unknown>).document;
    vi.restoreAllMocks();
  });

  it("reads CSRF token from SSR request context", async () => {
    const { getCSRFToken } = await importCsrfModule({
      isServer: true,
      headers: new Headers({ "x-reactive-view-csrf-token": "ctx-token" }),
    });

    expect(getCSRFToken()).toBe("ctx-token");
  });

  it("falls back to global SSR token", async () => {
    (globalThis as Record<string, unknown>).__RAILS_CSRF_TOKEN__ = "global-token";

    const { getCSRFToken } = await importCsrfModule({ isServer: true });

    expect(getCSRFToken()).toBe("global-token");
  });

  it("reads CSRF token from meta tag on the client", async () => {
    (globalThis as Record<string, unknown>).document = {
      querySelector: vi.fn(() => ({ getAttribute: vi.fn(() => "meta-token") })),
    };

    const { getCSRFToken } = await importCsrfModule({ isServer: false });

    expect(getCSRFToken()).toBe("meta-token");
  });

  it("returns null when client token is unavailable", async () => {
    (globalThis as Record<string, unknown>).document = {
      querySelector: vi.fn(() => null),
    };

    const { getCSRFToken } = await importCsrfModule({ isServer: false });

    expect(getCSRFToken()).toBeNull();
  });

  it("returns default csrf param on server", async () => {
    const { getCSRFParam } = await importCsrfModule({ isServer: true });

    expect(getCSRFParam()).toBe("authenticity_token");
  });

  it("reads csrf param from meta tag on client", async () => {
    (globalThis as Record<string, unknown>).document = {
      querySelector: vi.fn(() => ({ getAttribute: vi.fn(() => "custom_param") })),
    };

    const { getCSRFParam } = await importCsrfModule({ isServer: false });

    expect(getCSRFParam()).toBe("custom_param");
  });
});
