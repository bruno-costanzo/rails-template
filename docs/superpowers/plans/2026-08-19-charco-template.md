# Charco Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, tested Rails starter template (working app + GitHub template repo) with landing page, native auth, avatars, RubyLLM/Schematist/Neighbor AI layer, Lexxy rich text, PWA, meta-tags, Kamal deploy, and AI-assistant docs.

**Architecture:** The template IS a runnable Rails app named `CharcoTemplate`. Official generators do the heavy lifting (Rails auth, RubyLLM install/chat_ui, Action Text, neighbor:sqlite); our own code is limited to registration, profile/avatar, landing, one `Document` example model wiring Lexxy + Active Storage + Neighbor, a chat-title Schematist example, and `bin/rename`.

**Tech Stack:** Ruby 4.0.6, Rails 8.1.3.1, SQLite (+ Solid Queue/Cache/Cable), Propshaft, Importmap, Tailwind v4 + DaisyUI 5 (vendored .mjs, no Node), Hotwire, Minitest + WebMock, Kamal.

**Spec:** `docs/superpowers/specs/2026-08-19-charco-template-design.md`

## Global Constraints

- Ruby exactly 4.0.6; Rails exactly 8.1.3.1.
- SQLite everywhere; no Redis/Postgres/Node.
- All code, comments-free (user rule: never write code comments), English-only identifiers and copy.
- TDD for every piece of our own code: failing test first, then implementation.
- Commits: short imperative messages. NEVER add Co-Authored-By or any co-author trailer (user rule).
- No inline styles; DaisyUI component classes before custom CSS.
- Tests must never reach the network: WebMock blocks all HTTP except localhost.
- LLM provider is OpenAI only: chat `gpt-4o-mini`, embeddings `text-embedding-3-small` (1536 dimensions).
- Working directory: `/Users/brunocostanzo/Developer/charco_template` (git repo already initialized, spec committed, `.gitignore` has two `!docs/superpowers/` negation lines that MUST survive `rails new`).

---

### Task 1: Toolchain and app generation

**Files:**
- Create: entire Rails app skeleton via `rails new` (in place)
- Modify: `.gitignore` (re-append negation lines + `.env`)

**Interfaces:**
- Produces: app module `CharcoTemplate`, standard Rails 8.1 layout, `bin/setup`, `bin/dev`, Solid gems, Dockerfile, `config/deploy.yml`, `.github/workflows/ci.yml`, PWA stubs.

- [ ] **Step 1: Install toolchain**

```bash
mise install ruby@4.0.6
mise exec ruby@4.0.6 -- gem install rails -v 8.1.3.1
```

Run: `mise exec ruby@4.0.6 -- rails -v` — Expected: `Rails 8.1.3.1`

- [ ] **Step 2: Generate the app in place**

```bash
cd /Users/brunocostanzo/Developer/charco_template
mise exec ruby@4.0.6 -- rails new . --css=tailwind --skip-jbuilder --force
```

`--force` overwrites our two-line `.gitignore`; restored next step. Expected: app generated, `bundle install` and `tailwindcss:install` run automatically.

- [ ] **Step 3: Restore .gitignore additions**

Append to `.gitignore`:

```
!docs/superpowers/
!docs/superpowers/**
.env
```

- [ ] **Step 4: Verify baseline**

```bash
cat .ruby-version
bin/rails runner "puts Rails.version"
bin/rails test
```

Expected: `4.0.6`, `8.1.3.1`, test run finishes green (0 or few tests).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "Generate Rails 8.1.3.1 app skeleton"
```

---

### Task 2: DaisyUI + landing page + meta-tags

**Files:**
- Create: `app/assets/tailwind/daisyui.mjs`, `app/assets/tailwind/daisyui-theme.mjs`, `app/controllers/pages_controller.rb`, `app/views/pages/home.html.erb`, `app/views/shared/_navbar.html.erb`, `config/initializers/meta_tags.rb`, `test/system/landing_test.rb`, `test/controllers/pages_controller_test.rb`
- Modify: `app/assets/tailwind/application.css`, `app/views/layouts/application.html.erb`, `config/routes.rb`, `Gemfile`

**Interfaces:**
- Produces: `root` → `pages#home`; partial `shared/_navbar` rendered by the layout (later tasks add auth-aware links to it); `display_meta_tags` in layout.

- [ ] **Step 1: Install DaisyUI (no Node method)**

```bash
curl -sLo app/assets/tailwind/daisyui.mjs https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.mjs
curl -sLo app/assets/tailwind/daisyui-theme.mjs https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.mjs
```

Replace `app/assets/tailwind/application.css` content with:

```css
@import "tailwindcss";
@source not "./daisyui{,*}.mjs";
@plugin "./daisyui.mjs";
```

- [ ] **Step 2: Add meta-tags gem**

```bash
bundle add meta-tags
bin/rails generate meta_tags:install
```

In `config/initializers/meta_tags.rb` set: `config.title_limit = 70` (leave rest default). Site defaults go in the layout call below.

- [ ] **Step 3: Write failing tests**

`test/controllers/pages_controller_test.rb`:

```ruby
require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home is public and renders meta title" do
    get root_url
    assert_response :success
    assert_select "title", "Home | CharcoTemplate"
  end
end
```

`test/system/landing_test.rb`:

```ruby
require "application_system_test_case"

class LandingTest < ApplicationSystemTestCase
  test "visitor sees hero and call to action" do
    visit root_url
    assert_selector "h1", text: "Build your next idea faster"
    assert_link "Get started"
  end
end
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `bin/rails test test/controllers/pages_controller_test.rb` — Expected: FAIL (no route).

- [ ] **Step 5: Implement**

`config/routes.rb`: `root "pages#home"`

`app/controllers/pages_controller.rb`:

```ruby
class PagesController < ApplicationController
  def home
  end
end
```

`app/views/pages/home.html.erb`:

```erb
<% set_meta_tags title: "Home", description: "A Rails starter template with AI batteries included" %>
<div class="hero bg-base-200 min-h-[70vh]">
  <div class="hero-content text-center">
    <div class="max-w-xl">
      <h1 class="text-5xl font-bold">Build your next idea faster</h1>
      <p class="py-6">Rails, SQLite, Hotwire, DaisyUI and an AI toolkit ready on day one.</p>
      <%= link_to "Get started", "#", class: "btn btn-primary" %>
    </div>
  </div>
