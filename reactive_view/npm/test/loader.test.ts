import { afterEach, describe, expect, it, vi } from "vitest";

type LoaderModule = typeof import("../src/loader");

type LoaderTestOptions = {
  isServer: boolean;
  pathname?: string;
  routeParams?: Record<string, string>;
  headers?: Headers;
  modulePath?: "../src/loader" | "../dist/loader.js";
};

async function importLoaderModule(options: LoaderTestOptions) {
  vi.resetModules();

  const resourcePromises: Array<Promise<unknown>> = [];
  const createResourceMock = vi.fn((source: () => unknown, fetcher: (value: unknown) => Promise<unknown>) => {
    const promise = Promise.resolve(fetcher(source()));
    resourcePromises.push(promise);
    return [() => undefined];
  });

  vi.doMock("solid-js", async () => {
    const actual = await vi.importActual<typeof import("solid-js")>("solid-js");
    return {
      ...actual,
      createSignal: vi.fn((initial: number) => [() => initial, vi.fn()]),
      createResource: createResourceMock,
    };
  });

  vi.doMock("solid-js/web", async () => {
    return {
      isServer: options.isServer,
      getRequestEvent: vi.fn(() => {
        if (!options.headers) return undefined;
        return { request: { headers: options.headers } };
      }),
    };
  });

  const queryInnerMock = vi.fn(
    (fn: (params: Record<string, string>) => Promise<unknown>) =>
      vi.fn((params: Record<string, string>) => fn(params))
  );

  vi.doMock("@solidjs/router", () => {
    return {
      query: queryInnerMock,
      createAsync: vi.fn((fn: () => unknown) => fn()),
      useLocation: vi.fn(() => ({ pathname: options.pathname ?? "/" })),
      useParams: vi.fn(() => options.routeParams ?? {}),
    };
  });

  const module = (await import(
    options.modulePath ?? "../src/loader"
  )) as LoaderModule;
  return { module, resourcePromises, queryInnerMock };
}

