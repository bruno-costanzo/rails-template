# Console auditing

console1984 records production console sessions and the commands run in them. It depends on Active Record Encryption, whose keys live in `config/credentials.yml.enc` and are generated with `bin/rails db:encryption:init`.

`config/credentials.yml.enc` travels with the repository and the master key that opens it never does, so a new app has to generate its own credentials before the console — or anything else that decrypts — will boot in production. The README's Quickstart and Console auditing sections carry the steps.
