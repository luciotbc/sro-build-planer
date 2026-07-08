# 031 — transactional-email

> **How agents use this:** wires transactional email delivery for every environment. **Dev** captures all mail with [Mailpit](https://mailpit.axllent.org) (fake SMTP + web inbox at `:8025`) — no real send, no secrets. **Prod/staging/homologation** deliver over real SMTP whose credentials come **only** from Rails encrypted credentials (`config/credentials/<env>.yml.enc`), never from `.env` or plaintext. This is infra/config — no mockup, no UI, no new domain spec.

## Execution order
Independent infra task; no dependency on other backlog items. Enables reliable delivery for existing mailers (`passwords_mailer`, `users_mailer`, `UsersMailer#data_export` from 029) and any future one.

## Usage flow
1. **Dev** — run Mailpit (Docker `docker compose up -d mailpit`, or bare `mailpit` via Homebrew). App delivers to `localhost:1025`; developer reads mail at `http://localhost:8025`.
2. **Prod/staging/homolog** — `RAILS_ENV`'s `smtp_settings` read address/port/user/password from `Rails.application.credentials.dig(:smtp, …)`. The decrypt key is injected as `RAILS_MASTER_KEY` (Kamal `env/secret`, sourced from a password manager). No SMTP secret ever touches the repo or the container filesystem in plaintext.

## References
- **Code to reuse:** existing `config/environments/*.rb` mailer blocks (prod already scaffolds the commented `smtp_settings` + `credentials.dig(:smtp, …)` at `production.rb:65-72`); Kamal secrets already wire `RAILS_MASTER_KEY` (`.kamal/secrets`, `config/deploy.yml` `env/secret`).
- **New dev dependency:** Mailpit (Docker image `axllent/mailpit` **or** `brew install mailpit`) — dev/test tooling only, not a gem, not shipped.
- **New file:** `compose.yaml` (dev-only Mailpit service).
- **Spec:** none — no `docs/specs` rule governs mail infrastructure. Business rules for *what* mail is sent live in spec 09 / task 029; this task only governs *transport*.
- **Docs:** root `README.md` (install + run Mailpit, local and Docker) and this task file.

## Decision — secret storage (safest)
| Config | Storage | Rationale |
|---|---|---|
| SMTP password / user / API key (**secret**) | `config/credentials/<env>.yml.enc` (per env) | encrypted at rest; never in git, never plaintext on the server |
| SMTP address / port / mailer host (**non-secret**) | same per-env credentials file | single source; varies per env anyway |
| Per-env decrypt key | `RAILS_MASTER_KEY` env var via Kamal (already wired) | key from password manager, not on disk in prod |
| Dev | **nothing** — Mailpit needs no auth | zero secrets in the dev path |

**`.env` rejected.** Repo already standardizes on encrypted credentials + Kamal; adding dotenv = a second secrets mechanism, plaintext secret on disk, two sources to keep in sync = larger attack surface. Per-environment credentials (own key each) isolate blast radius: a leaked staging key cannot decrypt prod.

## Implementation scope
### Persistence
None.

### Config
- `config/environments/development.rb` — `delivery_method = :smtp`, `smtp_settings = { address: ENV.fetch("SMTP_ADDRESS","localhost"), port: ENV.fetch("SMTP_PORT",1025) }`, flip `raise_delivery_errors` to `true` (dev should surface broken mail, not silently drop it).
- `config/environments/production.rb` — uncomment + fill the `smtp_settings` block reading from `credentials.dig(:smtp, …)`; set `default_url_options[:host]` from credentials; `delivery_method = :smtp`. Staging/homologation reuse this env (run as `production`) or a dedicated env file with its own credentials file — documented, not built here unless an env file already exists.
- `config/environments/test.rb` — untouched (`:test` delivery).

### Tooling
- `compose.yaml` — `mailpit` service, ports `1025` (SMTP) + `8025` (UI), `restart: unless-stopped`.
- **Not** added to `Procfile.dev` — see Best practices.

### States
- **Dev success:** mail lands in Mailpit UI. **Dev failure:** `raise_delivery_errors=true` surfaces it (e.g. Mailpit not running) instead of silent no-op.
- **Prod:** missing credential → `smtp_settings` value is `nil`; delivery fails loudly in logs (acceptable — misconfig must be visible).

## Acceptance criteria
- [ ] `compose.yaml` runs Mailpit; `docker compose up -d mailpit` exposes `:1025`/`:8025`.
- [ ] Dev mailer delivers to Mailpit; a triggered mail (e.g. password reset) appears in the `:8025` inbox.
- [ ] Dev `raise_delivery_errors = true`.
- [ ] Prod `smtp_settings` reads every field from `credentials.dig(:smtp, …)`; no secret literal in any tracked file (`grep` clean).
- [ ] `README.md` documents Mailpit install + run for **both** bare-metal (Homebrew) and Docker Compose, plus the per-env credentials command.
- [ ] Existing mailer tests stay green (`PARALLEL_WORKERS=1 bin/rails test`); rubocop/format clean.

## Testing strategy (TDD — tests first)
Config/transport changes are not unit-tested per se (asserting env config is low value and brittle). Instead:
1. Keep existing `test/mailers/*` and integration mail assertions green — they prove mailers still render/enqueue under the changed config (test env uses `:test` delivery, unaffected).
2. Browser/manual: `docker compose up -d mailpit`, trigger a password-reset email, confirm it lands in the `:8025` inbox (evidence: screenshot).
3. `grep -rn` the repo to prove no SMTP password/user literal is committed.

## Best practices
- **Do not add Mailpit to `Procfile.dev`.** foreman terminates the whole stack if any process exits, so a dev without the `mailpit` binary would break `bin/dev` for everyone. Mailpit is a persistent infra service → run it via `docker compose` or `brew services`, decoupled from app boot. Offer an opt-in `Procfile.dev.local` only if a developer explicitly wants it bundled.
- Use `ENV.fetch` with Mailpit defaults in dev so the host/port can be overridden (e.g. when the app runs inside Docker and reaches Mailpit by service name).
- Per-environment credentials: `bin/rails credentials:edit --environment <env>`.

## Recommended LLM model
**Sonnet** — small, well-bounded config + docs change; no algorithmic complexity.

## Commit strategy
Branch `feat/031-transactional-email`. Commits:
1. `chore: add mailpit compose service for local email testing`
2. `feat: deliver dev mail to mailpit and surface delivery errors`
3. `feat: smtp delivery via encrypted credentials for non-dev envs`
4. `docs: document mailpit setup and email secret strategy`
