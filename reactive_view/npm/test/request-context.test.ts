import { beforeEach, describe, expect, it, vi } from "vitest";

const getRequestEventMock = vi.fn();

vi.mock("solid-js/web", async () => {
  const actual = await vi.importActual<typeof import("solid-js/web")>("solid-js/web");
  return {
    ...actual,
    getRequestEvent: getRequestEventMock,
  };
});

describe("getSSRRequestContext", () => {
  beforeEach(() => {
    vi.resetModules();
    getRequestEventMock.mockReset();
  });

  it("returns an empty object when no request event exists", async () => {
    getRequestEventMock.mockReturnValue(undefined);
    const { getSSRRequestContext } = await import("../src/request-context");

    expect(getSSRRequestContext()).toEqual({});
  });

  it("reads ReactiveView headers from the request event", async () => {
    getRequestEventMock.mockReturnValue({
      request: {
        headers: new Headers({
          "x-reactive-view-rails-base-url": "https://rails.test",
          "x-reactive-view-cookies": "session=abc",
          "x-reactive-view-csrf-token": "csrf-123",
        }),
      },
    });

    const { getSSRRequestContext } = await import("../src/request-context");

    expect(getSSRRequestContext()).toEqual({
      railsBaseUrl: "https://rails.test",
      cookies: "session=abc",
      csrfToken: "csrf-123",
    });
  });

  it("maps missing headers to undefined", async () => {
    getRequestEventMock.mockReturnValue({
      request: {
        headers: new Headers(),
      },
    });

    const { getSSRRequestContext } = await import("../src/request-context");

    expect(getSSRRequestContext()).toEqual({
      railsBaseUrl: undefined,
      cookies: undefined,
      csrfToken: undefined,
    });
  });
});
