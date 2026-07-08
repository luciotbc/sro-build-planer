# 022 — account-settings-page

> **How agents use this:** create the Account settings page shell — route, controller, view with page header and the stacked section-card layout — that tasks 023/024/027/028/030 plug their sections into. **Do not touch the topbar** (no nav entry yet — explicit scope decision). Also creates spec `docs/specs/09-account-settings.md` (page access rules) per GR2/GR3. Mockup: `account_settings.html` in the SRO Labs design project (read via Claude-in-Chrome, workflow rule 14).

## Execution order
First task of the account-settings feature. No dependency on 000–021. Blocks 023, 024, 027, 028, 030.

## Objective
Authenticated users reach `/settings` and see the "Account settings" page: title, subtitle "Manage your login credentials, notifications, and account data.", and a vertical stack of section cards (sections themselves land in later tasks).

## Usage flow
1. Logged-in user navigates to `/settings` (direct URL for now; topbar link is future work).
2. Page renders header + (for now empty) card stack, dark theme, centered column (~520px per mockup).
3. Unauthenticated visitor → redirected to login (standard `Authentication` concern behavior).

## References
- **Mockup:** `account_settings.html` (design project `e76dd313-…`).
- **Design system:** **GAP — no "settings section card" component exists** (card with title, muted description, body). Add a `settings-card` component class in `@layer components` (`app/assets/tailwind/application.css`), render it from a new shared partial `app/views/shared/_settings_card.html.erb` (locals: `title:`, `description:`, block body), and add it to `/docs/design_system` (re-run `/design-sync`, workflow rule 11).
- **Partials:** `app/views/shared/_topbar.html.erb` (rendered, NOT modified).
- **Spec:** create `docs/specs/09-account-settings.md` (auth-required access, section inventory, one concern per rule) + update `docs/specs/README.md` index (GR3).

## Implementation scope
### Persistence
None.

### Backend
- Route: `resource :settings, only: :show` (or `get "settings" => "settings#show"`).
- `SettingsController#show` — thin, requires auth (default `Authentication` concern), exposes `Current.user`.

### Frontend
- `app/views/settings/show.html.erb`: topbar render + page header (`h1` "Account settings", muted subtitle) + card-stack container.
- `_settings_card` partial + `.settings-card` CSS component; documented in the DS page with a snippet.
- I18n: `settings.show.*` keys in **all 6 locales**; game jargon list untouched (spec 08 R14).

### States
- **Success:** page renders for logged-in user. **Error:** anonymous → login redirect. **Empty/Loading:** n/a (server-rendered shell).

## Acceptance criteria
- [ ] `GET /settings` renders title + subtitle for an authenticated user; anonymous gets login redirect.
- [ ] Topbar unchanged (no diff in `_topbar.html.erb`).
- [ ] `.settings-card` component exists, is used by the page, and appears on `/docs/design_system`.
- [ ] Spec 09 created + spec README index updated; all 6 locales updated; `bin/i18n-check` passes.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; browser-validated; no console errors.

## Testing strategy (TDD — tests first)
1. Integration (`class SettingsShowTest < ActionDispatch::IntegrationTest`): authenticated GET → 200 + header markup; unauthenticated GET → redirect (use `follow_redirect! while response.redirect?` before HTML assertions).

## Best practices
- `bin/rails tailwindcss:build` after CSS edits (watcher dies in sandbox).
- Keep the shell PR tiny — it exists so section PRs stay ≤400 LOC each.

## Recommended LLM model
**Sonnet** — routine route/controller/view + one CSS component.

## Commit strategy
Branch `feat/022-account-settings-page`. Commits:
1. `test: settings page access and shell`
2. `feat: settings route, controller and page shell`
3. `feat: settings-card design-system component`
4. `docs: spec 09 account settings + i18n keys (6 locales)`
