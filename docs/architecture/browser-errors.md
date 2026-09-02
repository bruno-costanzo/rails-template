# Browser errors

`app/javascript/error_reporting.js`, called from `app/javascript/application.js`, listens for `error` and `unhandledrejection` on the window and posts to `JavascriptErrorsController`. The controller wraps the report in a `JavascriptError` (`app/errors/javascript_error.rb`) with the browser stack as its backtrace and hands it to `Rails.error.report` as handled, tagged with a source and the page URL, user agent and user id — so **Solid Errors records browser failures next to server ones at `/errors`**.

Both ends are fenced. The client caps reports at five per page load, truncates the message and stack, and swallows failures of its own fetch so a broken endpoint cannot start a reporting loop. The server rejects a blank message with `400`, is rate-limited, and truncates the message and the backtrace before reporting.

The CSRF token is attached when present and never required. `csrf_meta_tags` renders nothing when forgery protection is off, which is the case in test, so requiring the token would silently drop every report there and make the wiring untestable. The server is the enforcement point.

An error thrown from injected script is masked by the browser to a generic message with a null error object, which is why the system test dispatches a synthetic error event instead of throwing one.