</div>
<div class="grid gap-6 md:grid-cols-3 p-10">
  <% [["Authentication", "Sessions, registration and profiles out of the box."],
      ["AI toolkit", "RubyLLM chat, structured outputs and semantic search."],
      ["One-command deploy", "Kamal ships it to any server with SQLite persistence."]].each do |title, body| %>
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title"><%= title %></h2>
        <p><%= body %></p>
      </div>
    </div>
  <% end %>
</div>
```

`app/views/shared/_navbar.html.erb`:

```erb
<div class="navbar bg-base-100 shadow-sm">
  <div class="flex-1">
    <%= link_to "CharcoTemplate", root_path, class: "btn btn-ghost text-xl" %>
  </div>
  <div class="flex-none gap-2">
  </div>
</div>
```

Layout `app/views/layouts/application.html.erb`: replace the `<title>` tags block with `<%= display_meta_tags site: "CharcoTemplate", reverse: true %>`, and in `<body>` add `<%= render "shared/navbar" %>` above `<%= yield %>`, plus a flash block:

```erb
<% flash.each do |type, message| %>
  <div class="alert <%= type == "alert" ? "alert-error" : "alert-info" %> m-4"><%= message %></div>
<% end %>
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/pages_controller_test.rb && bin/rails test:system` — Expected: PASS. Also `bin/rails tailwindcss:build && grep -c "daisyui" app/assets/builds/tailwind.css` — Expected: ≥ 1.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "Add DaisyUI, meta-tags and landing page"
```

---

### Task 3: Native authentication

**Files:**
- Create: via `bin/rails generate authentication` (User, Session, Current, Authentication concern, SessionsController, PasswordsController, mailer, views, migrations)
- Modify: `app/controllers/pages_controller.rb`, `test/fixtures/users.yml`, `app/views/shared/_navbar.html.erb`
- Test: `test/controllers/sessions_controller_test.rb`, `test/test_helpers/session_test_helper.rb`

**Interfaces:**
- Produces: `Current.user`, `allow_unauthenticated_access`, `start_new_session_for(user)`, `after_authentication_url`, routes `new_session_url`, `session_url`; fixtures `users(:one)` (Ada) and `users(:two)` (Grace), password `"password"`; helper `sign_in_as(user)` for integration tests.

- [ ] **Step 1: Run the generator and migrate**

```bash
bin/rails generate authentication
bin/rails db:migrate
```

- [ ] **Step 2: Keep the landing public**

`app/controllers/pages_controller.rb`, first line inside class: `allow_unauthenticated_access`

- [ ] **Step 3: Normalize fixtures**

Overwrite `test/fixtures/users.yml`:

```yaml
one:
  email_address: ada@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

two:
  email_address: grace@example.com
  password_digest: <%= BCrypt::Password.create("password") %>
```

- [ ] **Step 4: Add sign-in test helper**

`test/test_helpers/session_test_helper.rb`:

```ruby
module SessionTestHelper
  def sign_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
```

In `test/test_helper.rb`, after the requires: `Dir[Rails.root.join("test/test_helpers/**/*.rb")].each { |f| require f }` and inside `ActiveSupport::TestCase`... actually include where needed per test class (integration tests include it explicitly).

- [ ] **Step 5: Write the session flow test**

`test/controllers/sessions_controller_test.rb`:

```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "signs in with valid credentials" do
    sign_in_as users(:one)
    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "rejects invalid credentials" do
    post session_url, params: { email_address: "ada@example.com", password: "wrong" }
    assert_redirected_to new_session_url
  end

  test "signs out" do
    sign_in_as users(:one)
    delete session_url
    assert_redirected_to new_session_url
    assert cookies[:session_id].blank?
  end
end
```

- [ ] **Step 6: Run the suite**

Run: `bin/rails test` — Expected: PASS. If a redirect target differs, read the generated `SessionsController` and fix the TEST to match generated behavior (the generator is the source of truth here).

- [ ] **Step 7: Update navbar with session links**

In `app/views/shared/_navbar.html.erb` `flex-none` div:

```erb
<% if authenticated? %>
  <%= button_to "Sign out", session_path, method: :delete, class: "btn btn-ghost" %>
<% else %>
  <%= link_to "Sign in", new_session_path, class: "btn btn-ghost" %>
<% end %>
```

`authenticated?` is a helper from the generated concern. Landing test still passes (`Get started` link untouched).

- [ ] **Step 8: Run full suite and commit**

```bash
bin/rails test test:system
git add -A && git commit -m "Add native Rails authentication"
```

---

### Task 4: Registration with name

**Files:**
- Create: `db/migrate/*_add_name_to_users.rb`, `app/controllers/registrations_controller.rb`, `app/views/registrations/new.html.erb`
- Modify: `app/models/user.rb`, `config/routes.rb`, `test/fixtures/users.yml`, `app/views/pages/home.html.erb` (Get started → signup), `app/views/shared/_navbar.html.erb`
- Test: `test/controllers/registrations_controller_test.rb`, `test/models/user_test.rb`

**Interfaces:**
- Produces: `User#name` (required), routes `new_registration_url` / `registration_url`; fixtures gain `name:` keys (`Ada Lovelace`, `Grace Hopper`).

- [ ] **Step 1: Write failing tests**

`test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a name" do
    user = User.new(name: "", email_address: "new@example.com", password: "password")
    assert_not user.valid?
    assert user.errors[:name].any?
  end
end
```

`test/controllers/registrations_controller_test.rb`:

```ruby
require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the sign up form" do
    get new_registration_url
    assert_response :success
  end

  test "creates a user and starts a session" do
    assert_difference("User.count") do
      post registration_url, params: { user: { name: "Joan Clarke", email_address: "joan@example.com",
        password: "password1234", password_confirmation: "password1234" } }
    end
    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "re-renders on invalid data" do
    assert_no_difference("User.count") do
      post registration_url, params: { user: { name: "", email_address: "bad", password: "x", password_confirmation: "y" } }
    end
    assert_response :unprocessable_entity
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/rails test test/controllers/registrations_controller_test.rb` — Expected: FAIL (no route `new_registration_url`).

- [ ] **Step 3: Implement**

```bash
bin/rails generate migration AddNameToUsers name:string
bin/rails db:migrate
```

`app/models/user.rb` — add:

```ruby
validates :name, presence: true
validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :password, length: { minimum: 8 }, allow_nil: true
```

`config/routes.rb`: `resource :registration, only: %i[new create]`

`app/controllers/registrations_controller.rb`:

