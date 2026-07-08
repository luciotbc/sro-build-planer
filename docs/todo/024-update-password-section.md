# 024 — update-password-section

> **How agents use this:** the "Update password" card on `/settings`, built around two NEW shared components that later tasks reuse: (a) `shared/_password_fields` — new + confirm password inputs **with the live "Password must have" rules checklist**, and (b) its `password-rules` Stimulus controller. The checklist is hidden until the user starts editing new/confirm password (mockup behavior). Task 025 reuses (a) on Password Recovery; task 026 reuses the rules list on registration.

## Execution order
After 022. Blocks 025 and 026. Parallel with 023/027/028/030.

## Usage flow
1. Card "Update password", description "Use a strong password with at least 8 characters.", fields: `CURRENT PASSWORD` (full width), `NEW PASSWORD` + `CONFIRM PASSWORD` (two columns), `Update password` primary button.
2. Rules panel appears **only after focus/input on new or confirm password** (before the button, per mockup): heading `PASSWORD MUST HAVE:` with four live-checked items — `8+ characters`, `One uppercase letter (A-Z)`, `One number (0-9)`, `Matching confirmation`. Each item toggles red ✗ → green ✓ as typed (client-side, Stimulus).
3. Submit: current password verified (`user.authenticate`); new password runs the **model** validations (`app/models/user.rb:20-28` — same rules as the checklist; keep them in sync, they are the source of truth).
4. Wrong current password / failed validation → inline errors (Turbo Stream). Success → toast; current session kept, **other** sessions destroyed (hardening).

## References
- **Mockup:** `account_settings.html` — second card (focus a password field to see the rules panel).
- **Design system:** `_settings_card`, `btn-primary`. **GAP — no "password rules checklist" component**: add `.password-rules` component class + document on `/docs/design_system` (re-run `/design-sync`).
- **Code to reuse:** password validations in `User` (min 8, uppercase+digit format, `maxlength: 72` on fields); inline-error Turbo pattern (`registrations_controller.rb`); session termination helpers (`app/controllers/concerns/authentication.rb`).
- **Spec:** spec 09 — add rules: current-password required; other sessions revoked on change. Note checklist mirrors `User` validations.

## Implementation scope
### Persistence
None.

### Backend
- `Users::UpdatePasswordService.call(user:, current_password:, password:, password_confirmation:)` → `ServiceResult` (authenticate → assign → save → destroy other sessions).
- `Settings::PasswordsController#update` — thin.

### Frontend
- `app/views/shared/_password_fields.html.erb`: new+confirm inputs + rules panel; parameterized labels/placeholders via locals so recovery/registration can reuse. `data-controller="password-rules"` with targets for each rule item.
- `app/javascript/controllers/password_rules_controller.js`: reveal-on-first-edit, per-rule regex checks, confirmation match.
- Card form `app/views/settings/_password_form.html.erb` = current-password field + `_password_fields` + button.
- I18n: rule labels, errors, success in 6 locales (English source).

### States
- **Success:** toast, fields cleared. **Error:** inline (wrong current password; server-side rule failures — server remains authoritative even with JS checklist). **Empty:** rules panel hidden until edit. **Loading:** n/a.

## Acceptance criteria
- [ ] Rules panel hidden on load; appears when new/confirm gains input; items flip ✗/✓ live, exactly the 4 mockup rules.
- [ ] Submit with wrong current password → inline error, password unchanged.
- [ ] Server rejects passwords violating model rules even with JS disabled.
- [ ] Success keeps the current session, destroys other sessions, shows toast.
- [ ] `_password_fields` + `password-rules` controller are reusable (no settings-specific coupling); `.password-rules` documented in DS.
- [ ] Spec 09 + i18n updated; `bin/i18n-check` green; `PARALLEL_WORKERS=1 bin/rails test` green; browser-validated.

## Testing strategy (TDD — tests first)
1. **Service:** wrong current password → failure; weak new password → model errors surfaced; success → digest changed + other sessions gone.
2. **Integration:** PATCH flows (success/redirect+toast, failures via Turbo Stream); markup contains rules panel with `hidden` initial state.
3. JS behavior validated in browser (DoD), not unit-tested.

## Best practices
- Single source of truth = model validations; checklist is UX sugar. If rules ever change, change model + checklist + spec together (GR3).
- Keep PR ≤400 LOC; if the Stimulus controller + partial + service push past, stack: PR-1 service+form, PR-2 rules checklist component.

## Recommended LLM model
**Sonnet** — patterned CRUD + a small Stimulus controller.

## Commit strategy
Branch `feat/024-update-password`. Commits:
1. `test: update password service and settings flow`
2. `feat: update password service with session revocation`
3. `feat: shared password fields partial with live rules checklist`
4. `feat: update password card on settings page`
5. `docs: spec 09 password rules + i18n keys (6 locales)`
