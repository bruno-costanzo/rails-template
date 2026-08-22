# Charco Template — Design Spec

**Date:** 2026-08-19
**Status:** Approved design, pending implementation plan

## Purpose

A reusable Rails starter template for building many small Rails + AI applications quickly. The template is a complete, working, tested Rails application hosted as a GitHub "Template repository". New apps are created by cloning it and running `bin/rename`. Apps do not receive updates after creation; the template itself evolves over time and its own test suite verifies every improvement.

## Versions

- Ruby 4.0.6 (managed with mise, pinned in `.ruby-version`)
- Rails 8.1.3.1
- RubyLLM 1.16+ (installed and upgraded via its official generators)
- DaisyUI 5 (vendored `.mjs` plugin files, no Node)

## Core stack

- **Database:** SQLite in all environments, including production. Solid Queue (jobs), Solid Cache, and Solid Cable run on SQLite. No Redis, no Postgres, no external services.
- **Assets:** Propshaft + Importmap. No Node, no JS bundler.
- **CSS:** tailwindcss-rails (Tailwind v4 standalone CLI) + DaisyUI 5 installed via the official no-Node method: `daisyui.mjs` and `daisyui-theme.mjs` vendored in `app/assets/tailwind/`, registered in `application.css` with:

  ```css
  @import "tailwindcss";
  @source not "./daisyui{,*}.mjs";
  @plugin "./daisyui.mjs";
  ```

- **Frontend:** Hotwire (Turbo + Stimulus).
- **Naming:** the app module is `CharcoTemplate`. A `bin/rename` script renames the module, database names, and config identifiers when starting a new app. This script is the only template-specific tooling.
- **Setup:** `bin/setup` leaves the app running with one command.

## Authentication and users

Base: the native Rails 8 authentication generator (`bin/rails generate authentication`), which provides `User` (email_address + password_digest), DB-backed `Session` records, the `Authentication` controller concern, `Current` (request context), session controller, and password reset by email.

Added on top (all TDD):

1. **Registration** — `RegistrationsController` (sign up + auto sign in), with controller and system tests.
2. **Profile** — a screen to edit name, email address, password, and avatar.
3. **Avatar** — `has_one_attached :avatar` on `User`, variants `thumb` (48px) and `medium` (200px) via image_processing/libvips. Validations (content type, size) with the `active_storage_validations` gem.
4. **Avatar fallback** — DaisyUI `avatar placeholder` component with the user's initials. No image generation, no external services.
5. **2FA** — not included; README documents the path (rotp gem over the owned controllers).

## AI layer

