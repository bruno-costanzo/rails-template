# Ticket lifecycle

`Feedback` has a `status` enum of `open` and `resolved`, defaulting to open, plus a `resolved_at` timestamp. `Feedback#resolve!` sets both, closes the support conversation the ticket came from if there is one, and is idempotent — resolving twice does not move `resolved_at` and does not raise.

`Admin::FeedbacksController` at `/admin/feedbacks` lists open tickets newest first, eager-loading the reporter and the photo blobs, and exposes a single `resolve` member action. The view links photos through the same public `/feedback/photos/:signed_id` route the GitHub issue body uses.

Nothing is notified on resolution. This panel is ticket control for the developer, not a customer-facing workflow; the person learns their conversation is over because it renders closed.

The controller includes `SuperadminAuthentication` and keeps `allow_unauthenticated_access`, so the app's session auth is skipped and the shared superadmin gate is the only one that applies. See superadmin-panels.md.
