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
- The page is reachable via direct URL and from the **user-settings menu** in the authenticated topbar (task 032): the avatar trigger opens a dropdown whose "Account settings" item links to `settings_path`. The menu also holds "Log out" (`DELETE /session`) and deliberately excludes any language/locale switcher. It is rendered from the layout's `:topbar_actions` slot via `shared/_user_menu` (driven by the `menu` Stimulus controller), not from `shared/_topbar` (which stays a pure layout slot).

### R3 — Section inventory
The page hosts, in order: Update email *(R4 — task 023)*, Update password *(R5 — task 024)*, Email me updates about SRO Labs *(R6 — task 027)*, My data *(R7 — task 028; export R8 — task 029)*, Delete account *(R9 — task 030)*.

### R4 — Update email (task 023)
- **Given** a logged-in user, **when** they submit a new valid email, **then** the email is updated, `email_confirmed_at` is reset to `nil`, and a confirmation email is sent to the **new** address (existing `email_confirmation` flow) — the user must re-verify. The session is kept.
- **Given** the previous state's confirmation links, **when** the email changes, **then** they stop working (the token embeds `email_confirmed_at`).
- **Given** an invalid or already-taken email, **when** submitted, **then** an inline validation message is shown, nothing changes, no mail is sent, and the taken-email error does not reveal the other account.
- **Given** an unchanged email, **when** submitted, **then** it is a no-op with a neutral notice (no mail, confirmation kept).
- Updates are rate-limited (same posture as registration).

### R5 — Update password (task 024)
- **Given** a logged-in user, **when** they submit current + new + confirmation, **then** the current password must authenticate and the new password must satisfy the `User` model validations (min 8 chars, one uppercase, one number, confirmation match) — the model is the single source of truth; the live checklist merely mirrors it.
- **Given** a successful change, **then** every OTHER session of the user is destroyed; the session performing the change stays valid.
- **Given** a wrong current password or failed validation, **then** an inline error is shown and nothing changes.
- The "Password must have" checklist (shared `_password_fields` + `password-rules` Stimulus controller) stays hidden until the user edits the new/confirmation field; it is client-side UX only — the server re-validates with JS disabled.
- Updates are rate-limited (same posture as registration).

### R6 — Product-updates email opt-in (task 027)
- `users.email_opt_in` (boolean, default **false**) — set at registration, editable on `/settings` via the Product updates toggle, which saves on change (no separate save button).
- The flag governs **product-update emails only**; transactional mail (confirmation, password reset, data export) is always sent.

### R7 — My data summary (task 028)
- The card shows read-only rows: email address; account created date; Terms & Privacy Policy accepted date; total characters created.
- **Terms-accepted date equals `created_at`**: terms are accepted as part of registration (`Users::RegisterService` gate) and no `terms_accepted_at` column exists — a deliberate scope decision. If terms re-acceptance is ever introduced, add the column and update this rule.
- Dates render via `l(date, format: :long)` (rails-i18n locale data).

### R8 — Export my data (task 029)
- **Given** a logged-in user clicking "Export my data", **then** a background job (Solid Queue, `Users::ExportDataJob`) builds the archive and emails it; the request itself only enqueues and shows a notice. Requests are rate-limited (2 per 10 min).
- Archive: single zip named `srolabs_<UTC %Y%m%d%H%M%S>.zip`, attached to one email to the account address (transactional — sent regardless of `email_opt_in`).
- `user.csv`: `email_address, email_confirmed_at, email_opt_in, created_at` — **never** ids/uuids/password data.
- One CSV per character named `<race prefix>_<name>_<current level>.csv` (`ch` Chinese, `eu` European; name sanitized to `[0-9A-Za-z_-]`; duplicates suffixed `_2`, `_3`…). Columns: `mastery_name, mastery_current_level, mastery_future_level, skill_group_name, current_skill_level, future_skill_level` — one row per `CharacterSkill`; "future" = the `target_*` fields.
- CSV headers are data identifiers and stay in English in every locale.
- Empty cases: no characters → zip contains only `user.csv`; character without skills → header-only CSV.

### R9 — Delete account (task 030)
- **Given** the confirmation modal, **when** the typed value equals the literal word `DELETE` (same in every locale — treated like fixed jargon), **then** the account is hard-deleted with its full cascade (sessions, characters, character masteries/skills), the session ends, and the user lands on the home page with a farewell notice. No grace period, no soft delete (scope decision).
- **Given** any other confirmation value — including forged requests without the param — **then** nothing is deleted and an error is shown. The disabled-until-typed button is UX only; `Users::DeleteAccountService` is the gate.
- Deleting the user invalidates every session row, so concurrent sessions die immediately.

## Cross-links
- Ownership/auth foundations: [05-character-lifecycle](05-character-lifecycle.md).
- Locale conventions for the new keys: [08-i18n-conventions](08-i18n-conventions.md); no new game jargon introduced.
