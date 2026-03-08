import { describe, expect, it, vi } from "vitest";

describe("core entrypoint exports", () => {
  it("exposes ReactiveView runtime helpers", async () => {
    vi.resetModules();

    vi.doMock("solid-js/web", () => ({
      isServer: false,
      Dynamic: vi.fn(),
      Portal: vi.fn(),
      getRequestEvent: vi.fn(() => undefined),
    }));

    vi.doMock("@solidjs/router", () => ({
      A: vi.fn(),
      Navigate: vi.fn(),
      useNavigate: vi.fn(),
      useLocation: vi.fn(() => ({ pathname: "/" })),
      useParams: vi.fn(() => ({})),
      useSearchParams: vi.fn(),
      useMatch: vi.fn(),
      useIsRouting: vi.fn(),
      useBeforeLeave: vi.fn(),
      createAsync: vi.fn((fn: () => unknown) => fn()),
      query: vi.fn((fn: (params: Record<string, string>) => Promise<unknown>) => fn),
      cache: vi.fn(),
      action: vi.fn((fn: unknown) => fn),
      redirect: vi.fn(),
      useAction: vi.fn(),
      useSubmission: vi.fn(),
      useSubmissions: vi.fn(),
    }));

    const core = await import("../src/index");

    expect(core.useLoaderData).toBeTypeOf("function");
    expect(core.createLoaderQuery).toBeTypeOf("function");
    expect(core.createMutation).toBeTypeOf("function");
    expect(core.createStream).toBeTypeOf("function");
    expect(core.useStreamData).toBeTypeOf("function");
    expect(core.getCSRFToken).toBeTypeOf("function");
    expect(core.getCSRFParam).toBeTypeOf("function");
  });
});
