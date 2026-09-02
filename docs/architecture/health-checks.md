# Health checks

Two endpoints with different jobs. `/up` is Rails' shallow liveness probe and Kamal's proxy uses it to gate deploys and container rotation — keep it shallow, and note that `config/environments/production.rb` excludes it from the SSL redirect and silences it in the logs. `GET /health` (`HealthController`, public by design) renders `HealthCheck.call` (`app/models/health_check.rb`) as JSON: `200` when every check passes, `503` with the failing one marked as an error.

Two checks ship. `database` runs a trivial query on the primary connection. `jobs` looks for a Solid Queue supervisor whose heartbeat is inside `SolidQueue.process_alive_threshold` — the gem's own liveness window rather than an invented number.

The supervisor's `kind` is never plain `Supervisor`: Solid Queue writes `Supervisor(fork)` or `Supervisor(async)`, so the check matches with `LIKE`. An exact match compiles, passes review and reports the queue dead forever. Detection also lags by up to the threshold: a graceful shutdown deregisters and goes red immediately, while an abrupt kill leaves a fresh heartbeat behind for a few minutes.

The `jobs` check is included only when the Active Job adapter is Solid Queue's — true in development and production, false in test — so the suite's job behaviour is unaffected by the endpoint existing.

It exists because the supervisor runs inside Puma. A dead supervisor leaves Puma serving pages and `/up` green while email, embeddings, chat replies, data exports and feedback tickets stop silently. The endpoint is public rather than superadmin-gated because the superadmin gate is deny-by-default: an unconfigured app would answer `401`, which every uptime monitor reads as an outage. Adding a check is one line in `HealthCheck#call`.