```ruby
class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      redirect_to root_url, notice: "Welcome!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
  end
end
```

`app/views/registrations/new.html.erb`:

```erb
<% set_meta_tags title: "Sign up" %>
<div class="flex justify-center py-16">
  <div class="card bg-base-100 shadow w-full max-w-md">
    <div class="card-body">
      <h1 class="card-title">Create your account</h1>
      <%= form_with model: @user, url: registration_path do |form| %>
        <% if @user.errors.any? %>
          <div class="alert alert-error mb-4"><%= @user.errors.full_messages.to_sentence %></div>
        <% end %>
        <%= form.label :name, class: "label" %>
        <%= form.text_field :name, class: "input input-bordered w-full", required: true %>
        <%= form.label :email_address, class: "label" %>
        <%= form.email_field :email_address, class: "input input-bordered w-full", required: true %>
        <%= form.label :password, class: "label" %>
        <%= form.password_field :password, class: "input input-bordered w-full", required: true %>
        <%= form.label :password_confirmation, class: "label" %>
        <%= form.password_field :password_confirmation, class: "input input-bordered w-full", required: true %>
        <%= form.submit "Sign up", class: "btn btn-primary w-full mt-4" %>
      <% end %>
    </div>
  </div>
</div>
```

Fixtures: add `name: Ada Lovelace` to `one:` and `name: Grace Hopper` to `two:`.
Landing: point `Get started` to `new_registration_path`. Navbar signed-out branch: add `<%= link_to "Sign up", new_registration_path, class: "btn btn-primary" %>`.

- [ ] **Step 4: Run full suite**

Run: `bin/rails test test:system` — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "Add user registration"
```

---

### Task 5: Avatars and profile

**Files:**
- Create: `app/controllers/profiles_controller.rb`, `app/views/profiles/edit.html.erb`, `app/views/users/_avatar.html.erb`, `test/fixtures/files/avatar.png`
- Modify: `Gemfile` (uncomment `image_processing`, add `active_storage_validations`), `app/models/user.rb`, `config/routes.rb`, `app/views/shared/_navbar.html.erb`
- Test: `test/models/user_test.rb` (extend), `test/controllers/profiles_controller_test.rb`

**Interfaces:**
- Produces: `User#avatar` (variants `:thumb` 48×48, `:medium` 200×200), `User#initials`, partial `users/avatar` (local: `user`), routes `edit_profile_url` / `profile_url`.

- [ ] **Step 1: Install dependencies**

```bash
bin/rails active_storage:install
bin/rails db:migrate
bundle add active_storage_validations
```

Uncomment `gem "image_processing"` in the Gemfile, then `bundle install`.

- [ ] **Step 2: Create image fixture**

```bash
mkdir -p test/fixtures/files
base64 -d > test/fixtures/files/avatar.png <<< "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
```

- [ ] **Step 3: Write failing tests**

Append to `test/models/user_test.rb`:

```ruby
test "initials come from the first two name words" do
  assert_equal "AL", users(:one).initials
end

test "accepts a png avatar" do
  user = users(:one)
  user.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "avatar.png", content_type: "image/png")
  assert user.valid?
end

test "rejects a non-image avatar" do
  user = users(:one)
  user.avatar.attach(io: StringIO.new("plain text"), filename: "notes.txt", content_type: "text/plain")
  assert_not user.valid?
end
```

`test/controllers/profiles_controller_test.rb`:

```ruby
require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get edit_profile_url
    assert_redirected_to new_session_url
  end

  test "updates name and avatar" do
    sign_in_as users(:one)
    patch profile_url, params: { user: { name: "Ada King", avatar: fixture_file_upload("avatar.png", "image/png") } }
    assert_redirected_to edit_profile_url
    assert_equal "Ada King", users(:one).reload.name
    assert users(:one).avatar.attached?
  end

  test "ignores blank password fields" do
    sign_in_as users(:one)
    patch profile_url, params: { user: { name: "Ada King", password: "", password_confirmation: "" } }
    assert_redirected_to edit_profile_url
  end
end
```

Run: `bin/rails test test/models/user_test.rb` — Expected: FAIL (`initials` undefined).

- [ ] **Step 4: Implement**

`app/models/user.rb` — add:

```ruby
has_one_attached :avatar do |attachable|
  attachable.variant :thumb, resize_to_fill: [ 48, 48 ]
  attachable.variant :medium, resize_to_fill: [ 200, 200 ]
end

validates :avatar, content_type: %w[image/png image/jpeg image/webp], size: { less_than: 5.megabytes }

def initials
  name.to_s.split.first(2).filter_map { |part| part[0] }.join.upcase
end
```

`config/routes.rb`: `resource :profile, only: %i[edit update]`

`app/controllers/profiles_controller.rb`:

```ruby
class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    if @user.update(profile_params)
      redirect_to edit_profile_url, notice: "Profile updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    permitted = params.expect(user: [ :name, :email_address, :avatar, :password, :password_confirmation ])
    permitted.delete(:password) if permitted[:password].blank?
    permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
    permitted
  end
end
```

`app/views/users/_avatar.html.erb`:

```erb
<% if user.avatar.attached? %>
  <div class="avatar">
    <div class="w-12 rounded-full">
      <%= image_tag user.avatar.variant(:thumb), alt: user.name %>
    </div>
  </div>
<% else %>
  <div class="avatar avatar-placeholder">
    <div class="bg-neutral text-neutral-content w-12 rounded-full">
      <span><%= user.initials %></span>
    </div>
  </div>
<% end %>
```

`app/views/profiles/edit.html.erb`: same card/form pattern as registration, fields `name`, `email_address`, `avatar` (`form.file_field :avatar, class: "file-input file-input-bordered w-full"`), `password`, `password_confirmation`, submit `Save`, and `<%= render "users/avatar", user: @user %>` at the top.

Navbar signed-in branch — replace with a DaisyUI dropdown:

```erb
<div class="dropdown dropdown-end">
  <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
    <%= render "users/avatar", user: Current.user %>
  </div>
  <ul tabindex="0" class="menu dropdown-content bg-base-100 rounded-box z-10 mt-3 w-52 p-2 shadow">
    <li><%= link_to "Profile", edit_profile_path %></li>
    <li><%= button_to "Sign out", session_path, method: :delete %></li>
  </ul>
</div>
```

- [ ] **Step 5: Run full suite**

