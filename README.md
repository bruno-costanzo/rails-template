# CharcoTemplate

## What is this

CharcoTemplate is a Rails 8.1.3.1 starter template. It is a fully working app on its own, and it is also the seed you clone to start a new project (`bin/rename <new_app_name>` rewrites the app's name throughout the codebase). Everything described below already exists in this repo — clone it, rename it, and build on top.

## Features

- Native Rails authentication (sign up, sign in/out, password reset) plus a custom registration flow and a profile page
- Avatars via Active Storage variants, with an initials fallback when no avatar is uploaded
- An AI chat UI (RubyLLM + OpenAI) scoped per signed-in user, with streaming responses and automatic chat titling
- A `Document` model with Lexxy rich text editing and semantic search over embeddings (Neighbor + sqlite-vec)
- Solid Queue, Solid Cache and Solid Cable — all on SQLite, no Redis required
- console1984: every production Rails console session and command is recorded
- Solid Errors: uncaught exceptions are captured and deduplicated in SQLite, with a dashboard behind HTTP basic auth
- onlylogs: a self-hosted log viewer at `/onlylogs` behind HTTP basic auth, tailing a rotated, size-capped copy of the production log on the storage volume
- A signed-in feedback form that always saves locally and, when configured, opens a labeled GitHub Issue
- A floating AI support assistant that turns a conversation into a refined, human-friendly ticket, filed through the same feedback pipeline
- Tailwind v4 + DaisyUI 5 (vendored, no Node/npm needed), Hotwire (Turbo + Stimulus)
- Lucide icons rendered inline through a helper, no icon font or CDN
- Kamal deployment configuration ready to point at your own server

## Requirements

- [mise](https://mise.jdx.dev) (or another way to install Ruby 4.0.6 matching `.ruby-version`)
- Ruby 4.0.6
- libvips (used by Active Storage's `image_processing` gem for avatar variants)
- An OpenAI API key (for the AI chat and semantic search features)

All Ruby/Rails commands below run under `mise exec ruby@4.0.6 --` in non-mise-shimmed shells (e.g. `mise exec ruby@4.0.6 -- bin/rails test`); the examples show bare commands for readability.

## Quickstart

```bash
git clone <this-repo> my_app
cd my_app
bundle install
bin/rename my_app
bin/setup
```

New apps need their own credentials — `config/master.key` is gitignored on purpose and never travels with the repo, and console1984 depends on Active Record encryption keys that live inside `config/credentials.yml.enc`. Before running the app for real, regenerate both:

```bash
rm config/credentials.yml.enc
bin/rails credentials:edit
```

This creates a fresh `master.key` and a new encrypted credentials file (Rails' default scaffold, with a freshly generated `secret_key_base`), and opens it in your editor. Then generate new Active Record encryption keys:

```bash
bin/rails db:encryption:init
```

Copy the three printed keys (`primary_key`, `deterministic_key`, `key_derivation_salt`) into an `active_record_encryption:` block inside the credentials file (`bin/rails credentials:edit` again), then save.

Finally, start the app:

```bash
bin/dev
```

`bin/dev` runs both the Rails server and the Tailwind watcher (see `Procfile.dev`).

## Configuration

Copy `.env.example` to `.env` and fill in your own key:

```bash
cp .env.example .env
```

```
OPENAI_API_KEY=sk-your-key-here
```

`.env` is gitignored; `.env.example` (checked in) documents the required variables. `.env.test` carries a fake test key (`OPENAI_API_KEY=test-key`) so the app boots in the test environment before WebMock installs its network stubs.

## Internationalization

The UI is bilingual. **Spanish is the default; English is served when the visitor's browser prefers it** — the locale is read from the `Accept-Language` header on every request (`ApplicationController#set_locale`), picking the first language it recognizes (`es`/`en`) and otherwise falling back to Spanish. There is **no in-app language switcher, and the locale is not user-configurable** — that's deliberate: you get English only if your browser is set to English. Framework strings (dates, numbers, Active Record error messages) come from the `rails-i18n` gem; `config/application.rb` sets `default_locale = :es`, `available_locales = [:es, :en]`, and `fallbacks = [:en]`.

No user-facing copy is hardcoded — it all lives in `config/locales/es.yml` and `config/locales/en.yml`, which are kept perfectly in sync. Two gates enforce that, in the same spirit as the coverage and N+1 gates:

- `config.i18n.raise_on_missing_translations = true` (in `config/environments/test.rb`): a `t()` lookup with a missing key raises during the test suite, so an untranslated string fails the build.
- An `i18n-tasks health` step in `config/ci.rb` (configured in `config/i18n-tasks.yml`) fails CI on any missing key, unused key, or inconsistent interpolation between the two locales.

There is intentionally no static "hardcoded string in a view" linter — no maintained tool detects literal text inside ERB reliably, so a fragile one was left out; the two gates above plus review cover it.

To add a new string: wrap it in a translation lookup (views use the lazy form `t(".key")`, which resolves to `<controller>.<action>.key`), add that key to **both** `config/locales/es.yml` and `config/locales/en.yml`, then run `bin/i18n-tasks normalize` to canonicalize the files (and `bin/i18n-tasks health` to confirm the two locales are in sync). Tests assert against `I18n.t(key)` rather than English literals, so they stay locale-independent.

## Testing

Run `bin/ci` before every commit — it is the pre-commit gate and exactly what CI runs. It's Rails' native CI runner, configured in `config/ci.rb`: rubocop, brakeman, then `bin/rails test` and `bin/rails test:system`.

```bash
bin/ci
```

Tests never hit the network. `test/test_helper.rb` calls `WebMock.disable_net_connect!(allow_localhost: true)`, so any real HTTP call from a test fails loudly instead of silently reaching OpenAI. Stub RubyLLM calls with the helpers in `test/test_helpers/openai_stubs.rb`:

- `stub_openai_chat(content:)` — stubs a chat completion
- `stub_openai_chat_stream(chunks:)` — stubs a streamed chat completion
- `stub_openai_chat_stream_with_tool_call(tool_name:, arguments:, chunks:)` — stubs a streamed tool-call round trip (a tool-call chunk, then a final streamed reply)
- `stub_openai_embedding(vector:)` — stubs an embedding request

### System tests

System tests (`bin/rails test:system`) drive a real headless Chrome through **cuprite** (Ferrum/CDP), configured in `test/application_system_test_case.rb`. Cuprite talks to Chrome directly over the DevTools protocol rather than through a WebDriver/chromedriver layer, which delivers clicks and keystrokes reliably — Selenium's synthetic input dropped intermittently on the CI runner and made these tests flaky. Because input is reliable, the tests use plain Capybara (`click_button`, `fill_in`, `find(...).click`) with no `execute_script` workarounds. `Capybara.disable_animation = true` is set so DaisyUI transitions never intercept an interaction. The CI runner already ships Chrome; no extra install step is needed.

### Coverage

100% line and branch coverage over `app/` and `lib/` is enforced by SimpleCov and measured on the `bin/rails test` (unit/integration) run. `test/test_helper.rb` sets `minimum_coverage line: 100, branch: 100`, so the suite fails the moment either number drops below 100%. Write the test that closes the gap first; never delete or weaken a failing coverage gate to make it pass. System tests (`bin/rails test:system`) are excluded from measurement — they run with `SKIP_COVERAGE=1` set (see `test/application_system_test_case.rb` and the system step in `config/ci.rb`), since browser-driven tests would otherwise double-count or skew the coverage figures gathered from the unit/integration run.

### N+1 detection

The `bullet` gem watches every query the test suite issues and fails the test the moment it spots an N+1 (an association lazily loaded once per record instead of eager-loaded once for the batch) or an eager load that was requested but never used. It's enabled strictly: `config/environments/test.rb` sets `Bullet.enable = true` and `Bullet.raise = true`, so a detected N+1 on any test-exercised path is a red test, not a log line. `config/environments/development.rb` enables it non-fatally instead (`Bullet.rails_logger = true`, `Bullet.console = true`) — it logs to `log/bullet.log` and to the browser console while you develop, without raising.

`test/test_helper.rb` wraps every test (not just controller/integration ones) with `Bullet.start_request`/`Bullet.end_request` in `before_setup`/`after_teardown`, exactly as Bullet's Minitest integration doc recommends. Controller, integration, and system tests already get this for free from Bullet's own Rack middleware (auto-inserted by its Railtie), but plain model/unit tests that touch associations directly do not go through that middleware, so the explicit wrapping is what makes strict mode apply everywhere. System tests are covered too: they run against a real in-process Puma server, Bullet's middleware wraps each request on that server thread the same way it does in production, and Capybara's `raise_server_errors` (on by default) re-raises the exception in the test thread — verified empirically by reverting a known eager load and watching a system test fail with the `Bullet::Notification::UnoptimizedQueryError`.

When a test fails with `Bullet::Notification::UnoptimizedQueryError`, the message tells you exactly what to do: "USE eager loading detected ... Add to your query: .includes([...])" means a real N+1 — add the suggested `includes`/`preload`, or a counter cache if it says "Need Counter Cache". "AVOID eager loading detected ... Remove from your query: .includes([...])" means an eager load that this particular code path never used — either the `includes` is genuinely unnecessary and should be removed, or it's necessary for a different caller than the one this test exercises. The stack trace under the message points at the exact model, association, and call site.

Only add an entry to the safelist (`Bullet.add_safelist`) when you've verified the second case: the eager load is correct for its real call site, just not exercised by this particular test. Keep the entry as narrow as possible — exact `class_name` and `association`, never a blanket disable of a detector. For example, `NotificationsHelperTest` calls `recent_notifications` (which does `.includes(:event)`) without ever rendering a notification's `message`, so Bullet sees the eager load as unused in that one test even though the navbar bell partial that calls `recent_notifications` in production always renders `message` (which delegates to `event`). That's safelisted narrowly in `config/environments/test.rb`:

```ruby
Bullet.add_safelist type: :unused_eager_loading, class_name: "TestNotifier::Notification", association: :event
```

## Console auditing

console1984 protects and audits the Rails console in production. Every console session and every command run inside it is recorded to the database (`console1984_sessions`, `console1984_commands` tables), and by default only the `production` environment is protected — development and test consoles are unrestricted. This requires Active Record encryption to be configured (see the Quickstart's credentials step above). If you want a web UI for browsing the audit trail, console1984's companion gem [`audits1984`](https://github.com/basecamp/audits1984) is not installed by default but can be added later.

## Superadmin access

Every developer-only panel — `/errors`, `/onlylogs`, `/admin/feedbacks`, the `/jobs` Solid Queue dashboard, and the `/madmin` resource browser — is gated by a single HTTP basic-auth credential pair, independent of the app's own session-based login, through the `SuperadminAuthentication` concern (`app/controllers/concerns/superadmin_authentication.rb`). A controller only needs `include SuperadminAuthentication`; the concern's `included` hook registers the `before_action`. Credentials resolve credentials-first then ENV, read live on every request (so tests can flip ENV per example):

- `Rails.application.credentials.dig(:superadmin, :username)` / `:password`, falling back to `ENV["SUPERADMIN_USER"]` / `ENV["SUPERADMIN_PASSWORD"]`

Comparison is constant-time (`ActiveSupport::SecurityUtils.secure_compare`). The gate is **deny-by-default**: when either value is blank, every request gets a `401 Unauthorized` — there is no "leave it open when unconfigured" fallback anywhere. This is deliberately stricter than the Solid Errors and onlylogs gem defaults, both of which leave their own dashboard open until a password is set; here that door is closed. Set the credentials block with `bin/rails credentials:edit`:

```yaml
superadmin:
  username: some-username
  password: some-password
```

To reuse one shared pair across every app born from this template, keep the values out of every repo and inject them at deploy time: store them once in your password manager, then list `SUPERADMIN_USER`/`SUPERADMIN_PASSWORD` under `env.secret` in `config/deploy.yml` and resolve them in `.kamal/secrets` (for example via `kamal secrets fetch --adapter 1password`, next to `RAILS_MASTER_KEY` and `OPENAI_API_KEY`). Rotating the credential is a redeploy — no repo ever contains the values.

### Background jobs (Mission Control)

`/jobs` is [Mission Control — Jobs](https://github.com/rails/mission_control-jobs), the dashboard for Solid Queue: browse queues, inspect and retry failed jobs, pause and resume queues. It's gated by the same superadmin auth — `config/initializers/mission_control_jobs.rb` sets `MissionControl::Jobs.base_controller_class = "MissionControlJobsBaseController"` (which just `include SuperadminAuthentication`) and `MissionControl::Jobs.http_basic_auth_enabled = false`, so the gem's own basic auth stands down and only the superadmin gate applies.

### Resource browser (madmin)

`/madmin` is a [madmin](https://github.com/excid3/madmin) panel for browsing and editing the app's records, gated by the same superadmin auth (`Madmin::ApplicationController` includes the concern). It ships dashboards for the domain models only — `Chat`, `Document`, `Feedback`, `Message`, `Model`, `Session`, `ToolCall`, `User`, plus `Noticed::Notification` and `Noticed::Event`. The framework-internal and sensitive resources the installer generates (Active Storage, Action Text, console1984 audit logs, and Solid Errors — which already has `/errors`) were removed from `config/routes/madmin.rb`, `app/madmin/resources/`, and `app/controllers/madmin/`. Adding a dashboard for a new model is a manual, deliberate step — there is no "auto-generate a dashboard for every model" option, in madmin or here. The resource generator reads the model's columns (`attribute_names`/`attribute_types`), so the table has to exist first; run it **after** the migration:

```bash
bin/rails g model Widget name:string
bin/rails db:migrate
bin/rails g madmin:resource Widget
```

Then trim the generated route/resource/controller the same way if the generator pulls in extras you don't want exposed. (This ordering is why a "create the model, get the dashboard for free" hook isn't wired: right after `rails g model` the table hasn't been migrated yet, so the resource generator would fail.)

Two integration points with the template's conventions: madmin's generated files are excluded from the 100%-coverage gate (`add_filter "app/madmin"` / `add_filter "app/controllers/madmin"` in `test/test_helper.rb`), since they're generated boilerplate; and `Madmin::ApplicationController` disables Bullet for the duration of each madmin request (`around_action :without_bullet if defined?(Bullet)`), because madmin's index views intentionally lazy-load associations and would otherwise trip the strict N+1 gate — acceptable for a dev-only panel over bounded data.

## Error tracking

[Solid Errors](https://github.com/fractaledmind/solid_errors) captures uncaught exceptions through Rails' native error reporter (`Rails.error`) and stores them, deduplicated by fingerprint, in the primary SQLite database (`solid_errors`/`solid_errors_occurrences` tables, migrated alongside everything else — no separate database needed). Browse them at `/errors`.

The dashboard is behind the shared superadmin basic auth (see [Superadmin access](#superadmin-access)), not the gem's own: `config/initializers/solid_errors.rb` sets `SolidErrors.base_controller_class = "SolidErrorsBaseController"`, and that controller just `include SuperadminAuthentication`. So `/errors` is deny-by-default like the other panels — the initializer no longer sets `SolidErrors.username`/`password`, which leaves the gem's own password-gated filter inert. Only the notification email stays panel-specific, read once in the initializer from Rails credentials first and an environment variable second:

- `Rails.application.credentials.dig(:solid_errors, :email_to)`, falling back to `ENV["SOLID_ERRORS_EMAIL_TO"]`

Email notification is off unless `email_to` resolves to a value; when it does, Solid Errors emails that address (via the app's already-configured Action Mailer) every time a new error occurs.

## Log viewer

[onlylogs](https://github.com/renuo/onlylogs) mounts a self-hosted web log viewer at `/onlylogs`: live-tail the log in the browser, grep it (with regular expressions — install [ripgrep](https://github.com/BurntSushi/ripgrep) on the server for fast searches), and download it. No external log service involved.

Production keeps logging to STDOUT exactly as before (`bin/kamal logs` is unchanged), but `config/environments/production.rb` now broadcasts every line to a second destination through `ActiveSupport::BroadcastLogger`: `storage/logs/production.log`, on the persistent storage volume that `config/deploy.yml` already mounts. That file is rotated by Ruby's own `Logger` (`ActiveSupport::TaggedLogging.logger(path, 5, 100.megabytes)`): when it reaches 100 MB it shifts to `production.log.0`, keeping at most five files total (`production.log` plus `.0`–`.3`), so the on-disk copy is hard-capped at ~500 MB and can never fill the volume.

The viewer's file whitelist (`config.log_file_patterns` in `config/initializers/onlylogs.rb`) is restricted to exactly that path — onlylogs automatically extends a `*.log` entry to its `*.log.N` rotation suffixes, so the dropdown lists the rotated set too, and nothing else on the server is reachable through the viewer. In development and test the environment's own `log/<env>.log` is additionally whitelisted so the viewer has something to show locally.

Access control for the HTTP side (the `/onlylogs` page and its download endpoint) is the shared superadmin basic auth (see [Superadmin access](#superadmin-access)), not the gem's built-in one. Onlylogs ships its own basic-auth (it answers 403 when unconfigured, reads ENV ahead of credentials, and only once at boot); this app bypasses it through the gem's documented custom-auth hook — `config.disable_basic_authentication` plus `config.parent_controller` pointing at `OnlylogsBaseController` (`app/controllers/onlylogs_base_controller.rb`), which just `include SuperadminAuthentication`. So `/onlylogs` is gated by `SUPERADMIN_USER`/`SUPERADMIN_PASSWORD` exactly like the other panels — deny-by-default, read live per request — while the gem's own auth no-ops under `disable_basic_authentication`.

**Basic auth protects the HTTP surface only.** The live tail streams over Action Cable, and by the gem's design `Onlylogs::LogsChannel` performs no basic-auth check of its own — the WebSocket's boundary is whatever the app's cable connection accepts, which here is *any signed-in user* (`app/channels/application_cable/connection.rb`), and this template ships open self-registration. The channel's protection is the file whitelist plus path encryption: a streamable path must decrypt via `Onlylogs::SecureFilePath` (keyed from `secret_key_base`) and re-pass the whitelist. Two consequences:

- The gem's blank-path fallback (`initialize_watcher` with no `file_path` streams `default_log_file_path` with **no decryption and no whitelist check**) would have let any signed-in user live-tail the production log without onlylogs credentials. This template neutralizes it by setting `config.default_log_file_path = ""` — a path that can never exist, so the channel's text-file check rejects the fallback before reading anything. Don't point `default_log_file_path` back at a real log file; a channel test (`test/channels/onlylogs_logs_channel_test.rb`) guards this.
- Residual risk that remains after that fix: encrypted path tokens are normally only rendered into pages behind `/onlylogs` basic auth, but the channel never checks onlylogs credentials — so a signed-in user who somehow holds a valid encrypted token for a whitelisted file (a leaked page source, a shared URL, an operator's copy-paste) can stream that file over the socket without basic auth. The tokens don't expire (`MessageEncryptor` without expiry), so treat rendered `/onlylogs` HTML as sensitive.

**Known upstream gap** worth patching in the gem (renuo/onlylogs): the channel has no `parent_controller`-style hook to inject app authentication into the WebSocket path, and the gem README's claim that streaming always requires a whitelisted, encrypted path is false for the blank-path branch of `LogsChannel#initialize_watcher`. Until that's fixed upstream, the two mitigations above are what stand between a signed-in user and the log stream.

This is stage 1 of a two-stage plan. Stage 2 — streaming logs from all apps to one central onlylogs server instead of hosting a viewer per app — is deliberately not built yet: onlylogs' server side (https://onlylogs.io) is still in beta and not yet publicly self-hostable. When it is, the per-app viewer can be replaced by (or complemented with) streaming to that single central instance.

## Development email preview

[letter_opener_web](https://github.com/fgrehm/letter_opener_web) catches every email the app sends in development and lists them in a browsable inbox at `/letter_opener`, instead of trying to reach a real SMTP server. This is where password-reset emails (`PasswordsMailer`) and Solid Errors notification emails land while developing locally.

The gem lives in the `development` group of the `Gemfile`, so it never loads in test or production; `config/routes.rb` also mounts it only `if Rails.env.development?`, and `config/environments/development.rb` sets `config.action_mailer.delivery_method = :letter_opener_web`. Test and production delivery are untouched — `config/environments/test.rb` still uses `:test`, and production keeps whatever SMTP settings it's configured with.

## User feedback

Signed-in users can leave feedback (with optional screenshots) from the "Feedback" link in the navbar dropdown, at `/feedback`. Every submission is saved locally as a `Feedback` record (`belongs_to :user`, `has_many_attached :photos`) — that part always works, with no configuration needed.

On top of that, each feedback can optionally open a GitHub Issue labeled `feedback` in a repo you choose. This is best-effort: `CreateFeedbackIssueJob` runs after the `Feedback` is created and silently does nothing unless both of these are set:

```bash
GITHUB_ISSUES_TOKEN=github_pat_your-fine-grained-token
GITHUB_ISSUES_REPO=your-org/your-repo
```

To create the token: on GitHub, go to Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token. Scope it to the single repository you want issues created in, and grant it **Issues: Read and write** repository permission (nothing else is needed). Set both env vars in `.env` (see `.env.example`).

`GithubIssues` (`app/models/github_issues.rb`) is a small PORO wrapping `Net::HTTP` — no extra gem — that POSTs to `https://api.github.com/repos/#{repo}/issues` with the token as a bearer credential and the `X-GitHub-Api-Version: 2022-11-28` header GitHub's REST API expects. `GithubIssues.configured?` is `false` whenever either env var is blank, and `CreateFeedbackIssueJob` checks that before doing anything — so with neither var set, feedback is captured locally and nothing ever reaches GitHub. If GitHub responds with anything other than a 2xx, the client raises; the job has no custom retry configuration of its own, so it relies entirely on Solid Queue's default retry-with-backoff behavior, and Solid Errors captures it if retries are exhausted.

Any photos attached to the feedback are linked in the issue body through a permanent public route, `/feedback/photos/:signed_id` (`FeedbackPhotosController`), rather than a raw Active Storage blob URL — those expire and GitHub can't authenticate to fetch them anyway. That controller resolves the signed ID to a blob and then checks the blob is actually attached to some `Feedback#photos` before redirecting to it, so it can't be turned into a generic "serve any blob by signed ID" proxy for attachments elsewhere in the app (avatars, message attachments, etc.).

Those photo links are absolute URLs, built with `Rails.application.config.action_mailer.default_url_options` (the same host config used for password-reset emails) since a background job has no request to infer a host from. `config/environments/production.rb` ships that as the placeholder `{ host: "example.com" }` — like the `YOUR_REGISTRY_USER`/`YOUR_SERVER_IP`/domain placeholders in `config/deploy.yml`, **this must be replaced with your app's real production host before deploying**, or photo links inside GitHub issues will silently point at `example.com` instead of your app.

A future extension worth considering: auto-capturing a screenshot of the page the user was on when they opened the feedback form (e.g., via a JS screenshot library posting a data URL alongside the form). Not built here — today photos are whatever the user manually attaches, and the support chat's context capture (below) only ever carries plain text (page URL, user agent, viewport), never a screenshot image.

## AI support assistant

Every signed-in page shows a floating "Support" button (bottom-right corner). It opens a chat panel backed by a dedicated support `Chat` (`support: true`, one per user, found-or-created by `SupportChatsController`). The assistant listens to the person's problem or suggestion, asks clarifying questions in plain language, and once it understands the issue, calls `CreateSupportTicketTool` (`app/tools/create_support_ticket_tool.rb`, a `RubyLLM::Tool`) to file it — this creates a `Feedback` record for that user, reusing the exact same pipeline as the manual feedback form above (Task 22): it always saves locally, and opens a labeled GitHub Issue when `GITHUB_ISSUES_TOKEN`/`GITHUB_ISSUES_REPO` are set. The assistant needs `OPENAI_API_KEY` to work at all (like the rest of the AI chat); without it, the support button still opens the panel, but the assistant can't reply.

Every time the widget's panel is opened for the first time on a page, its Stimulus controller (`app/javascript/controllers/support_chat_controller.js`) captures three plain strings — the page URL, the browser's user agent, and the viewport size (e.g. `"1512x982"`) — and appends them as `context[...]` query params on the frame's request to `SupportChatsController#show`. The controller whitelists exactly those three keys, discards anything else, and truncates each value to 2 kilobytes before storing them as plain text in `ticket_context` (a JSON column on `Chat`, used only by support chats — never interpreted, never executed, just carried along as metadata). That column is deliberately **not** called `context`: RubyLLM's `acts_as_chat` already defines its own `context` attribute on chat records (for provider-specific request configuration), and reusing that name silently breaks it. When `CreateSupportTicketTool` files the ticket, it copies `chat.ticket_context` onto the new `Feedback#context` (a plain JSON column — no naming conflict there), and `CreateFeedbackIssueJob` renders those values as a `Context:` block inside the trusted, developer-only metadata section of the issue body, before the `---` separator that precedes the person's own words. None of this ever reaches the chat UI the person sees — it only ever surfaces in the GitHub issue.

The widget also has a small attach control (the paperclip icon, via `lucide_icon("paperclip")`) next to the message box. Picking a file uploads it immediately to `POST /support_chat/photos` (`SupportChatPhotosController`, scoped strictly through `Current.user.chats.find_by!(support: true)` — there is no way to attach to another user's chat), where it's held on `Chat#pending_photos` (`has_many_attached`, with the exact same content-type/size validation as `Feedback#photos`). When the ticket is filed, `CreateSupportTicketTool` attaches those same blobs onto the new `Feedback#photos` and then calls `chat.pending_photos.detach` — **not** `.purge`. `Blob#purge` does rescue `ActiveRecord::InvalidForeignKey`, so the `active_storage_attachments` → `active_storage_blobs` foreign key (present in this app's schema, with SQLite foreign keys on by default) would in practice stop a `purge` from deleting a blob still referenced by the `Feedback`'s new attachment. But relying on that rescue for correctness would be fragile — it depends on the FK constraint existing and being enforced, and it would still destroy the `Chat`'s own attachment row and briefly attempt (then abort) the delete. `.detach` sidesteps all of that: it only removes the join row and never touches the blob, so it's correct independent of any FK-constraint behavior. From there the photos flow into the GitHub issue exactly like manually-attached feedback photos do (Task 22): through the public `/feedback/photos/:signed_id` route.

**The binding rule:** nothing the person sees in this chat may ever contain code, file names, stack traces, class names, or any other technical detail — only plain, human-friendly language. This is enforced in depth:

1. `SupportContext.instructions` (`app/models/support_context.rb`) prepends `SupportContext::BINDING_RULE`, a fixed English sentence stating the rule, to every support chat's system prompt. `SupportAgent` (`app/agents/support_agent.rb`, a `RubyLLM::Agent`) declares these instructions and the ticket-filing tool; `ChatResponseJob` finds the chat through `SupportAgent.find(chat_id)` instead of `Chat.find` only when `chat.support?` is true — normal chats are unaffected. Because `Agent.find` applies instructions at runtime (never persisted as a `messages` row), a multi-turn support conversation re-sends the same instructions on every turn without ever duplicating or staling a persisted system message.
2. `config/support_context.md` — a short, human-friendly, explicitly non-technical description of the app — is the *only* app-specific knowledge given to the assistant. It ships as a placeholder; **keep it non-technical when you edit it for your own app.** `SupportContext.content` reads it (empty string if the file is ever removed).
3. Technical message types (the system prompt itself, tool-call requests, tool results) are never rendered in the support chat's UI even if something goes wrong upstream: `Message#to_partial_path` renders those as a blank partial for support chats specifically (`app/models/message.rb`), while the normal chat UI (which is meant to be transparent/debuggable) still shows them in full.
4. The ticket itself — the refined title and summary the tool files — is written for the developer and can be as technical as the person's own words make it; only the chat reply shown back to the person stays in plain language.

## Ticket lifecycle

Every `Feedback` (Task 22, whether filed through the manual form or the AI support assistant above) carries a `status` (`open`/`resolved`, default `open`) and a `resolved_at` timestamp. `Feedback#resolve!` sets both; calling it on an already-resolved ticket is a no-op — `resolved_at` doesn't change and it doesn't raise. Resolving a ticket only updates that local record; **it never sends any notification** (no email, no GitHub comment) — the scope here is ticket control, nothing more.

Open tickets are worked from a minimal admin panel at `/admin/feedbacks` (`Admin::FeedbacksController`): a table of open tickets with the reporter's email, message, context, links to any attached photos (reusing the same public `/feedback/photos/:signed_id` route the GitHub issue body uses), and a "Resolve" button per row that calls `resolve!` and redirects back. Resolved tickets drop off the list; there's no separate view for them, since ticket control — not a full archive — is the goal.

The panel sits behind the shared superadmin basic auth (see [Superadmin access](#superadmin-access)), independent of the app's session-based login: `Admin::FeedbacksController` `include SuperadminAuthentication` and keeps `allow_unauthenticated_access` so only the superadmin gate applies. Access is the same `SUPERADMIN_USER`/`SUPERADMIN_PASSWORD` (or `superadmin` credentials block) as every other panel — resolved live per request, deny-by-default, so `/admin/feedbacks` returns `401 Unauthorized` until the credentials are set. Configure them before you need the panel; there's no way to reach it otherwise.

## Money

[money-rails](https://github.com/RubyMoney/money-rails) is installed and configured with USD as the default currency (`config/initializers/money.rb`), but no monetized model ships with the template. To add a monetized column to a model: add `t.monetize :price` to a migration (this creates `price_cents` and `price_currency` columns), then declare `monetize :price_cents` on the model.

## Icons

The template's icon set is [Lucide](https://lucide.dev), via the `lucide-rails` gem: icons render as inline `<svg>` markup through the `lucide_icon` helper, no icon font and no CDN. In any view:

```erb
<%= lucide_icon "house", class: "size-4" %>
```

The first argument is the icon's name as it appears in the [Lucide icon library](https://lucide.dev/icons) (kebab-case, e.g. `house`, `arrow-right`, `circle-check`). Any keyword argument becomes an HTML attribute on the rendered `<svg>` — `class:` is the common case for sizing and color, since stroke color follows `currentColor` by default. Global defaults (applied to every icon) can be overridden via `LucideRails.default_options=` in an initializer if a future app needs that; the template doesn't set one.

## Notifications

[Noticed](https://github.com/excid3/noticed) provides the in-app notification pipeline: a bell in the navbar, a `/notifications` page, and the database tables and Active Job wiring underneath them. The template ships **zero notifications** — no notifier ever fires in app code. What ships is the capability: install the gem's migrations, `ApplicationNotifier` as a base class, the `User` recipient association, and the bell UI. A child app adds one notifier class and the bell works.

The installed gem is Noticed 3.0.0, which keeps the `Event`/`Notification` split introduced in the v2 rewrite (v1 used a single notification class). In this architecture, database persistence is core, not a delivery method — declaring `deliver_by :database` raises a deprecation warning and does nothing (`Noticed::Deliverable#deliver_by`, noticed gem, `app/models/concerns/noticed/deliverable.rb`). Calling `SomeNotifier.deliver(recipients)` always saves a `Noticed::Event` row (the thing that happened, with an optional polymorphic `record`) and one `Noticed::Notification` row per recipient (the per-person inbox entry: `read_at`, `seen_at`), inside a transaction — synchronously, no job needed just to see it in someone's inbox. Only the *delivery methods* you declare (`:email`, `:action_cable`, `:slack`, etc.) run through a background job (`Noticed::EventJob`, itself an `ActiveJob::Base` subclass), which Solid Queue is already configured to run in this app.

### Create a notifier

```bash
bin/rails generate noticed:notifier NewCommentNotifier
```

Or by hand, inheriting from `ApplicationNotifier` (`app/notifiers/application_notifier.rb`):

```ruby
# app/notifiers/new_comment_notifier.rb
class NewCommentNotifier < ApplicationNotifier
  notification_methods do
    def message
      "#{params[:comment].author.name} commented on your post"
    end

    def url
      post_path(params[:comment].post)
    end
  end
end
```

Deliver it to one or many recipients:

```ruby
NewCommentNotifier.with(record: comment, comment: comment).deliver(post.author)
```

`record:` is special — it fills the `Noticed::Event#record` polymorphic association (what the notification is *about*), so you can later ask "every notification generated from this comment." Any recipient with `has_many :notifications, as: :recipient, class_name: "Noticed::Notification"` (already added to `User`) picks it up immediately: `recipient.notifications.unread.count`, `recipient.notifications.newest_first`, `notification.mark_as_read`. The bell (`app/views/shared/_notification_bell.html.erb`, backed by `NotificationsHelper`) and the full list at `/notifications` (`NotificationsController`, scoped through `Current.user`) render whatever `message` your notifier's `notification_methods` block defines — every notifier you write needs one.

`User#notifications`'s `dependent: :destroy` only cleans up the recipient side: if you pass `record:` and that record is later destroyed, its `Noticed::Event` rows (and their notifications) are not cleaned up automatically and will linger in `noticed_events`. If you add a notifier tied to a record, also add the record-side association Noticed's own README documents ("Associating Notifications"): `has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"` on that model.

### Email opt-in pattern

Nothing ships with email enabled. To add it to a specific notifier, use Noticed's built-in `:email` delivery method and guard it with `config.if`:

```ruby
class NewCommentNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "NewCommentMailer"
    config.method = :notify
    config.if = -> { recipient.email_notifications? }
  end

  notification_methods do
    def message
      "#{params[:comment].author.name} commented on your post"
    end
  end
end
```

`config.mailer` and `config.method` are required (`Noticed::DeliveryMethods::Email`, noticed gem, `lib/noticed/delivery_methods/email.rb`); the delivery method calls `mailer.with(params).public_send(method)`, so the mailer action reads `params[:notification]`, `params[:record]`, and `params[:recipient]`. `config.if`/`config.unless` are evaluated per-recipient at delivery time (not at `.deliver` time), so you can check a per-user preference, not just a global switch. This exact pattern — a `deliver_by :email` block guarded by `config.if`, backed by a plain `ActionMailer::Base` mailer — is exercised end-to-end by the template's only notifier, `TestNotifier` (`test/notifiers/`), which is test-only and never invoked by app code. Its test (`test/notifiers/test_notifier_test.rb`) delivers with and without the opt-in param and asserts `ActionMailer::Base.deliveries` accordingly.

In development, any email a notifier sends lands in the same [letter_opener](#development-email-preview) inbox at `/letter_opener` as password resets — no separate setup needed.

### Future channels (not installed)

- **Web push** (desktop/mobile browser notifications while the app is closed) needs the [`web-push`](https://github.com/pushpad/web-push) gem plus VAPID keys and a service worker subscription flow. Deliberately not installed — add it if a real notifier needs it, then `deliver_by :web_push` following Noticed's docs.
- **Mobile push** (iOS/Android native apps) is supported by Noticed's built-in `:fcm` (Firebase Cloud Messaging) and `:ios` (Apple Push Notification Service) delivery methods — no extra gem needed, just credentials and device tokens, wired up the same `deliver_by` way as `:email` above.

## Authorization

[Pundit](https://github.com/varvet/pundit) provides the authorization capability: plain Ruby policy classes that answer "may this user do this to this record." The template ships **zero policies** — no `authorize` call exists in app code, mirroring how [Notifications](#notifications) ships zero notifiers. What ships is the capability: the gem, `Pundit::Authorization` included in `ApplicationController` (with `pundit_user` mapped to `Current.user`, since this app has no `current_user`), a `rescue_from Pundit::NotAuthorizedError` that redirects back with an alert, and `ApplicationPolicy` (`app/policies/application_policy.rb`) as the default-deny base class. A child app adds one policy class and authorization works.

Until you need it, `Current.user` scoping **is** the template's authorization: every controller already fetches records through `Current.user.chats`, `Current.user.documents`, and so on, which makes "not yours" indistinguishable from "not found." Reach for Pundit when that stops being enough — the first role (admin, moderator), the first shared resource (a document with viewers and editors), the first rule beyond "the owner may do everything."

### Create a policy

```bash
bin/rails generate pundit:policy Document
```

Or by hand, inheriting from `ApplicationPolicy`:

```ruby
# app/policies/document_policy.rb
class DocumentPolicy < ApplicationPolicy
  def show?
    record.user == user
  end

  def update?
    record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
```

`ApplicationPolicy` answers `false` to every action, so a policy only grants what it explicitly opens up. In a controller, `authorize` looks up the policy from the record's class, asks the query named after the current action (`authorize document` inside `update` asks `DocumentPolicy#update?` — the query defaults to `"#{action_name}?"`), returns the record when allowed, and raises `Pundit::NotAuthorizedError` when not — which the `ApplicationController` rescue turns into a redirect back (or to root) with an alert toast:

```ruby
def update
  @document = Document.find(params[:id])
  authorize @document
  @document.update!(document_params)
end
```

For index-style actions, `policy_scope(Document)` runs your policy's `Scope#resolve` against the current user and returns the filtered relation. In views, the `policy` helper drives conditional UI: `<% if policy(document).update? %>` around the edit link.

The whole pipeline — permit, deny with the redirect-and-alert rescue, and scope filtering — is exercised by the template's test-only `PunditTestRecordPolicy` (`test/policies/`), a policy for a plain test-only record class that shadows no app model, never loaded by app code, exactly like `TestNotifier`.

### Opt-in strictness

Once an app adopts policies broadly, Pundit can enforce that no action forgets them: `after_action :verify_authorized` raises unless the action called `authorize` (and `after_action :verify_policy_scoped` does the same for `policy_scope` on index actions). The template deliberately does not enable these — they would force a policy onto every existing action, and that is an app decision, not a template one. When you flip them on, `skip_authorization` / `skip_policy_scope` mark the actions that legitimately have nothing to authorize.

## Deployment

Deploys use [Kamal](https://kamal-deploy.org). Before your first deploy, edit `config/deploy.yml` and replace every UPPERCASE placeholder with real values:

- `YOUR_REGISTRY_USER` — your container registry username
- `YOUR_SERVER_IP` — your server's IP address
- `app.YOUR_DOMAIN.com` — the domain the app will be served from

`RAILS_MASTER_KEY` and `OPENAI_API_KEY` are injected as secrets via `.kamal/secrets` (which reads `config/master.key` and the `OPENAI_API_KEY` environment variable — never commit real secrets into that file). A persistent storage volume (`storage/` mounted at `/rails/storage`) is mandatory: it holds the SQLite database files and any locally-stored Active Storage uploads, so losing it means losing data.

```bash
kamal setup
```

## Adding 2FA later

Two-factor authentication is not included, but the native authentication controllers this template ships with (`SessionsController`, `RegistrationsController`) are yours to extend. A minimal approach with [`rotp`](https://github.com/mdp/rotp):

```ruby
# add otp_secret + otp_required_for_login columns to users, then in SessionsController#create:
if user.otp_required_for_login
  return redirect_to new_session_otp_path(user_id: user.id) # a small controller that verifies ROTP::TOTP.new(user.otp_secret).verify(params[:code])
end
```

Wire the verification step in before `start_new_session_for(user)` is called, so a correct password alone never finishes authentication for an account with 2FA enabled.

## Updating this template

Since this repo doubles as a living app, keeping it current means:

1. Bump `.ruby-version` and the `rails` constraint in the `Gemfile`, then `bundle update rails`.
2. Re-download the vendored DaisyUI files (`app/assets/tailwind/daisyui.mjs`, `app/assets/tailwind/daisyui-theme.mjs`) from the DaisyUI release you're targeting.
3. Run any `ruby_llm:upgrade_to_*` generators RubyLLM ships when you bump its version, to pick up new migrations/config.
4. Run `bin/ci` before committing the upgrade.

Also worth re-checking after a Rails upgrade: whether Lexxy still needs to monkey-patch `rich_text_area` (see `CLAUDE.md`'s Subsystem map) — a new Rails version may ship the official `ActionText::Editor` adapter API Lexxy prefers.

## Porting template improvements into an existing app

Apps born from this template do not receive updates automatically — "Use this template" creates a fresh history with no git link back, and `bin/rename` rewrites the app's identity throughout the tree, so wholesale merges from the template would conflict everywhere the rename touched. This is a deliberate trade-off: your app fully owns its code and its name.

Individual improvements port well with cherry-pick:

```bash
git remote add template git@github.com:bruno-costanzo/rails-template.git
git fetch template
git log template/main --oneline
git cherry-pick <sha>
```

What applies cleanly: commits that never mention the app name — JavaScript fixes, jobs, POROs, migrations, test helpers, gem bumps. Recent examples of this kind: streaming-race fixes, upload validations, N+1 guards.

What conflicts: anything `bin/rename` rewrote — layouts and views carrying the app name, `config/` files, `database.yml`, `deploy.yml`. For those, read the template commit's diff (`git show <sha>`) and apply the change by hand under your app's names.

Pick commits one at a time, run `bin/ci` after each, and skip anything your app has since diverged from — a template improvement is an offer, not an obligation.
