# Console auditing

console1984 records production console sessions and the commands run in them. It depends on Active Record Encryption, whose keys live in `config/credentials.yml.enc` and are generated with `bin/rails db:encryption:init`.

`config/master.key` never travels with the repository, so a new app has to generate its own credentials before the console — or anything else that decrypts — will boot in production. The README's Quickstart and Console auditing sections carry the steps.
