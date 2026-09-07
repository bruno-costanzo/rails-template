# Deploy

Kamal, configured in `config/deploy.yml`. Every value an app must replace is an UPPERCASE placeholder: the registry user, the server address, the host.

The `storage/` volume is mandatory, not an optimization. SQLite databases and locally-stored Active Storage files both live there, so a deploy without it loses the entire database on the next container rotation.

`SOLID_QUEUE_IN_PUMA` is set here, which is what makes the job supervisor run inside the web container (see background-jobs.md), and the backup accessory is active by default (see backups.md).

The image build forwards the SSH agent: `Dockerfile` mounts it on the `bundle install` layer and `config/deploy.yml` asks Kamal for it under `builder`. `charco_mobile` is fetched from a private repository over SSH, so a build without the agent resolves every other gem and then fails on that one. `test/ci/image_build_test.rb` keeps both halves together, since either alone builds nothing.
