# Error tracking

Solid Errors subscribes to `Rails.error` from `config/initializers/solid_errors.rb` and persists deduplicated exceptions to the primary database — no separate database, migrated like everything else. The dashboard is mounted at `/errors` and gated by the shared superadmin basic auth: the initializer sets `SolidErrors.base_controller_class` to `SolidErrorsBaseController`, which only includes `SuperadminAuthentication`. The gem's own username and password settings are deliberately left unset, which leaves its internal `http_basic_authenticate_with` inert, so the deny-by-default concern is the only gate.

Email notification is the one panel-specific setting: the recipient resolves from `Rails.application.credentials.dig(:solid_errors, :email_to)` and then `SOLID_ERRORS_EMAIL_TO`, and notifications only fire when one of them resolves.

Browser exceptions land in the same dashboard; see browser-errors.md.
