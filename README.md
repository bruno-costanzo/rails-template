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
- Tailwind v4 + DaisyUI 5 (vendored, no Node/npm needed), Hotwire (Turbo + Stimulus)
- Kamal deployment configuration ready to point at your own server

## Requirements

- [mise](https://mise.jdx.dev) (or another way to install Ruby 4.0.6 matching `.ruby-version`)
- Ruby 4.0.6
- libvips (used by Active Storage's `image_processing` gem for avatar variants)
- An OpenAI API key (for the AI chat and semantic search features)

## Quickstart

```bash
git clone <this-repo> my_app
cd my_app
bin/rename my_app
bin/setup
```

New apps need their own credentials — `config/master.key` is gitignored on purpose and never travels with the repo, and console1984 depends on Active Record encryption keys that live inside `config/credentials.yml.enc`. Before running the app for real, regenerate both:

```bash
rm config/credentials.yml.enc
mise exec ruby@4.0.6 -- bin/rails credentials:edit
```

This creates a fresh `master.key` and an empty encrypted credentials file, and opens it in your editor. Then generate new Active Record encryption keys:

```bash
mise exec ruby@4.0.6 -- bin/rails db:encryption:init
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

```bash
mise exec ruby@4.0.6 -- bin/rails test
mise exec ruby@4.0.6 -- bin/rails test:system
```

Tests never hit the network. `test/test_helper.rb` calls `WebMock.disable_net_connect!(allow_localhost: true)`, so any real HTTP call from a test fails loudly instead of silently reaching OpenAI. Stub RubyLLM calls with the helpers in `test/test_helpers/openai_stubs.rb`:

- `stub_openai_chat(content:)` — stubs a chat completion
- `stub_openai_embedding(vector:)` — stubs an embedding request

## Console auditing

console1984 protects and audits the Rails console in production. Every console session and every command run inside it is recorded to the database (`console1984_sessions`, `console1984_commands` tables), and by default only the `production` environment is protected — development and test consoles are unrestricted. This requires Active Record encryption to be configured (see the Quickstart's credentials step above). If you want a web UI for browsing the audit trail, console1984's companion gem [`audits1984`](https://github.com/basecamp/audits1984) is not installed by default but can be added later.

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
4. Run the full suite (`mise exec ruby@4.0.6 -- bin/rails test` and `mise exec ruby@4.0.6 -- bin/rails test:system`) before committing the upgrade.

Also worth re-checking after a Rails upgrade: whether Lexxy still needs to monkey-patch `rich_text_area` (see `CLAUDE.md`'s Subsystem map) — a new Rails version may ship the official `ActionText::Editor` adapter API Lexxy prefers.
