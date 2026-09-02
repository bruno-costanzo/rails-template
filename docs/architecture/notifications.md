# Notifications

noticed's install migrations create `noticed_events` — the thing that happened, with an optional polymorphic record — and `noticed_notifications`, one row per recipient with `read_at` and `seen_at`, both in the primary database. `User` declares `has_many :notifications, as: :recipient, dependent: :destroy`.

The installed version keeps the event/notification split, which means database persistence is core rather than a delivery method. `deliver_by :database` is deprecated and does nothing; `SomeNotifier.deliver(recipients)` always saves synchronously inside a transaction and then unconditionally enqueues noticed's own job. Only declared delivery methods — email, Action Cable and so on — actually do anything in that job, so a notifier with none still enqueues a job that does nothing.

`ApplicationNotifier` (`app/notifiers/application_notifier.rb`) is the only notifier code in `app/`; **the app ships zero notifiers**, the same capability-only stance as pundit and analytics. The navbar bell (`app/views/shared/_notification_bell.html.erb`, `app/helpers/notifications_helper.rb`) and `/notifications` (`NotificationsController`, scoped through `Current.user`) render whatever `message` a notifier's notification methods define.

`TestNotifier` in `test/notifiers/` is the only notifier in the repository. It is required by a glob in `test/test_helper.rb`, is never loaded by app code, and exercises the whole pipeline — deliver, persist, unread count, mark read — plus the opt-in email pattern, so the wiring is covered without deciding for the app what it should notify about. The README's Notifications section carries the recipe for adding a real one.