Run: `bin/rails test test:system` — Expected: PASS (variants need libvips: `brew install vips` if missing).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "Add avatars and profile editing"
```

---

### Task 6: PWA activation

**Files:**
- Modify: `config/routes.rb` (uncomment PWA routes), `app/views/pwa/manifest.json.erb`, `app/views/layouts/application.html.erb` (uncomment manifest link tag)
- Test: `test/integration/pwa_test.rb`

- [ ] **Step 1: Write failing test**

`test/integration/pwa_test.rb`:

```ruby
require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "serves the manifest publicly" do
    get pwa_manifest_path(format: :json)
    assert_response :success
    assert_equal "CharcoTemplate", JSON.parse(response.body)["name"]
  end

  test "serves the service worker publicly" do
    get pwa_service_worker_path(format: :js)
    assert_response :success
  end
end
```

Run: `bin/rails test test/integration/pwa_test.rb` — Expected: FAIL (undefined route).

- [ ] **Step 2: Implement**

In `config/routes.rb` uncomment:

```ruby
get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
```

In `app/views/pwa/manifest.json.erb` set `"name": "CharcoTemplate"`, `"theme_color"`/`"background_color"` to `"#1d232a"`, keep generated icon entries. In the layout, uncomment the manifest link line. Run test — Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "Activate PWA manifest and service worker"
```

---

### Task 7: RubyLLM install + test stubs

**Files:**
- Create: `config/initializers/ruby_llm.rb` (via generator, then edited), `.env.example`, `test/test_helpers/openai_stubs.rb`
- Modify: `Gemfile`, `test/test_helper.rb`
- Test: `test/models/chat_test.rb`

**Interfaces:**
- Produces: models `Chat`, `Message`, `ToolCall`, `Model` (acts_as_* from generator); helpers `stub_openai_chat(content:)` and `stub_openai_embedding(vector:)` available in all tests; `ENV["OPENAI_API_KEY"]` defaults to `"test-key"` under test.

- [ ] **Step 1: Install gems and run generator**

```bash
bundle add ruby_llm
bundle add dotenv-rails --group "development,test"
bundle add webmock --group test
bin/rails generate ruby_llm:install
bin/rails db:migrate
```

- [ ] **Step 2: Configure OpenAI-only**

Edit `config/initializers/ruby_llm.rb` to exactly:

```ruby
RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.default_model = "gpt-4o-mini"
  config.default_embedding_model = "text-embedding-3-small"
end
```

Create `.env.example`:

```
OPENAI_API_KEY=sk-your-key-here
```

- [ ] **Step 3: Wire WebMock and stubs**

Top of `test/test_helper.rb`, BEFORE `require_relative "../config/environment"`:

```ruby
ENV["OPENAI_API_KEY"] ||= "test-key"
```

After the existing requires:

```ruby
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)
Dir[File.expand_path("test_helpers/**/*.rb", __dir__)].each { |f| require f }
```

`test/test_helpers/openai_stubs.rb`:

```ruby
module OpenaiStubs
  def stub_openai_chat(content:)
    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        id: "chatcmpl-test", object: "chat.completion", created: 0, model: "gpt-4o-mini",
        choices: [ { index: 0, message: { role: "assistant", content: content }, finish_reason: "stop" } ],
        usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 }
      }.to_json
    )
  end

  def stub_openai_embedding(vector:)
    stub_request(:post, "https://api.openai.com/v1/embeddings").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        object: "list", model: "text-embedding-3-small",
        data: [ { object: "embedding", index: 0, embedding: vector } ],
        usage: { prompt_tokens: 1, total_tokens: 1 }
      }.to_json
    )
  end
end

class ActiveSupport::TestCase
  include OpenaiStubs
end
```

- [ ] **Step 4: Write the round-trip test**

`test/models/chat_test.rb`:

```ruby
require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "ask persists user and assistant messages via stubbed OpenAI" do
    stub_openai_chat(content: "Hello from the stub")
    chat = Chat.create!(model: "gpt-4o-mini")
    chat.ask("Say hello")
    assert_equal [ "user", "assistant" ], chat.messages.order(:created_at).pluck(:role)
    assert_includes chat.messages.last.content, "Hello from the stub"
  end
end
```

Run: `bin/rails test test/models/chat_test.rb` — Expected: PASS. If `Chat.create!(model: ...)` mismatches the generated schema (e.g. it expects `model_id` string or a `Model` association), READ the generated migration/models and adapt the creation call in the test to the generated interface; record the final form because Tasks 8–9 reuse it.

- [ ] **Step 5: Full suite green, commit**

```bash
bin/rails test test:system
git add -A && git commit -m "Add RubyLLM with OpenAI config and test stubs"
```

---

### Task 8: Chat UI scoped to users

**Files:**
- Create: via `bin/rails generate ruby_llm:chat_ui` (chats/messages controllers, views, jobs); `db/migrate/*_add_user_to_chats.rb`
- Modify: generated `app/controllers/chats_controller.rb`, `app/models/chat.rb`, `app/models/user.rb`, generated chat/message views (DaisyUI restyle), `app/views/shared/_navbar.html.erb`
- Test: `test/controllers/chats_controller_test.rb`

**Interfaces:**
- Consumes: `sign_in_as`, `stub_openai_chat`, fixtures `users(:one|:two)`.
- Produces: `Chat belongs_to :user`; `User has_many :chats, dependent: :destroy`; all chat routes require auth and scope through `Current.user.chats`.

- [ ] **Step 1: Run the generator**

```bash
bin/rails generate ruby_llm:chat_ui
bin/rails db:migrate
```

Inspect what it generated (`git status`); run `bin/rails test` to confirm nothing broke.

- [ ] **Step 2: Write failing scoping tests**

`test/controllers/chats_controller_test.rb`:

```ruby
require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get chats_url
    assert_redirected_to new_session_url
  end

  test "does not show another user's chat" do
    sign_in_as users(:one)
    other_chat = users(:two).chats.create!(model: "gpt-4o-mini")
    assert_raises(ActiveRecord::RecordNotFound) { get chat_url(other_chat) }
  end

  test "lists own chats" do
    sign_in_as users(:one)
    users(:one).chats.create!(model: "gpt-4o-mini")
    get chats_url
    assert_response :success
  end
end
```

(Adapt `create!(model: ...)` to the interface recorded in Task 7 Step 4.)

Run — Expected: FAIL (`chats` association missing).

- [ ] **Step 3: Implement scoping**

```bash
bin/rails generate migration AddUserToChats user:references
bin/rails db:migrate
```

