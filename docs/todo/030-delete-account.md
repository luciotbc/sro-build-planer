# 030 — delete-account

> **How agents use this:** the "Delete account" danger card + type-DELETE confirmation modal. Hard-deletes the user and all associated data (sessions, characters and their masteries/skills via `dependent: :destroy`), signs the user out, redirects to the landing page. The literal confirmation word is **`DELETE` in every locale** (acts like fixed jargon — record in spec 09).

## Execution order
After 022. Parallel with 023/024/027/028/029.

## Usage flow
1. Danger card (red accents): title "Delete account", copy "Permanently erase your account and all associated data. This action cannot be undone.", full-width outlined red button `Delete my account`.
2. Click opens a modal (existing `dialog` component): trash icon in a red rounded square, heading "Delete your account?", copy "This is permanent. All your characters, builds, and data will be erased and cannot be recovered.", label `TYPE DELETE TO CONFIRM`, text input (placeholder `delete`), buttons `Cancel` + `Delete account` (danger).
3. `Delete account` stays disabled until the input equals `DELETE` (Stimulus; server re-checks — client state is not trusted).
4. Confirm → destroy user, terminate session, redirect to root with a farewell toast. Cancel/Esc closes the modal.

## References
- **Mockup:** `account_settings.html` — last card + its modal (click "Delete my account" in Present mode).
- **Design system:** `_modal` partial + `dialog` Stimulus controller; `btn-primary`/`btn-ghost`. **GAPs — no danger-variant button and no danger card**: add `.btn-danger` (solid/outline) and danger-card styling to `@layer components`, document on `/docs/design_system` (re-run `/design-sync`).
- **Code to reuse:** `User has_many :sessions/:characters, dependent: :destroy` (`app/models/user.rb`); `terminate_session` (`authentication.rb` concern); `_modal` + `dialog` controller.
- **Spec:** spec 09 — deletion rules: hard delete, cascade inventory, confirmation word, no grace period (scope decision).

## Implementation scope
### Persistence
None (cascades already modeled).

### Backend
- `Users::DeleteAccountService.call(user:, confirmation:)` → `ServiceResult`; fails unless `confirmation == "DELETE"`; destroys user.
- `Settings::AccountsController#destroy` (DELETE verb) — thin; terminates session on success.

### Frontend
- Danger card + modal on `/settings`; Stimulus `delete-confirmation` (or extend an existing controller) enabling the button on exact match.
- I18n: all copy in 6 locales; confirmation word stays literally `DELETE` everywhere.

### States
- **Success:** account gone, logged out, root redirect + toast. **Error:** wrong/absent confirmation → inline error, nothing deleted. **Empty/Loading:** n/a.

## Acceptance criteria
- [ ] Modal matches mockup (icon, copy, disabled-until-DELETE button, Cancel).
- [ ] DELETE with wrong confirmation (or forged request without it) deletes nothing and shows an error.
- [ ] Confirmed deletion removes user + sessions + characters (+ character_masteries/skills), signs out, redirects to root.
- [ ] Other concurrent sessions of the deleted user are invalidated (rows destroyed).
- [ ] `.btn-danger` + danger card documented in the design system.
- [ ] Spec 09 + i18n updated; `bin/i18n-check` green; tests green (`PARALLEL_WORKERS=1`); browser-validated.

## Testing strategy (TDD — tests first)
1. **Service:** wrong confirmation → failure, user persists; correct → user + dependents gone (assert counts).
2. **Integration:** DELETE without confirmation param → error, still logged in; with `DELETE` → redirect to root (follow-redirect loop), session cookie invalid on next request, records gone.

## Best practices
- Server-side confirmation check is the gate; the disabled button is UX only.
- Destructive action — double-check `dependent: :destroy` chain in a test rather than assuming (character_masteries/skills hang off Character).

## Recommended LLM model
**Sonnet** — small feature but destructive path deserves careful tests.

## Commit strategy
Branch `feat/030-delete-account`. Commits:
1. `test: delete account service and flow`
2. `feat: delete account service with typed confirmation`
3. `feat: danger button and card design-system components`
4. `feat: delete account card and confirmation modal`
5. `docs: spec 09 deletion rules + i18n keys (6 locales)`
