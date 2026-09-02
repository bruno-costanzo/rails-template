# Sitemap and robots

`SitemapsController` serves both `/sitemap.xml` and `/robots.txt`, unauthenticated; there is no file in `public/`.

They are dynamic because the `Sitemap:` directive needs an **absolute** URL and a static file cannot know its host. A checked-in `robots.txt` would hardcode one host into every app born from this one — the same trap as an unset `APP_HOST`.

The sitemap lists the root, `/blog` and every published post with its last-modified date, using the same published scope the public blog uses, so drafts cannot leak. `robots.txt` disallows the developer panels.

Neither is cached, deliberately. If a blog grows large enough for that to matter, add `fresh_when` rather than a sitemap-generator gem.
