# TypeScript: CSRF API

## `getCSRFToken()`

Returns CSRF token string or `null`.

Behavior:

- SSR: reads global `__RAILS_CSRF_TOKEN__`
- client: reads `<meta name="csrf-token">`

## `getCSRFParam()`

Returns param name string (usually `"authenticity_token"`).

Behavior:

- SSR default: `"authenticity_token"`
- client: reads `<meta name="csrf-param">` with same fallback
