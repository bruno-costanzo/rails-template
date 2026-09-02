# Rich text

Action Text with the Lexxy editor. The pieces are `import "lexxy"` in `app/javascript/application.js`, a manual `pin "lexxy"` in `config/importmap.rb`, and `stylesheet_link_tag "lexxy"` in the layout — Lexxy is not pinned by `bin/importmap`, so a fresh pin has to be added by hand.

On Rails 8.1 Lexxy has no official editor adapter to plug into, so it monkey-patches `rich_text_area` and `rich_textarea` instead. Re-check `Lexxy.supports_editor_adapter?` after any Rails upgrade: the rendered `lexxy-editor` tag should be identical either way, but the path that produces it changes, so re-run the Lexxy system test to confirm.
