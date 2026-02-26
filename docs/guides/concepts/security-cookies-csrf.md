# Security, Cookies, and CSRF

ReactiveView keeps Rails auth and CSRF protections in place for both SSR and client mutations.

## Auth and cookies

- Loaders run as Rails controllers, so session/cookie auth applies naturally.
- During SSR, Rails forwards cookie headers to SolidStart; SolidStart forwards them back to Rails loader endpoints.

## CSRF on mutations

- `LoaderDataController#mutate` and `#stream` enforce CSRF verification.
- token accepted from:
  - `X-CSRF-Token` header
  - `authenticity_token` param
- generated mutation helpers include CSRF token automatically.

## Read endpoints

`GET /_reactive_view/loaders/*path/load` is read-only and skips forgery protection.

## Practical rules

- Keep `csrf_meta_tags` in your layout.
- Use generated form/actions where possible.
- Use `before_action` guards in loaders for authorization.

See [Internal Endpoints Reference](../../reference/ruby/internal-endpoints.md) and [CSRF API Reference](../../reference/typescript/csrf-api.md).
