# Security headers

A nonce-based Content Security Policy is active in every environment, in `config/initializers/content_security_policy.rb`. Default, base URI, form action and frame ancestors are all restricted to the app's own origin, which also makes it clickjacking-safe; objects are forbidden; fonts allow data URIs; images allow data and blob URIs and any HTTPS source, which is permissive on purpose for user and blog content; connections are restricted to the same origin, which covers the Action Cable WebSocket behind Turbo Streams.

**Scripts are strict and styles are not.** Scripts are the real XSS vector, so `script-src` is the app's own origin plus a per-request nonce; `javascript_importmap_tags` and the layout's `csp_meta_tag` propagate that nonce so importmap, Turbo and Stimulus keep working. The nonce is generated with `SecureRandom` rather than Rails' default of the session id, so that public, session-less pages — sign-in, the blog — still get a nonce without a session being created just to hold it. Styles allow inline because Lexxy and Turbo inject inline styles at runtime that cannot carry a nonce, which is a much weaker vector.

The whole cuprite system suite validates the policy implicitly, since a broken CSP would stop importmap, Turbo and Stimulus and fail those tests, and `test/integration/content_security_policy_test.rb` asserts the header and the nonce directly.

The middleware applies the policy globally, so it also covers the mounted engine UIs — madmin, the RailsPress admin, Mission Control, Solid Errors, onlylogs. Those sit behind the superadmin gate and are not system-tested under the policy; if a panel's JavaScript breaks under it, relax the policy for that path or add nonces there rather than weakening it globally.
