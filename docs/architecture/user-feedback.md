# User feedback

A signed-in person leaves feedback, with optional screenshots, from the navbar dropdown at `/feedback`. Every submission is saved locally as a `Feedback` (`belongs_to :user`, `has_many_attached :photos`, validated for content type and size like the avatar). That part always works and needs no configuration.

On top of that, each feedback can open a GitHub issue. `after_create_commit` enqueues `CreateFeedbackIssueJob`, which returns immediately unless `GithubIssues.configured?` — both `GITHUB_ISSUES_TOKEN` and `GITHUB_ISSUES_REPO` set — and otherwise posts a `feedback`-labeled issue through `GithubIssues` (`app/models/github_issues.rb`), a small wrapper over `Net::HTTP` with no extra gem, sending `X-GitHub-Api-Version: 2022-11-28` per GitHub's own versioning header. The issue body carries the reporter, the app and environment, any captured context and photo links above a separator, and the person's own words below it.

A non-2xx response raises, and nothing retries it. Solid Queue has no automatic retry mechanism and the job declares no `retry_on`, so a failed issue creation lands in `solid_queue_failed_executions` and waits there to be retried or discarded from `/jobs` or a console; Solid Errors records the exception either way. The local `Feedback` row is already saved by then, so nothing is lost — only the mirror to GitHub.

Photos are linked through the permanent public route `/feedback/photos/:signed_id` rather than a raw Active Storage URL, because those expire and GitHub cannot authenticate to fetch them. `FeedbackPhotosController` resolves the signed id and then checks the blob is actually attached to some `Feedback#photos` before redirecting, so it cannot be turned into a general "serve any blob by signed id" proxy for avatars or message attachments.

Those links are absolute URLs built from `config.action_mailer.default_url_options`, because a job has no request to infer a host from. In production the host comes from `APP_HOST` and falls back to `example.com`, so an app that deploys without setting it files issues whose photo links point nowhere.
