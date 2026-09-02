# Deploy

Kamal, configured in `config/deploy.yml`. Every value an app must replace is an UPPERCASE placeholder: the registry user, the server address, the host.

The `storage/` volume is mandatory, not an optimization. SQLite databases and locally-stored Active Storage files both live there, so a deploy without it loses the entire database on the next container rotation.

`SOLID_QUEUE_IN_PUMA` is set here, which is what makes the job supervisor run inside the web container (see background-jobs.md), and the backup accessory is active by default (see backups.md).
