# 09 — Account Settings

> **How agents use this:** business rules for the `/settings` page (account management). One rule per concern, Given/When/Then where behavior branches. Visual/interaction is governed by the `account_settings.html` mockup and the design system (`.settings-card` etc.), NOT by this spec (see [03](03-prerequisites-and-cascade.md) M1). Rules are added incrementally as tasks `docs/todo/022`–`030` land; sections below marked *(planned)* are specified by their task file until implemented.

## Glossary
- **Settings page** — `/settings`, the authenticated account-management page (`SettingsController#show`).
- **Section card** — one `.settings-card` per concern (email, password, opt-in, my data, delete).

## Rules

### R1 — Access
- **Given** an unauthenticated visitor, **when** they request `/settings`, **then** they are redirected to login (standard `Authentication` concern) and returned to `/settings` after authenticating.
- **Given** an authenticated user, **when** they request `/settings`, **then** the page renders with their own account data only (`Current.user`).

### R2 — Navigation
- No topbar entry for now (explicit scope decision, task 022): the page is reachable by direct URL. Adding a topbar/menu link is future work and must not modify `shared/_topbar` until then.

### R3 — Section inventory
The page hosts, in order: Update email *(planned — task 023)*, Update password *(planned — 024)*, Email me updates about SRO Labs *(planned — 027)*, My data *(planned — 028, export 029)*, Delete account *(planned — 030)*. Each section's rules join this spec when its task ships.

## Cross-links
- Ownership/auth foundations: [05-character-lifecycle](05-character-lifecycle.md).
- Locale conventions for the new keys: [08-i18n-conventions](08-i18n-conventions.md); no new game jargon introduced.
