import { getRequestEvent } from "solid-js/web";
const RAILS_BASE_URL_HEADER = "x-reactive-view-rails-base-url";
const RAILS_COOKIES_HEADER = "x-reactive-view-cookies";
const RAILS_CSRF_TOKEN_HEADER = "x-reactive-view-csrf-token";
export function getSSRRequestContext() {
    const event = getRequestEvent();
    if (!event)
        return {};
    return {
        railsBaseUrl: event.request.headers.get(RAILS_BASE_URL_HEADER) || undefined,
        cookies: event.request.headers.get(RAILS_COOKIES_HEADER) || undefined,
        csrfToken: event.request.headers.get(RAILS_CSRF_TOKEN_HEADER) || undefined,
    };
}
