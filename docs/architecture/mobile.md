# Mobile apps

The app ships as native iOS and Android apps through the `charco_mobile` gem, pinned in the `Gemfile` from its GitHub repository. The gem is the Rails side of a config-driven native shell: the views describe the native chrome they want with hidden `data-native-*` elements, and the shells read those elements from every page they render. The complete reference, including every helper and the design of the shells, lives in that repository; this page covers what this app does with it.

## Where it lives

- `config/charco_mobile.yml` — the tab bar, the colors and the error screen icons. The engine serves it as JSON at `/native/config`, rendered through ERB first so asset helpers work inside it. While code reloading is on, every request reads the file again.
- `config/locales/es.yml` and `config/locales/en.yml`, under `charco_mobile` — the tab titles and the error screen copy. The device language picks the translation, and `config/i18n-tasks.yml` ignores the namespace as unused because no view calls it: the gem reads it when it builds the config document.
- `app/views/layouts/application.html.erb` — the identity, tab bar, badge and toast signals, the web navbar hidden for the app, and the `native-inset` class on `main` so the page clears the status bar and the tab bar.
- `app/views/shared/_flash.html.erb` — skips notices for the app, because the layout already turns them into a native toast. Alerts stay web banners on both, since they explain the page they appear on.
- `app/views/shared/_native_navbar.html.erb` — the native navigation bar every page gets in the app: the page title (from `content_for :title` or the meta tags), a sign-in button when signed out, and when signed in a menu with profile, sessions, feedback and sign out. Sign out clicks a hidden `button_to` the partial keeps in the DOM, since the web navbar with the real one is not rendered in the app.
- The `new` and `edit` pages of sessions, registrations, passwords, email confirmations, profiles, feedback, documents and chats start with `native_form_tag`, so the app skips them on the way back after a submission.
- `app/views/chats/index.html.erb` — the chat list is the reference page for the richer signals: a floating action button to the new-chat form and a native menu per row anchored to the row's element, with the web buttons the menu clicks kept in the DOM under `native-hidden`. The support launcher moves to the left corner in the app (`app/assets/tailwind/application.css`) so the button never covers it.
- `config/ci.rb` — the `charco_mobile check` step parses every view and fails on a mistyped, duplicated or too-new signal.
- `.github/workflows/ci.yml` — the gem lives in a private repository reached over SSH, so an ssh-agent step loads the `CHARCO_MOBILE_DEPLOY_KEY` secret before Bundler runs. The key is a read-only deploy key of that repository; every app born from here needs the same secret in its own repository, or its first CI run fails at `bundle install`.

## Gotchas

A signal the app cannot read is silently ignored, which is why the CI step exists: a typo in `data-native-tabs` does not raise, the tab bar just never appears.

The tab bar and the badge render only while someone is signed in, so a signed-out page has no tabs by construction; the sign-in and sign-up pages are the only ones a signed-out person sees in the app.

The identity tag renders on every page, signed out included: it is the absence or the change of the value that resets the app on sign-out, and a page that skipped the tag would keep a signed-out person's screens alive.

Every signal must render inside the body, never in the head, because the shell watches the body for them.

The session cookie is already permanent (see `auth.md`), which is what keeps a native person signed in across launches; a change there to a session-scoped cookie signs every app user out on relaunch.

Preview on a device with `bin/rails server` in one terminal and `bundle exec charco_mobile preview` in another: it tunnels the local server through Cloudflare and prints a QR code, and a middleware keeps the session cookie working through the tunnel's public suffix domain.

## Turning it off

Nothing runs in the browser, so an app that never ships to the stores loses nothing by keeping this in place. An app that wants it gone removes the gem from the `Gemfile`, deletes `config/charco_mobile.yml`, `test/integration/mobile_test.rb` and this page, drops the `charco_mobile` namespace from both locale files and from `config/i18n-tasks.yml`, the check step from `config/ci.rb`, the ssh-agent step from `.github/workflows/ci.yml`, the `native_*` lines from the layout, the flash partial and the form pages, and the entry in the subsystem map. `bin/i18n-tasks health` and `test/docs/documentation_test.rb` fail on anything left behind.
