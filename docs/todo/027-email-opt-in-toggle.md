# 027 — email-opt-in-toggle

> **How agents use this:** the "Email me updates about SRO Labs" card — a "Product updates" toggle switch persisting the user's opt-in. **The DB column `users.email_opt_in` (boolean, default false, NOT NULL) already exists** (`db/schema.rb` users table) — the original request said "add column"; verify and reuse it instead of migrating a duplicate. The toggle-switch control is a **design-system gap** — build and document it.

## Execution order
After 022. Parallel with 023/024/028/030.

## Usage flow
1. Card title "Email me updates about SRO Labs"; row: bold "Product updates", muted copy "Occasional emails about new features and major releases. We send these very rarely.", toggle on the right reflecting `email_opt_in`.
2. Flipping the toggle auto-submits (Turbo form, no separate save button per mockup) → persists → success toast; failure reverts with error toast.

## References
- **Mockup:** `account_settings.html` — third card.
- **Design system:** **GAP — no toggle-switch component** (checkboxes are inline `accent-brass` only). Add `.toggle` component in `@layer components` styled per mockup (pill track + knob), driven by a visually-hidden checkbox — use CSS `:has(input:checked)` (NOT `peer-checked`, which fails for non-siblings — see memory/feedback). New shared partial `app/views/shared/_toggle.html.erb`; document on `/docs/design_system` (re-run `/design-sync`).
- **Spec:** spec 09 — add rule: opt-in default false; controls product-update emails only (not transactional mail).

## Implementation scope
### Persistence
None new — column exists. (If registration already writes it, leave as-is.)

### Backend
- `Settings::EmailOptInsController#update` (or a `settings#update` slice) toggling `email_opt_in`; trivial CRUD → no service needed (repo rule: services only beyond trivial CRUD).

### Frontend
- `_toggle` partial inside `_settings_card`; form auto-submits on `change` (tiny Stimulus action or `onchange: this.form.requestSubmit()` via existing controller pattern); Turbo response → toast.
- I18n: card copy + toasts in 6 locales.

### States
- **Success:** toggle persists across reload + toast. **Error:** revert + error toast. **Empty/Loading:** n/a.

## Acceptance criteria
- [ ] Toggle renders current `email_opt_in`; flipping persists without full-page dead-end; state survives reload.
- [ ] No duplicate migration; schema untouched.
- [ ] `.toggle` component documented in the design system.
- [ ] Spec 09 + i18n updated; `bin/i18n-check` green; tests green (`PARALLEL_WORKERS=1`); browser-validated.

## Testing strategy (TDD — tests first)
1. Integration: PATCH toggles the flag on `Current.user` only; anonymous → login redirect; response renders toast/redirect (follow-redirect loop).

## Best practices
- Keep it a checkbox under the hood (accessibility, no-JS fallback still submits with a button fallback if trivial).

## Recommended LLM model
**Haiku** — one boolean field + one CSS component.

## Commit strategy
Branch `feat/027-email-opt-in-toggle`. Commits:
1. `test: email opt-in toggle persistence`
2. `feat: toggle design-system component`
3. `feat: product updates opt-in card on settings page`
4. `docs: spec 09 opt-in rule + i18n keys (6 locales)`
