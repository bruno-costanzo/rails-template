# CharcoTemplate

Rails starter template. This repo is both a working app and the template new apps are born from (`bin/rename <new_app_name>` after cloning).

## Stack
- Ruby 4.0.6, Rails 8.1.3.1, SQLite everywhere (Solid Queue/Cache/Cable on SQLite)
- Propshaft + Importmap (no Node), Tailwind v4 + DaisyUI 5 (vendored `app/assets/tailwind/daisyui.mjs`, `app/assets/tailwind/daisyui-theme.mjs`)
- Hotwire (Turbo + Stimulus), Lexxy for Action Text rich text
- RubyLLM (OpenAI only: gpt-4o-mini / text-embedding-3-small), Schematist for structured output, Neighbor + sqlite-vec for vector search
- Native Rails authentication (+ custom registration/profile), Active Storage avatars
- console1984 for audited production console access (depends on Active Record encryption)
- money-rails for currency handling (default currency USD in `config/initializers/money.rb`, no monetized model ships — apps opt in per-model)
- Minitest + fixtures + WebMock (tests NEVER hit the network), Kamal deploys

## Commands
- `bin/setup` — install and prepare everything
- `bin/dev` — run app + Tailwind watcher
- `bin/ci` — the pre-commit gate; run it before every commit, it is exactly what CI runs. It's Rails' native CI runner (`ActiveSupport::ContinuousIntegration`), configured in `config/ci.rb` with four steps: rubocop, brakeman, `bin/rails test`, `bin/rails test:system`
- `bin/rename <name>` — turn the template into a new app

All Ruby/Rails commands run under `mise exec ruby@4.0.6 -- <command>` in non-mise-shimmed shells (e.g. `mise exec ruby@4.0.6 -- bin/rails test`).

## Conventions
- TDD always: failing test first, minimal implementation second.
- English-only code and copy. No code comments. No inline styles.
- DaisyUI component classes before custom CSS.
- Controllers scope data through `Current.user` (see `ChatsController`, `DocumentsController`).
- LLM calls in tests use `stub_openai_chat` / `stub_openai_chat_stream` / `stub_openai_embedding` (test/test_helpers/openai_stubs.rb).
- Background work goes to Solid Queue jobs (see `GenerateDocumentEmbeddingJob`).
- 100% line and branch coverage is enforced by SimpleCov; `bin/rails test` fails below 100%. Write the test first; never delete a failing coverage gate. System tests run with `SKIP_COVERAGE=1` and are excluded from measurement.
- Commits: short imperative messages, no co-author trailers.

## Subsystem map
- Auth: `app/controllers/concerns/authentication.rb`, `SessionsController`, `RegistrationsController`, `ProfilesController`. Avatars via Active Storage variants (`User#avatar`, `thumb`/`medium`) with an initials fallback (`User#initials`). No 2FA out of the box — see README's "Adding 2FA later" for the rotp path.
- AI chat: RubyLLM `acts_as_chat`-generated models (`Chat`, `Message`, `ToolCall`, `Model`), scoped per user through `Current.user`. `ChatResponseJob` streams the assistant response and, only after it persists, enqueues `GenerateChatTitleJob` (event-driven, race-safe — it never runs before the first message exists). Titling uses `RubyLLM.chat.with_schema(ChatTitleSchema)` (`app/schemas/chat_title_schema.rb`, a Schematist schema).
- Semantic search: `Document` (`semantic_search`, `EMBEDDING_DIMENSIONS = 1536`) enqueues `GenerateDocumentEmbeddingJob` from an `after_save_commit` callback guarded by `saved_change_to_embedding?` (avoids re-embedding loops), `config/initializers/neighbor.rb` calling `Neighbor::SQLite.initialize!` (sqlite-vec extension).
- Rich text: Action Text + Lexxy (`import "lexxy"` in `app/javascript/application.js`, manual `pin "lexxy"` in `config/importmap.rb`, `stylesheet_link_tag "lexxy"` in the layout). On Rails 8.1, Lexxy falls back to monkey-patching `rich_text_area`/`rich_textarea` instead of using the official `ActionText::Editor` adapter API (merged later in Rails). Re-verify `Lexxy.supports_editor_adapter?` after any Rails upgrade — the rendered `<lexxy-editor>` tag should stay the same either way, but re-run the Lexxy system test to confirm.
- Console auditing: console1984 records production console sessions/commands and requires Active Record encryption (keys live in `config/credentials.yml.enc`, generated via `bin/rails db:encryption:init`). See README's Console auditing and Quickstart sections — new apps must regenerate their own credentials, since `config/master.key` never travels with the repo.
- Error tracking: Solid Errors subscribes to `Rails.error` (`config/initializers/solid_errors.rb`) and persists deduplicated exceptions to the primary DB (`solid_errors`/`solid_errors_occurrences`, migrated normally — no separate database). Dashboard mounted at `/errors` (`config/routes.rb`), protected by HTTP basic auth independent of session auth: username/password/`email_to` resolve from `Rails.application.credentials.dig(:solid_errors, ...)` first, `ENV["SOLID_ERRORS_USERNAME"]`/`PASSWORD`/`EMAIL_TO` second. Auth is gated on password alone (`http_basic_authenticate_with ... if SolidErrors.password`) — a username with no password leaves `/errors` open, so set both before production. The gem also checks its own `ENV["SOLIDERRORS_USERNAME"]`/`PASSWORD` (no underscore between "SOLID" and "ERRORS") ahead of everything this app configures — avoid setting those exact names unless you want them to win silently. Email notification only fires when `email_to` resolves. See README's Error tracking section.
- User feedback: `Feedback` (`belongs_to :user`, `has_many_attached :photos`) always persists locally via `FeedbacksController#create` (`/feedback`, linked from the navbar dropdown). `after_create_commit` enqueues `CreateFeedbackIssueJob`, which no-ops unless `GithubIssues.configured?` (both `GITHUB_ISSUES_TOKEN` and `GITHUB_ISSUES_REPO` set) and otherwise POSTs a labeled (`feedback`) issue to `https://api.github.com/repos/#{repo}/issues` via `GithubIssues` (`app/models/github_issues.rb`, plain `Net::HTTP`, no new gem, `X-GitHub-Api-Version: 2022-11-28`). A non-2xx response raises, so Solid Queue retries and Solid Errors captures exhausted failures. Photos are linked in the issue body through the permanent public route `/feedback/photos/:signed_id` (`FeedbackPhotosController`), which only redirects to blobs actually attached to a `Feedback#photos` — never an open blob proxy. See README's "User feedback" section.
- Deploy: `config/deploy.yml` (placeholders in UPPERCASE; `storage/` volume is mandatory for SQLite + Active Storage).