- **RubyLLM** — installed with `ruby_llm:install` (models `Chat`, `Message`, `ToolCall`, `Model` + initializer). Configured for **OpenAI only** (`OPENAI_API_KEY` via ENV; dotenv-rails in development). Chat UI generated with `ruby_llm:chat_ui` (Turbo streaming, model selector), then restyled with DaisyUI and scoped to the signed-in user (`Chat belongs_to :user`).
- **Schematist** — one structured-output example: `ChatTitleSchema` in `app/schemas/` (title + tags), used with `chat.with_schema(...)` to auto-name conversations.
- **Neighbor + SQLite** — the `sqlite-vec` extension loaded through `database.yml` `extensions:` (Rails 8 native support, per Neighbor's SQLite docs). Example model `Document` with an `embedding` column generated in a Solid Queue job calling `RubyLLM.embed` on save. `Document.semantic_search(query)` uses `nearest_neighbors`. A minimal search screen demonstrates it.
- **Lexxy** — Action Text installed; Lexxy replaces Trix. `Document#content` is rich text edited with Lexxy. One model demonstrates Lexxy + Active Storage attachments + `to_plain_text` extraction feeding Neighbor embeddings.
- **Testing** — tests never call OpenAI. WebMock stubs all LLM HTTP calls (chat and embeddings). CI needs no API keys.

## Landing, SEO, PWA

- **Landing** — public root (`allow_unauthenticated_access`): navbar, hero, features, footer built with DaisyUI components. Generic English copy meant to be replaced per app.
- **meta-tags** — initializer with site defaults (title, description, Open Graph, Twitter cards); `set_meta_tags` on the landing as the per-page example.
- **PWA** — Rails 8's generated `app/views/pwa/` activated: routes uncommented, complete manifest with icons and installability. Minimal service worker; caching strategies are per-app decisions.

## UI feedback: confirmations and flash messages

- **Confirmations** — the native browser `confirm()` dialog is replaced globally via Turbo's confirm hook (`Turbo.config.forms.confirm`) with a DaisyUI `modal` (`<dialog>`) rendered from a shared partial in the layout. Existing and future `data: { turbo_confirm: "..." }` buttons keep working unchanged — the replacement happens in one place.
- **Flash messages** — rendered as DaisyUI toasts from a single `shared/_flash` partial in the layout: responsive positioning, dismiss button, and auto-dismiss (~5 seconds) via a small Stimulus controller. The duplicated inline flash rendering in the auth views (sessions/passwords) is removed.
- Both flows are covered by system tests (confirm/cancel on a destroy action; flash toast on a failed login).

## Money

- **money-rails** installed by default with its official initializer (`config/initializers/money.rb`), `default_currency = :usd`. No monetized example model ships — apps add `monetize :price_cents` when they need it (README documents the `t.monetize` migration pattern). A small behavior test verifies the wiring (default currency and formatting), so a broken initializer or missing gem fails the suite.

## Icons

- **Lucide** — inline SVG icons via the `lucide-rails` gem, rendered through the gem's helper as the template convention. No icon font, no CDN: only the icons actually used ship with the page, they inherit `currentColor` (dark mode for free), and there is no font flash. Ad-hoc inline SVGs in the template's own views are replaced with the helper; README documents the convention for child apps.

## Error tracking and user feedback

- **Solid Errors** — errors are captured via Rails' native error reporter, stored in SQLite, and deduplicated by fingerprint by the `solid_errors` gem (consistent with the Solid Queue/Cache/Cable philosophy: no external services). Its web dashboard is mounted at `/errors`, protected with HTTP basic auth whose credentials live in Rails credentials — independent of the app's session auth, so it survives per-app login changes. Email notification on new errors goes to an address configured in credentials; when absent, notifications are off and the dashboard still works.
- **User feedback → GitHub Issues** — a `Feedback` model (message + optional photos via Active Storage) with a DaisyUI form for signed-in users. Submissions are stored locally and a Solid Queue job creates a GitHub issue (label `feedback`) in the app's repo via the REST API with plain `Net::HTTP` — no new gems. Configured per app with `GITHUB_ISSUES_TOKEN` (fine-grained, issues: write) and `GITHUB_ISSUES_REPO`; when unset the job is silently skipped and feedback still persists locally. Photos are linked in the issue body through a permanent public route served by the app (the GitHub API cannot host image uploads). A "capture screenshot automatically" button is documented as a future extension, not built.
- Tests never hit the network: GitHub API calls are WebMock-stubbed; Solid Errors behavior is tested through Rails' error reporter against the local database.
- **AI support assistant** — a floating support button (DaisyUI, bottom corner) for signed-in users opens a support chat backed by a RubyLLM agent. The agent converses with the person, refines their problem or suggestion, and files it through a `RubyLLM::Tool` that creates a `Feedback` record — reusing the whole Task 22 pipeline (local persistence always; GitHub issue with the `feedback` label when configured). The agent knows the application through `config/support_context.md`, a human-friendly per-app description maintained by the app's developer; the template ships a placeholder. Support conversations reuse the existing RubyLLM `Chat` infrastructure (streaming via the existing response job) flagged as support chats and excluded from the normal chat list.
- **Binding rule for the support assistant:** nothing the person sees may ever contain code, file names, stack traces, class names, or any technical internals — user-facing output is human-friendly only. Enforced in depth: (1) the system prompt states the rule explicitly; (2) `config/support_context.md` is by convention non-technical, so the agent has no internals to leak; (3) the refined issue the tool files is written for the developer, but the chat reply confirming it stays in plain human language.
- **Support agent implementation** — the support agent is a `RubyLLM::Agent` subclass (the gem's official agent API: class-level `instructions`/`tools`, `chat_model "Chat"`), not ad-hoc per-job chat configuration. `config/support_context.md` ships with guided sections — what the app does, common problems, and what to ask per report type — all human-friendly by convention.
- **Ticket context** — the support widget captures the page URL, browser, and viewport when opened; the filed ticket carries them into the trusted metadata section of the GitHub issue body. People can attach images in the support chat (same validation rules as feedback photos); they end up attached to the `Feedback` and linked in the issue. Automatic screenshot capture stays a documented future extension.
- **Ticket lifecycle** — `Feedback` gains `status` (`open`/`resolved`) and `resolved_at`. A minimal `/admin/feedbacks` panel behind credentials-based HTTP basic auth (same lookup pattern as Solid Errors, but denying access entirely when no credentials are configured) lists open tickets with their context and photos and marks them resolved. No notification is sent on resolution. Ticket state lives in the app; the GitHub issue is an unsynced working mirror.

## Deployment

- **Kamal** — `config/deploy.yml` documented with placeholders (server, registry) and `.kamal/secrets` for keys. A **persistent volume mounts `storage/`** (SQLite databases + Active Storage files survive deploys). Thruster ships in the Rails 8 Dockerfile.

## Production console auditing

- **console1984** — Basecamp's audited Rails console. Gem installed, its migrations run (console session/command trail tables), default protection (production only). Requires Active Record encryption: the template runs `bin/rails db:encryption:init` and stores the keys in credentials. Because `config/master.key` never travels with the repo, the README instructs each new app to regenerate credentials (`rm config/credentials.yml.enc && bin/rails credentials:edit`) and re-run `db:encryption:init`, pasting the fresh keys. Companion tool `audits1984` is documented as optional, not installed.

## Notifications

- **noticed (v2) is the entire notifications layer** — no other notification gem or service. The template ships the *capability*, not any notification: `noticed` installed with its migrations (`noticed_events`/`noticed_notifications` on SQLite), an `ApplicationNotifier < Noticed::Event` base class, and a navbar bell (DaisyUI dropdown: unread badge, list, mark-as-read) that renders whatever notifications exist — empty until a child app creates its first notifier. Creating a notification in a child app is one notifier class; the README documents the recipe. Tests exercise the full pipeline with a notifier that lives only under `test/`.
- **Channels**: in-app (database) works out of the box; email delivery uses noticed's built-in `:email` delivery method as a documented, per-notifier opt-in pattern (previewable in `/letter_opener` in development). Web push and mobile push are documented future channels: browser push requires the `web-push` gem for VAPID crypto (deliberately not installed — nothing beyond noticed ships today), and mobile uses noticed's built-in FCM/APNS delivery methods when an app needs them.
- **Binding rule for implementation:** the noticed v2 documentation and installed gem source are read before any code is written — v2 is a rewrite; v1 memory is not trusted.

## Development email preview

- **letter_opener_web** — in development, Action Mailer delivers to a browsable inbox mounted at `/letter_opener` instead of sending real email. Covers password resets, Solid Errors notifications, and any mail a child app adds. Development-only gem and route; test and production behavior unchanged.

## Testing and CI

- Minitest + fixtures; system tests with headless Capybara; WebMock for AI.
- The template is built test-first, and the README declares TDD as the convention for child apps.
- **The suite is deterministic.** A flaky test is a bug: it gets a root-cause diagnosis and a real fix — never sleeps, in-test retries, or weakened assertions. `bin/ci` green must mean green every time, locally and in CI.
- **N+1 queries fail the suite.** The `bullet` gem runs in development (Rails log + browser console warnings while navigating) and in test with `Bullet.raise = true`: any N+1, unnecessary eager load, or missing counter cache on a test-exercised path is a red test. False positives go to a documented safelist, never silenced by loosening the mode.

## Quality gate: bin/ci and 100% coverage

- **`bin/ci`** is the single quality gate: RuboCop → Brakeman → `bin/rails test` (with coverage enforcement) → `bin/rails test:system`. The GitHub Actions workflow runs `bin/ci`, so local and CI verification are identical and CI must pass.
- **Coverage rule:** SimpleCov with branch coverage enabled enforces **100% line AND 100% branch coverage** over `app/` and `lib/`, failing the test run below that. Coverage is measured on the unit/integration run; system tests run in `bin/ci` but are excluded from measurement. Unreachable code is deleted rather than excluded; `# :nocov:` markers are not used.
- **Binding conventions, documented:** CLAUDE.md and README state the rules any human or AI working on a child app must follow: TDD always, 100% line+branch coverage, `bin/ci` green before commit/push.

## AI-assistant files

- `CLAUDE.md` at the root: full stack description, conventions (TDD, English-only, no code comments, DaisyUI components before custom CSS), commands (`bin/dev`, `bin/rails test`), and how each subsystem is wired.
- `AGENTS.md` with the same content for other AI tools.
- No skills/agents shipped initially; added later if real usage demands them.

## Documentation

README in English: quickstart, `bin/rename`, Kamal deploy, and an "Updating this template" section covering Rails/gem upgrades, re-downloading DaisyUI `.mjs` files, and running RubyLLM's official upgrade generators.

## Out of scope

- Multi-tenancy, roles/authorization (Pundit), OAuth, 2FA (documented only), notifications, pagination, payment — all per-app decisions.
- Any provider other than OpenAI.
- Update mechanism for already-created apps.