`app/models/chat.rb`: add `belongs_to :user`. `app/models/user.rb`: add `has_many :chats, dependent: :destroy`.

In the generated `ChatsController`: replace every `Chat.` receiver with `Current.user.chats.` (index listing, `find`, `create`). Do NOT add `allow_unauthenticated_access` anywhere in chat controllers.

Run tests — Expected: PASS.

- [ ] **Step 4: DaisyUI restyle**

Generated views keep their structure; apply DaisyUI classes:
- Chat index: wrap list in `<div class="p-6 max-w-3xl mx-auto">`, each chat row as `list-row` inside `<ul class="list bg-base-100 rounded-box shadow">`, "New chat" as `btn btn-primary`.
- Message partial: user messages `<div class="chat chat-end"><div class="chat-bubble chat-bubble-primary">…</div></div>`, assistant messages `chat chat-start` + `chat-bubble`.
- Message form: input `input input-bordered w-full`, submit `btn btn-primary`.
- Navbar dropdown: add `<li><%= link_to "Chats", chats_path %></li>`.

- [ ] **Step 5: Verify manually + suite**

```bash
bin/rails test test:system
```

Expected: PASS. Then `bin/dev`, sign up, create a chat (needs real `OPENAI_API_KEY` in `.env` — optional smoke check, skip if no key).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "Add chat UI scoped to users with DaisyUI styling"
```

---

### Task 9: Schematist chat titles

**Files:**
- Create: `app/schemas/chat_title_schema.rb`, `app/jobs/generate_chat_title_job.rb`
- Modify: `Gemfile`, generated `ChatsController#create` (enqueue job)
- Test: `test/jobs/generate_chat_title_job_test.rb`

**Interfaces:**
- Consumes: `Chat` (+`user`), `stub_openai_chat`.
- Produces: `GenerateChatTitleJob.perform_later(chat)`; `ChatTitleSchema` (`title` string, `tags` string array).

- [ ] **Step 1: Add gem**

```bash
bundle add schematist
```

If `chats` has no `title` column: `bin/rails generate migration AddTitleToChats title:string && bin/rails db:migrate`.

- [ ] **Step 2: Write failing test**

`test/jobs/generate_chat_title_job_test.rb`:

```ruby
require "test_helper"

class GenerateChatTitleJobTest < ActiveJob::TestCase
  test "titles the chat from its first user message" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini")
    chat.messages.create!(role: "user", content: "How do I deploy Rails with Kamal?")
    stub_openai_chat(content: { title: "Deploying Rails with Kamal", tags: [ "rails", "kamal" ] }.to_json)
    GenerateChatTitleJob.perform_now(chat)
    assert_equal "Deploying Rails with Kamal", chat.reload.title
  end

  test "keeps an existing title" do
    chat = users(:one).chats.create!(model: "gpt-4o-mini", title: "Kept")
    GenerateChatTitleJob.perform_now(chat)
    assert_equal "Kept", chat.reload.title
  end
end
```

Run — Expected: FAIL (job undefined).

- [ ] **Step 3: Implement**

`app/schemas/chat_title_schema.rb`:

```ruby
class ChatTitleSchema < Schematist::Schema
  string :title, description: "Concise conversation title, six words maximum"
  array :tags, of: :string, description: "Up to three lowercase topic tags"
end
```

`app/jobs/generate_chat_title_job.rb`:

```ruby
class GenerateChatTitleJob < ApplicationJob
  queue_as :default

  def perform(chat)
    return if chat.title.present?
    first_question = chat.messages.where(role: "user").order(:created_at).first
    return if first_question.nil?
    response = RubyLLM.chat.with_schema(ChatTitleSchema).ask("Title this conversation: #{first_question.content}")
    chat.update!(title: response.content["title"])
  end
end
```

