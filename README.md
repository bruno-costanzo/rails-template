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
- A signed-in feedback form that always saves locally and, when configured, opens a labeled GitHub Issue
- Tailwind v4 + DaisyUI 5 (vendored, no Node/npm needed), Hotwire (Turbo + Stimulus)
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

## Testing

Run `bin/ci` before every commit — it is the pre-commit gate and exactly what CI runs. It's Rails' native CI runner, configured in `config/ci.rb`: rubocop, brakeman, then `bin/rails test` and `bin/rails test:system`.

```bash
bin/ci
```

Tests never hit the network. `test/test_helper.rb` calls `WebMock.disable_net_connect!(allow_localhost: true)`, so any real HTTP call from a test fails loudly instead of silently reaching OpenAI. Stub RubyLLM calls with the helpers in `test/test_helpers/openai_stubs.rb`:

- `stub_openai_chat(content:)` — stubs a chat completion
- `stub_openai_chat_stream(chunks:)` — stubs a streamed chat completion
- `stub_openai_embedding(vector:)` — stubs an embedding request

### Coverage

100% line and branch coverage over `app/` and `lib/` is enforced by SimpleCov and measured on the `bin/rails test` (unit/integration) run. `test/test_helper.rb` sets `minimum_coverage line: 100, branch: 100`, so the suite fails the moment either number drops below 100%. Write the test that closes the gap first; never delete or weaken a failing coverage gate to make it pass. System tests (`bin/rails test:system`) are excluded from measurement — they run with `SKIP_COVERAGE=1` set (see `test/application_system_test_case.rb` and the system step in `config/ci.rb`), since browser-driven tests would otherwise double-count or skew the coverage figures gathered from the unit/integration run.

## Console auditing

console1984 protects and audits the Rails console in production. Every console session and every command run inside it is recorded to the database (`console1984_sessions`, `console1984_commands` tables), and by default only the `production` environment is protected — development and test consoles are unrestricted. This requires Active Record encryption to be configured (see the Quickstart's credentials step above). If you want a web UI for browsing the audit trail, console1984's companion gem [`audits1984`](https://github.com/basecamp/audits1984) is not installed by default but can be added later.

## Error tracking

[Solid Errors](https://github.com/fractaledmind/solid_errors) captures uncaught exceptions through Rails' native error reporter (`Rails.error`) and stores them, deduplicated by fingerprint, in the primary SQLite database (`solid_errors`/`solid_errors_occurrences` tables, migrated alongside everything else — no separate database needed). Browse them at `/errors`.

The dashboard is behind HTTP basic auth, independent of the app's own session-based login. Credentials and the notification email are read once, in `config/initializers/solid_errors.rb`, from Rails credentials first and an environment variable second:

- `Rails.application.credentials.dig(:solid_errors, :username)` / `:password`, falling back to `ENV["SOLID_ERRORS_USERNAME"]` / `ENV["SOLID_ERRORS_PASSWORD"]`
- `Rails.application.credentials.dig(:solid_errors, :email_to)`, falling back to `ENV["SOLID_ERRORS_EMAIL_TO"]`

Set the credentials block with `bin/rails credentials:edit`:

```yaml
solid_errors:
  username: some-username
  password: some-password
  email_to: devs@yourapp.com
```

Basic auth is only enabled when a password is set — the gem's filter is `http_basic_authenticate_with ... if SolidErrors.password`, so a username with no password still leaves `/errors` wide open. Set both before deploying to production. Email notification is off unless `email_to` resolves to a value; when it does, Solid Errors emails that address (via the app's already-configured Action Mailer) every time a new error occurs. `.env.test` sets `SOLID_ERRORS_USERNAME`/`SOLID_ERRORS_PASSWORD` to fixed test values so the dashboard's basic-auth test doesn't need real credentials.

Solid Errors also reads its own env vars directly, `ENV["SOLIDERRORS_USERNAME"]`/`ENV["SOLIDERRORS_PASSWORD"]` (no underscore between "SOLID" and "ERRORS") — this gem-native lookup happens ahead of anything this app configures, credentials included. Don't set those two exact variable names unless you intend them to silently win over everything else.

## User feedback

Signed-in users can leave feedback (with optional screenshots) from the "Feedback" link in the navbar dropdown, at `/feedback`. Every submission is saved locally as a `Feedback` record (`belongs_to :user`, `has_many_attached :photos`) — that part always works, with no configuration needed.

On top of that, each feedback can optionally open a GitHub Issue labeled `feedback` in a repo you choose. This is best-effort: `CreateFeedbackIssueJob` runs after the `Feedback` is created and silently does nothing unless both of these are set:

```bash
GITHUB_ISSUES_TOKEN=github_pat_your-fine-grained-token
GITHUB_ISSUES_REPO=your-org/your-repo
```

To create the token: on GitHub, go to Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token. Scope it to the single repository you want issues created in, and grant it **Issues: Read and write** repository permission (nothing else is needed). Set both env vars in `.env` (see `.env.example`).

`GithubIssues` (`app/models/github_issues.rb`) is a small PORO wrapping `Net::HTTP` — no extra gem — that POSTs to `https://api.github.com/repos/#{repo}/issues` with the token as a bearer credential and the `X-GitHub-Api-Version: 2022-11-28` header GitHub's REST API expects. `GithubIssues.configured?` is `false` whenever either env var is blank, and `CreateFeedbackIssueJob` checks that before doing anything — so with neither var set, feedback is captured locally and nothing ever reaches GitHub. If GitHub responds with anything other than a 2xx, the client raises: Solid Queue retries the job automatically, and Solid Errors captures it if retries are exhausted.

Any photos attached to the feedback are linked in the issue body through a permanent public route, `/feedback/photos/:signed_id` (`FeedbackPhotosController`), rather than a raw Active Storage blob URL — those expire and GitHub can't authenticate to fetch them anyway. That controller resolves the signed ID to a blob and then checks the blob is actually attached to some `Feedback#photos` before redirecting to it, so it can't be turned into a generic "serve any blob by signed ID" proxy for attachments elsewhere in the app (avatars, message attachments, etc.).

A future extension worth considering: auto-capturing a screenshot of the page the user was on when they opened the feedback form (e.g., via a JS screenshot library posting a data URL alongside the form). Not built here — today photos are whatever the user manually attaches.

## Money

[money-rails](https://github.com/RubyMoney/money-rails) is installed and configured with USD as the default currency (`config/initializers/money.rb`), but no monetized model ships with the template. To add a monetized column to a model: add `t.monetize :price` to a migration (this creates `price_cents` and `price_currency` columns), then declare `monetize :price_cents` on the model.

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