describe("loader utilities", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    delete (globalThis as Record<string, unknown>).__RAILS_BASE_URL__;
    delete (globalThis as Record<string, unknown>).__REACTIVE_VIEW_COOKIES__;
    delete (globalThis as Record<string, unknown>).window;
    delete process.env.RAILS_BASE_URL;
  });

  it("fetches loader data with SSR base URL and cookies", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ count: 2 }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module, queryInnerMock } = await importLoaderModule({
      isServer: true,
      headers: new Headers({
        "x-reactive-view-rails-base-url": "https://rails.test",
        "x-reactive-view-cookies": "session=abc",
      }),
    });

    const getUsers = module.createLoaderQuery<{ count: number }>("users/index");
    await expect(getUsers({ page: "1", empty: "" })).resolves.toEqual({ count: 2 });

    expect(queryInnerMock).toHaveBeenCalledWith(expect.any(Function), "loader:users/index");
    expect(fetchMock).toHaveBeenCalledWith(
      "https://rails.test/_reactive_view/loaders/users/index/load?page=1",
      expect.objectContaining({
        method: "GET",
        credentials: "include",
        headers: expect.objectContaining({
          Accept: "application/json",
          "Content-Type": "application/json",
          Cookie: "session=abc",
        }),
      })
    );
  });

  it("falls back to process.env.RAILS_BASE_URL on server", async () => {
    process.env.RAILS_BASE_URL = "https://env.test";
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ ok: true }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importLoaderModule({ isServer: true });
    const getData = module.createLoaderQuery<{ ok: boolean }>("index");
    await getData({});

    expect(fetchMock).toHaveBeenCalledWith(
      "https://env.test/_reactive_view/loaders/index/load",
      expect.any(Object)
    );
  });

  it("uses explicit route and params in useLoaderData", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ id: 99 }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };

    const { module, resourcePromises } = await importLoaderModule({ isServer: false });

    module.useLoaderData("users/[id]", { id: "99" });
    await resourcePromises[0];

    expect(fetchMock).toHaveBeenCalledWith(
      "https://client.test/_reactive_view/loaders/users/[id]/load?id=99",
      expect.any(Object)
    );
  });

  it("derives loader path from current route params", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ name: "Sam" }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };

    const { module, resourcePromises } = await importLoaderModule({
      isServer: false,
      pathname: "/users/123",
      routeParams: { id: "123" },
    });

    module.useLoaderData();
    await resourcePromises[0];

    expect(fetchMock).toHaveBeenCalledWith(
      "https://client.test/_reactive_view/loaders/users/[id]/load?id=123",
      expect.any(Object)
    );
  });

  it("appends /index for directory routes", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ users: [] }), {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);
    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://client.test" },
    };

    const { module, resourcePromises } = await importLoaderModule({
      isServer: false,
      pathname: "/users",
      routeParams: {},
    });

    module.useLoaderData();
    await resourcePromises[0];

    expect(fetchMock).toHaveBeenCalledWith(
      "https://client.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
  });

  it("throws a helpful error when loader response is not JSON", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response("<html>oops</html>", {
        headers: { "content-type": "text/html" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importLoaderModule({ isServer: true });
    const getData = module.createLoaderQuery("index");

    await expect(getData({})).rejects.toThrow("Expected JSON response");
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("retries once when loader response is transient HTML", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response("<!DOCTYPE html><html><body>booting</body></html>", {
          status: 503,
          headers: { "content-type": "text/html" },
        })
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          headers: { "content-type": "application/json" },
        })
      );
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importLoaderModule({ isServer: true });
    const getData = module.createLoaderQuery<{ ok: boolean }>("index");

    await expect(getData({})).resolves.toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("falls back to current origin when injected base URL responds with HTML", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response("<!DOCTYPE html><html><body>wrong origin</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        })
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          headers: { "content-type": "application/json" },
        })
      );
    vi.stubGlobal("fetch", fetchMock);

    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://rails.test" },
      __RAILS_BASE_URL__: "https://daemon.test",
    };

    const { module } = await importLoaderModule({ isServer: false });
    const getData = module.createLoaderQuery<{ ok: boolean }>("users/index");

    await expect(getData({})).resolves.toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock).toHaveBeenNthCalledWith(
      1,
      "https://daemon.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      "https://rails.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
  });

  it("falls back to current origin when injected base URL request fails", async () => {
    const fetchMock = vi
      .fn()
      .mockRejectedValueOnce(new TypeError("Failed to fetch"))
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          headers: { "content-type": "application/json" },
        })
      );
    vi.stubGlobal("fetch", fetchMock);

    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://rails.test" },
      __RAILS_BASE_URL__: "https://daemon.test",
    };

    const { module } = await importLoaderModule({ isServer: false });
    const getData = module.createLoaderQuery<{ ok: boolean }>("users/index");

    await expect(getData({})).resolves.toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock).toHaveBeenNthCalledWith(
      1,
      "https://daemon.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      "https://rails.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
  });

  it("keeps dist loader fallback behavior in sync with source", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response("<!DOCTYPE html><html><body>wrong origin</body></html>", {
          status: 200,
          headers: { "content-type": "text/html" },
        })
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          headers: { "content-type": "application/json" },
        })
      );
    vi.stubGlobal("fetch", fetchMock);

    (globalThis as Record<string, unknown>).window = {
      location: { origin: "https://rails.test" },
      __RAILS_BASE_URL__: "https://daemon.test",
    };

    // WHY: Runtime consumers import from package exports, which point at dist.
    // Testing source-only behavior is insufficient because stale dist artifacts
    // can regress client navigation even when src tests pass.
    const { module } = await importLoaderModule({
      isServer: false,
      modulePath: "../dist/loader.js",
    });
    const getData = module.createLoaderQuery<{ ok: boolean }>("users/index");

    await expect(getData({})).resolves.toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock).toHaveBeenNthCalledWith(
      1,
      "https://daemon.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
    expect(fetchMock).toHaveBeenNthCalledWith(
      2,
      "https://rails.test/_reactive_view/loaders/users/index/load",
      expect.any(Object)
    );
  });

  it("throws a helpful error when JSON is invalid", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response("not-json", {
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importLoaderModule({ isServer: true });
    const getData = module.createLoaderQuery("index");

    await expect(getData({})).rejects.toThrow("Invalid JSON response");
  });

  it("uses server error payloads for failed requests", async () => {
    const fetchMock = vi.fn(async () => {
      return new Response(JSON.stringify({ error: "No access" }), {
        status: 403,
        statusText: "Forbidden",
        headers: { "content-type": "application/json" },
      });
    });
    vi.stubGlobal("fetch", fetchMock);

    const { module } = await importLoaderModule({ isServer: true });
    const getData = module.createLoaderQuery("admin/index");

    await expect(getData({})).rejects.toThrow("No access");
  });
});
