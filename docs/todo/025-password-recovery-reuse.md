# 025 — password-recovery-reuse

> **How agents use this:** swap the hand-rolled password inputs on the Password Recovery reset page (`app/views/passwords/edit.html.erb`) for the shared `shared/_password_fields` partial from 024, gaining the live rules checklist there. Pure view refactor + reuse — **no behavior change** to the reset flow (`PasswordsController#update` untouched except param names if needed).

## Execution order
After 024. Parallel with 026.

## Usage flow
1. User opens the emailed reset link → `passwords#edit`.
2. Page now renders `_password_fields` (new + confirm + hidden rules panel; appears on edit, same as settings).
3. Submit behaves exactly as today (token validation, sessions destroyed, redirect to login).

## References
- **Design system:** `.password-rules` (024).
- **Partials/code:** `app/views/passwords/edit.html.erb`, `app/views/shared/_password_fields.html.erb`, `app/controllers/passwords_controller.rb` (read-only reference).
- **Spec:** spec 09 cross-link from recovery section if spec text mentions the checklist; otherwise no spec change.

## Implementation scope
### Persistence / Backend
None (param names must keep matching what `PasswordsController#update` expects — parameterize the partial's field names via locals if they differ).

### Frontend
- Replace the two inputs in `passwords/edit.html.erb` with the shared partial; keep `maxlength: 72`.
- I18n: reuse 024 keys; add any recovery-specific labels in 6 locales.

### States
Same as today; rules panel hidden until edit.

## Acceptance criteria
- [ ] Reset page uses `shared/_password_fields`; duplicate markup deleted.
- [ ] Rules checklist works on the reset page (browser-validated).
- [ ] Existing password-reset integration tests still green unchanged (or updated only for markup assertions).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; `bin/i18n-check` green.

## Testing strategy (TDD — tests first)
1. Integration: `passwords#edit` markup contains the rules panel; full reset flow (request → email token → update → login redirect) still passes.

## Best practices
- Refactor-only PR — one responsibility, tiny diff (pr-sizing doc).

## Recommended LLM model
**Haiku** — mechanical partial swap.

## Commit strategy
Branch `refactor/025-password-recovery-reuse`. Commits:
1. `test: reset page renders shared password fields`
2. `refactor: reuse password fields partial on password recovery`
