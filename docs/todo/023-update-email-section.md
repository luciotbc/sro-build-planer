# 023 — update-email-section

> **How agents use this:** the "Update email" card on `/settings`. Changing the email invalidates the previous confirmation and forces re-verification via the existing `email_confirmation` flow. Inline validation message on invalid email. Specs govern business rules; add the new rules to spec 09 per GR3.

## Execution order
After 022 (page shell). Parallel with 024/027/028/030.

## Usage flow
1. Card "Update email" shows description "Your login email and where we send important account notices.", label `CURRENT EMAIL`, a text input prefilled with `Current.user.email_address`, and a `Save email` primary button.
2. User edits the email and saves.
3. Invalid format / blank / already-taken → inline validation message on the field (Turbo Stream replace of the form, same pattern as `registrations/_form`).
4. Valid + actually changed → email updated, `email_confirmed_at` reset to `nil`, confirmation email sent to the **new** address, success toast telling the user to verify the new email. Unchanged submit → no-op with neutral notice.
5. User stays logged in; clicking the emailed link confirms (existing `EmailConfirmationsController#show`).

## References
- **Mockup:** `account_settings.html` — first card.
- **Design system:** `_settings_card` (022), `btn-primary`, toast (`_toast`/`_error_toast`). **GAP — no labeled-input/field component**; inputs currently use inline Tailwind (see `registrations/_form.html.erb`). Reuse that inline style; do NOT invent a new component here (scope), but note the gap in the DS docs if not already noted.
- **Code to reuse:** `User#normalizes :email_address`, `User#generates_token_for :email_confirmation` + `confirm_email!` (`app/models/user.rb`); `UsersMailer#email_confirmation` (`app/mailers/users_mailer.rb`); Turbo-Stream inline error pattern from `registrations_controller.rb`.
- **Spec:** `docs/specs/09-account-settings.md` — add rules: email change ⇒ re-verification required; token invalidation (token embeds `email_confirmed_at`, so old links die automatically — state this).

## Implementation scope
### Persistence
None (uses existing `email_address`, `email_confirmed_at`).

### Backend
- `Users::UpdateEmailService.call(user:, email_address:)` → `ServiceResult`; validates via model, resets `email_confirmed_at`, sends `UsersMailer.email_confirmation.deliver_later`. No-change short-circuit (warning, no email sent).
- Controller: `Settings::EmailsController#update` (or `settings#update_email`) — thin, rate-limit like registration (harden commit).

### Frontend
- Form partial `app/views/settings/_email_form.html.erb` inside `_settings_card`; inline error rendering + field error state; Turbo Stream replace on failure, redirect + toast on success.
- I18n: success/verify-again/error messages in all 6 locales, English source.

### States
- **Success:** toast "check your new email to verify". **Error:** inline field message (format, taken, blank). **Empty/Loading:** n/a.

## Acceptance criteria
- [ ] Card matches mockup (labels, description, button).
- [ ] Invalid email shows inline validation message without page reload.
- [ ] Duplicate email fails without leaking which account owns it (generic message — enumeration guard).
- [ ] Successful change: `email_confirmed_at` is `nil`, confirmation mail enqueued to the new address, user still logged in.
- [ ] Old confirmation links (issued for the previous state) no longer work.
- [ ] Spec 09 + i18n (6 locales) updated; `bin/i18n-check` green.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; browser-validated.

## Testing strategy (TDD — tests first)
1. **Service:** valid change resets confirmation + enqueues mail (`assert_enqueued_email_with`); invalid format/taken → failure result, no mail; unchanged → success w/ warning, no mail.
2. **Integration:** PATCH as owner → redirect + flash; invalid → Turbo Stream with inline error; anonymous → login redirect (`follow_redirect!` loop before assertions).

## Best practices
- Business logic in the service (repo rule 5); controller thin.
- Feature-then-harden: happy path commit first, rate-limit/enumeration-guard follow-up commit.

## Recommended LLM model
**Sonnet** — established service + mailer patterns to copy.

## Commit strategy
Branch `feat/023-update-email`. Commits:
1. `test: update email service and settings flow`
2. `feat: update email service with re-verification`
3. `feat: update email card on settings page`
4. `fix: rate limit and enumeration guard for email update`
5. `docs: spec 09 email rules + i18n keys (6 locales)`