If `response.content` returns a String instead of a Hash, wrap with `JSON.parse`. If `with_schema` rejects the Schematist class directly, pass `ChatTitleSchema.new.to_json_schema` instead (check Schematist's README section on RubyLLM integration for the blessed form) and keep the test unchanged — it only asserts the resulting title. In the generated `ChatsController#create`, after the chat is successfully created: `GenerateChatTitleJob.perform_later(@chat)` (match the actual instance variable name used by the generated code).

- [ ] **Step 4: Run suite, commit**

```bash
bin/rails test test:system
git add -A && git commit -m "Auto-title chats with Schematist structured output"
```

---

### Task 10: Action Text + Lexxy + Document CRUD

**Files:**
- Create: `app/models/document.rb`, migration `create_documents`, `app/controllers/documents_controller.rb`, `app/views/documents/{index,new,edit,show,_form}.html.erb`
- Modify: `Gemfile`, `config/importmap.rb`, `app/javascript/application.js`, `app/views/layouts/application.html.erb`, `config/routes.rb`, `app/models/user.rb`, navbar
- Test: `test/controllers/documents_controller_test.rb`, `test/system/documents_test.rb`

**Interfaces:**
- Produces: `Document(user_id, title)` + `has_rich_text :content`; routes `resources :documents`; `User has_many :documents, dependent: :destroy`. (Embedding column arrives in Task 11.)

- [ ] **Step 1: Install Action Text and Lexxy**

```bash
bin/rails action_text:install
bin/rails db:migrate
bundle add lexxy
```

Per Lexxy docs (importmap path): in `config/importmap.rb` ensure `pin "lexxy", to: "lexxy.js"` (add if the gem does not auto-pin — check `bin/importmap json | grep lexxy` first). In `app/javascript/application.js`: `import "lexxy"`. In the layout `<head>`: `<%= stylesheet_link_tag "lexxy" %>` (verify the exact asset name against the gem's install docs/`app/assets` contents; adjust if it ships a different stylesheet name). Remove the `trix`/`actiontext.css` requires that `action_text:install` added if Lexxy's docs say they are superseded; otherwise leave them.

- [ ] **Step 2: Write failing tests**

`test/controllers/documents_controller_test.rb`:

```ruby
require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  include SessionTestHelper

  test "requires authentication" do
    get documents_url
    assert_redirected_to new_session_url
  end

  test "creates a document with rich content" do
    sign_in_as users(:one)
    assert_difference("Document.count") do
      post documents_url, params: { document: { title: "Kamal notes", content: "<p>Deploy with <strong>Kamal</strong></p>" } }
    end
    document = Document.last
    assert_equal users(:one), document.user
    assert_includes document.content.to_plain_text, "Deploy with Kamal"
  end

  test "does not show another user's document" do
    sign_in_as users(:one)
    other = users(:two).documents.create!(title: "Private", content: "secret")
    assert_raises(ActiveRecord::RecordNotFound) { get document_url(other) }
  end
end
```

`test/system/documents_test.rb`:

```ruby
require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  test "new document form renders the Lexxy editor" do
    visit new_session_url
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_on "Sign in"
    visit new_document_url
    assert_selector "lexxy-editor"
  end
end
```

(Match `fill_in` targets to the generated sessions view's actual field names/placeholders.)

Run — Expected: FAIL (no Document).

- [ ] **Step 3: Implement**

```bash
bin/rails generate model Document user:references title:string
bin/rails db:migrate
```

`app/models/document.rb`:

```ruby
class Document < ApplicationRecord
  belongs_to :user
  has_rich_text :content
  validates :title, presence: true
end
```

`app/models/user.rb`: add `has_many :documents, dependent: :destroy`.
`config/routes.rb`: `resources :documents`.

`app/controllers/documents_controller.rb`:

```ruby
class DocumentsController < ApplicationController
  def index
    @documents = Current.user.documents.order(updated_at: :desc)
  end

  def show
    @document = Current.user.documents.find(params[:id])
  end

  def new
    @document = Current.user.documents.build
  end

  def create
    @document = Current.user.documents.build(document_params)
    if @document.save
      redirect_to @document, notice: "Document created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @document = Current.user.documents.find(params[:id])
  end

  def update
    @document = Current.user.documents.find(params[:id])
    if @document.update(document_params)
      redirect_to @document, notice: "Document updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user.documents.find(params[:id]).destroy
    redirect_to documents_url, notice: "Document deleted"
  end

  private

  def document_params
    params.expect(document: [ :title, :content ])
  end
end
```

`_form.html.erb`: card layout; `form.text_field :title` (`input input-bordered w-full`), `form.rich_text_area :content`, submit `btn btn-primary`. Index: `list` rows linking to each document + `New document` button. Show: title `h1`, `<%= @document.content %>`, Edit/Delete buttons (`btn btn-ghost`, delete via `button_to` with `data: { turbo_confirm: "Delete this document?" }`). Navbar dropdown: add `<li><%= link_to "Documents", documents_path %></li>`.

- [ ] **Step 4: Run suite**

Run: `bin/rails test test:system` — Expected: PASS. If `lexxy-editor` selector fails, check the actual custom element name rendered (`page.html` in a debug run) and fix the ASSERTION to the element Lexxy really renders.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "Add documents with Lexxy rich text editing"
```

---

### Task 11: Neighbor semantic search

**Files:**
- Create: migration `add_embedding_to_documents`, `app/jobs/generate_document_embedding_job.rb`
- Modify: `Gemfile`, `app/models/document.rb`, `app/controllers/documents_controller.rb#index`, `app/views/documents/index.html.erb`
- Test: `test/models/document_test.rb`, `test/jobs/generate_document_embedding_job_test.rb`

**Interfaces:**
- Consumes: `stub_openai_embedding(vector:)`, `Document`.
- Produces: `Document::EMBEDDING_DIMENSIONS = 1536`, `Document#embedding_source_text`, `Document.semantic_search(query, limit: 5)`, `GenerateDocumentEmbeddingJob`.

- [ ] **Step 1: Install**

```bash
bundle add neighbor
bundle add sqlite-vec
bin/rails generate neighbor:sqlite
bin/rails generate migration AddEmbeddingToDocuments embedding:binary
bin/rails db:migrate
```

- [ ] **Step 2: Write failing tests**

`test/models/document_test.rb`:

```ruby
require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  def unit_vector(index)
    Array.new(Document::EMBEDDING_DIMENSIONS, 0.0).tap { |v| v[index] = 1.0 }
  end

  def create_document(title, index)
    doc = users(:one).documents.create!(title: title, content: "Body of #{title}")
    doc.update!(embedding: unit_vector(index))
    doc
  end

  test "embedding_source_text combines title and plain text content" do
    doc = users(:one).documents.create!(title: "Kamal", content: "<p>Deploy <strong>fast</strong></p>")
    assert_equal "Kamal\nDeploy fast", doc.embedding_source_text
  end

  test "semantic_search returns nearest documents first" do
    kamal = create_document("Kamal", 0)
    cooking = create_document("Cooking", 1)
    stub_openai_embedding(vector: unit_vector(0))
    results = Document.semantic_search("how to deploy")
    assert_equal kamal, results.first
    assert_includes results, cooking
  end

  test "saving enqueues an embedding refresh" do
    assert_enqueued_with(job: GenerateDocumentEmbeddingJob) do
      users(:one).documents.create!(title: "New", content: "text")
    end
  end
end
```

`test/jobs/generate_document_embedding_job_test.rb`:

```ruby
require "test_helper"

class GenerateDocumentEmbeddingJobTest < ActiveJob::TestCase
  test "stores the embedding and does not re-enqueue itself" do
    doc = users(:one).documents.create!(title: "Kamal", content: "Deploy")
    stub_openai_embedding(vector: Array.new(Document::EMBEDDING_DIMENSIONS, 0.5))
    perform_enqueued_jobs only: GenerateDocumentEmbeddingJob do
      GenerateDocumentEmbeddingJob.perform_now(doc)
    end
    assert_equal Document::EMBEDDING_DIMENSIONS, doc.reload.embedding.size
    assert_no_enqueued_jobs only: GenerateDocumentEmbeddingJob
  end
end
```

Run — Expected: FAIL (`EMBEDDING_DIMENSIONS` undefined).

- [ ] **Step 3: Implement**

`app/models/document.rb` — add:

```ruby
EMBEDDING_DIMENSIONS = 1536

has_neighbors :embedding, dimensions: EMBEDDING_DIMENSIONS
after_save_commit :refresh_embedding_later, unless: :saved_change_to_embedding?

def self.semantic_search(query, limit: 5)
  query_embedding = RubyLLM.embed(query).vectors
  where.not(embedding: nil).nearest_neighbors(:embedding, query_embedding, distance: "cosine").first(limit)
end

def embedding_source_text
  [ title, content.to_plain_text ].join("\n").strip
end

private

def refresh_embedding_later
  GenerateDocumentEmbeddingJob.perform_later(self)
end
```

`app/jobs/generate_document_embedding_job.rb`:

```ruby
class GenerateDocumentEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(document)
    document.update!(embedding: RubyLLM.embed(document.embedding_source_text).vectors)
  end
end
```

`DocumentsController#index`:

```ruby
def index
  @documents = if params[:q].present?
    Document.where(user: Current.user).semantic_search(params[:q])
  else
    Current.user.documents.order(updated_at: :desc)
  end
end
```

Index view — add above the list:

```erb
<%= form_with url: documents_path, method: :get, class: "join w-full mb-6" do |form| %>
  <%= form.text_field :q, value: params[:q], placeholder: "Semantic search…", class: "input input-bordered join-item w-full" %>
  <%= form.submit "Search", class: "btn btn-primary join-item" %>
<% end %>
```

- [ ] **Step 4: Run full suite**

Run: `bin/rails test test:system` — Expected: PASS. If `RubyLLM.embed(...).vectors` shape differs (single vs array of vectors), inspect the return in a console with the stub active and adjust `semantic_search`/job accordingly — the stubbed response has ONE embedding, so a single flat vector is expected.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "Add semantic search with Neighbor and sqlite-vec"
```

---

### Task 12: Kamal deployment config

**Files:**
- Modify: `config/deploy.yml`, `.kamal/secrets`

- [ ] **Step 1: Edit deploy.yml**

Keep the generated file structure; ensure/set these keys (placeholders in UPPERCASE are meant to be replaced per app):

```yaml
service: charco_template
image: YOUR_REGISTRY_USER/charco_template
servers:
  web:
    - YOUR_SERVER_IP
proxy:
  ssl: true
  host: app.YOUR_DOMAIN.com
registry:
  username: YOUR_REGISTRY_USER
  password:
    - KAMAL_REGISTRY_PASSWORD
env:
  secret:
    - RAILS_MASTER_KEY
    - OPENAI_API_KEY
volumes:
  - "charco_template_storage:/rails/storage"
```

The `volumes` line is the critical one: SQLite databases and Active Storage files live in `/rails/storage` and must survive deploys. Verify it exists (Rails generates it; do not delete it).

- [ ] **Step 2: Wire the secret**

In `.kamal/secrets` add: `OPENAI_API_KEY=$OPENAI_API_KEY`

- [ ] **Step 3: Validate and commit**

Run: `ruby -ryaml -e 'YAML.load_file("config/deploy.yml"); puts "ok"'` — Expected: `ok`.

```bash
git add -A && git commit -m "Configure Kamal deploy with persistent storage volume"
```

---

### Task 13: bin/rename

**Files:**
- Create: `lib/template/renamer.rb`, `bin/rename`
- Test: `test/lib/template/renamer_test.rb`

**Interfaces:**
- Produces: `Template::Renamer.new(root:, new_name:).run` — rewrites `CharcoTemplate`/`charco_template`/`charco-template` to the new name's camel/snake/dash forms in every text file under root (skipping `.git log node_modules storage tmp vendor` and `*.mjs`). `bin/rename my_new_app` runs it from the repo root.

- [ ] **Step 1: Write failing test**

`test/lib/template/renamer_test.rb`:

```ruby
require "test_helper"
require "tmpdir"

class Template::RenamerTest < ActiveSupport::TestCase
  test "rewrites module, snake and dashed names in text files" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "application.rb"), "module CharcoTemplate\nend\n")
      File.write(File.join(dir, "deploy.yml"), "service: charco_template\nhost: charco-template.example.com\n")
      FileUtils.mkdir(File.join(dir, "tmp"))
      File.write(File.join(dir, "tmp", "skipped.rb"), "CharcoTemplate")
      Template::Renamer.new(root: dir, new_name: "acme_notes").run
      assert_includes File.read(File.join(dir, "application.rb")), "module AcmeNotes"
      assert_includes File.read(File.join(dir, "deploy.yml")), "service: acme_notes"
      assert_includes File.read(File.join(dir, "deploy.yml")), "acme-notes.example.com"
      assert_includes File.read(File.join(dir, "tmp", "skipped.rb")), "CharcoTemplate"
    end
  end
end
```

Run: `bin/rails test test/lib/template/renamer_test.rb` — Expected: FAIL (uninitialized constant).

- [ ] **Step 2: Implement**

`lib/template/renamer.rb`:

```ruby
module Template
  class Renamer
    SKIP_DIRS = %w[.git log node_modules storage tmp vendor].freeze
    OLD_MODULE = "CharcoTemplate".freeze
    OLD_SNAKE = "charco_template".freeze
    OLD_DASHED = "charco-template".freeze

    def initialize(root:, new_name:)
      @root = Pathname.new(root)
      @new_snake = new_name.underscore
    end

    def run
      text_files.each { |path| rewrite(path) }
    end

    private

    def new_module = @new_snake.camelize

    def new_dashed = @new_snake.dasherize

    def text_files
      Dir.glob(@root.join("**", "*"), File::FNM_DOTMATCH)
        .select { |path| File.file?(path) && !skip?(path) && text?(path) }
    end

    def skip?(path)
      relative = Pathname.new(path).relative_path_from(@root).to_s
      relative.end_with?(".mjs") || SKIP_DIRS.any? { |dir| relative == dir || relative.start_with?("#{dir}/") }
    end

    def text?(path)
      chunk = File.binread(path, 8192)
      chunk.nil? || !chunk.include?("\x00")
    end

    def rewrite(path)
      original = File.read(path)
      updated = original.gsub(OLD_MODULE, new_module).gsub(OLD_SNAKE, @new_snake).gsub(OLD_DASHED, new_dashed)
      File.write(path, updated) if updated != original
    end
  end
end
```

`bin/rename` (then `chmod +x bin/rename`):

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "pathname"
require "active_support"
require "active_support/core_ext/string/inflections"
require_relative "../lib/template/renamer"

new_name = ARGV[0] or abort("Usage: bin/rename <new_app_name>")
Template::Renamer.new(root: File.expand_path("..", __dir__), new_name: new_name).run
puts "Renamed to #{new_name}. Review with: git diff"
```

- [ ] **Step 3: Run test, then full suite, commit**

```bash
bin/rails test test/lib/template/renamer_test.rb
bin/rails test test:system
git add -A && git commit -m "Add bin/rename for new apps born from the template"
```

---

### Task 14: AI-assistant files and README

**Files:**
- Create: `CLAUDE.md`, `AGENTS.md` (symlink), rewrite `README.md`

- [ ] **Step 1: Write CLAUDE.md**

```markdown
# CharcoTemplate

Rails starter template. This repo is both a working app and the template new apps are born from (`bin/rename <new_app_name>` after cloning).

## Stack
- Ruby 4.0.6, Rails 8.1.3.1, SQLite everywhere (Solid Queue/Cache/Cable on SQLite)
- Propshaft + Importmap (no Node), Tailwind v4 + DaisyUI 5 (vendored `app/assets/tailwind/daisyui*.mjs`)
- Hotwire (Turbo + Stimulus), Lexxy for Action Text rich text
- RubyLLM (OpenAI only: gpt-4o-mini / text-embedding-3-small), Schematist for structured output, Neighbor + sqlite-vec for vector search
- Native Rails authentication (+ custom registration/profile), Active Storage avatars
- Minitest + fixtures + WebMock (tests NEVER hit the network), Kamal deploys

## Commands
- `bin/setup` — install and prepare everything
- `bin/dev` — run app + Tailwind watcher
- `bin/rails test test:system` — full suite (run before every commit)
- `bin/rename <name>` — turn the template into a new app

## Conventions
- TDD always: failing test first, minimal implementation second.
- English-only code and copy. No code comments. No inline styles.
- DaisyUI component classes before custom CSS.
- Controllers scope data through `Current.user` (see `ChatsController`, `DocumentsController`).
- LLM calls in tests use `stub_openai_chat` / `stub_openai_embedding` (test/test_helpers/openai_stubs.rb).
- Background work goes to Solid Queue jobs (see `GenerateDocumentEmbeddingJob`).
- Commits: short imperative messages, no co-author trailers.

## Subsystem map
- Auth: `app/controllers/concerns/authentication.rb`, `SessionsController`, `RegistrationsController`, `ProfilesController`
- AI chat: RubyLLM generated models (`Chat`, `Message`, `ToolCall`, `Model`), `GenerateChatTitleJob` + `ChatTitleSchema`
- Semantic search: `Document` (`semantic_search`, `EMBEDDING_DIMENSIONS`), `GenerateDocumentEmbeddingJob`, `config/initializers/neighbor` via `neighbor:sqlite`
- Rich text: Action Text + Lexxy (`import "lexxy"` in app/javascript/application.js)
- Deploy: `config/deploy.yml` (placeholders in UPPERCASE; `storage/` volume is mandatory)
```

- [ ] **Step 2: Symlink AGENTS.md and rewrite README.md**

```bash
ln -s CLAUDE.md AGENTS.md
```

README.md sections (English): What is this / Features list / Requirements (mise, Ruby 4.0.6, libvips) / Quickstart (`clone → bin/rename → bin/setup → bin/dev`, INCLUDING regenerating credentials: `rm config/credentials.yml.enc && bin/rails credentials:edit`, then `bin/rails db:encryption:init` and paste the keys into credentials — required because master.key never travels with the repo and console1984 depends on Active Record encryption) / Configuration (`.env` from `.env.example`) / Testing (`bin/rails test test:system`, WebMock policy) / Console auditing (console1984 protects the production console; sessions/commands are recorded; `audits1984` optional companion) / Deployment (Kamal: replace UPPERCASE placeholders, `kamal setup`) / Adding 2FA later (rotp over the owned auth controllers, 3-4 line sketch) / Updating this template (bump `.ruby-version` + Gemfile, re-download DaisyUI `.mjs` files, run `ruby_llm:upgrade_to_*` generators, run the suite).

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "Add CLAUDE.md, AGENTS.md and README"
```

---

### Task 15: Final verification

- [ ] **Step 1: Full quality gate**

```bash
bin/rails test test:system
bin/rubocop
bin/brakeman --no-pager
```

Expected: all green. Fix any offense in OUR files (generated code may need `# rubocop:disable` never — prefer fixing or excluding paths in `.rubocop.yml` only for generated RubyLLM files if they violate omakase).

- [ ] **Step 2: Fresh-clone smoke test**

```bash
git clone . /tmp/charco_smoke && cd /tmp/charco_smoke
bin/rename acme_notes
grep -r "CharcoTemplate" --include="*.rb" . | grep -v renamer && echo "LEAK" || echo "clean"
bin/setup --skip-server && bin/rails test
cd - && rm -rf /tmp/charco_smoke
```

Expected: `clean`, suite green under the new name.

- [ ] **Step 3: Final commit and publish instructions**

```bash
git add -A && git commit -m "Final template polish"
```

Tell Bruno: create the GitHub repo, push `main`, then Settings → check "Template repository". New apps: "Use this template" → clone → `bin/rename`.

---

### Task 16: console1984 audited console

Execution order note: run this task after Task 11 and BEFORE Task 14 (docs reference it). Task 15 stays last.

**Files:**
- Modify: `Gemfile`, `config/application.rb` (only if changing protected environments — default production-only is kept, so likely no change), `db/schema.rb` (via migrations)
- Create: console1984 migrations (via `rails console1984:install:migrations`), Active Record encryption keys in credentials
- Test: `test/integration/console1984_test.rb`

**Interfaces:**
- Produces: console session/command audit tables; AR encryption configured (credentials hold `active_record_encryption` keys). Task 14's README documents the regenerate-credentials flow for new apps.

- [ ] **Step 1: Install**

```bash
bundle add console1984
bin/rails console1984:install:migrations
bin/rails db:migrate
```

- [ ] **Step 2: Configure Active Record encryption**

```bash
bin/rails db:encryption:init
```

Copy the printed keys into credentials (`bin/rails credentials:edit` opens $EDITOR; in non-interactive shells use `EDITOR="true" ...` tricks or write via `bin/rails runner` with `Rails.application.credentials` — if editing credentials non-interactively proves brittle, document the keys requirement and add them via `EDITOR='code --wait'`-free approach: `bin/rails credentials:edit` with EDITOR set to a script that appends the YAML block).

- [ ] **Step 3: Write the smoke test**

`test/integration/console1984_test.rb`:

```ruby
require "test_helper"

class Console1984Test < ActiveSupport::TestCase
  test "audit tables exist" do
    assert ActiveRecord::Base.connection.table_exists?("console1984_sessions")
    assert ActiveRecord::Base.connection.table_exists?("console1984_commands")
  end

  test "console protection targets production by default" do
    assert_includes Console1984.protected_environments.map(&:to_sym), :production
  end
end
```

Adapt table names/config reader to what the installed gem actually creates (inspect the migrations it copied); document adaptations.

- [ ] **Step 4: Run suite, commit**

```bash
bin/rails test test:system
git add -A && git commit -m "Add console1984 audited production console"
```
