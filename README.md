This is a Silkroad online skill planner

# README

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/luciotbc/sro-build-planer)

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

### Dependency

- Ruby: 4.0.2
- [oxipng](https://github.com/oxipng/oxipng): lossless PNG optimizer used by the pre-commit hook (`brew install oxipng`)

### Getting Started

1. Clone the repository
2. Install dependencies using `bundle install`
3. Install oxipng: `brew install oxipng`
4. Enable git hooks: `git config core.hooksPath .githooks`
5. Setup your development environment `bin/setup`
6. Run the application using `bin/dev`

### Email (transactional mail)

The app sends transactional email (password reset, data export, etc.). Delivery is wired per environment:

| Env | Transport | Secrets |
|-----|-----------|---------|
| development | [Mailpit](https://mailpit.axllent.org) — fake SMTP, nothing leaves your machine | none |
| test | Rails `:test` delivery (`ActionMailer::Base.deliveries`) | none |
| production / staging / homologation | real SMTP | **Rails encrypted credentials only** |

#### Local mail with Mailpit

Mailpit captures every outgoing email and shows it in a web inbox — no real send, no account. Development delivers to `localhost:1025` and you read mail at **http://localhost:8025**.

**Option A — Docker Compose (recommended):**

```bash
docker compose up -d mailpit    # starts SMTP :1025 + web UI :8025
docker compose stop mailpit     # stop it
```

**Option B — bare metal (Homebrew, no Docker):**

```bash
brew install mailpit
mailpit                         # foreground
# or run as a background service:
brew services start mailpit
```

Then run the app (`bin/dev`), trigger an email, and open http://localhost:8025.

> Mailpit is intentionally **not** in `Procfile.dev`: foreman kills the whole stack if any process exits, so a missing `mailpit` binary would break `bin/dev` for everyone. Run it as a separate service (Compose or `brew services`).
>
> Override the SMTP target with `SMTP_ADDRESS` / `SMTP_PORT` (e.g. when the app itself runs inside Docker and reaches Mailpit by service name).

#### Other environments (production / staging / homologation)

SMTP credentials are stored **only** in Rails encrypted, per-environment credentials — never in `.env` or plaintext. Edit them with:

```bash
bin/rails credentials:edit --environment production
# also: --environment staging, --environment homologation
```

Expected structure:

```yaml
smtp:
  address: smtp.your-provider.com
  port: 587
  user_name: your-smtp-user
  password: your-smtp-password   # the only true secret
  domain: yourdomain.com
  host: yourdomain.com           # used for links in mailer templates
```

Each environment gets its own encryption key (`config/credentials/<env>.key`, gitignored). In production the key is delivered as the `RAILS_MASTER_KEY` env var via Kamal (`env/secret`, sourced from a password manager) — the SMTP secret never touches the repo or the container filesystem in plaintext. See [docs/todo/031-transactional-email.md](docs/todo/031-transactional-email.md) for the full rationale.

### Database

![Database Diagram](docs/diagrams/db-erd.svg)

To regenerate the diagram after schema changes:

```bash
bin/rails docs:erd
```

### Design System

The design system is a living, in-app reference served at `/docs/design_system` (`DocsController#design_system`, view `app/views/docs/design_system.html.erb`, development-only). Every component is a real `app/views/shared` partial styled by `@layer components` classes in `app/assets/tailwind/application.css`, so the docs cannot drift from production.
