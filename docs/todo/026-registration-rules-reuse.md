# 026 — registration-rules-reuse

> **How agents use this:** add the live password-rules checklist (024's `password-rules` Stimulus controller + `.password-rules` markup) to the **create-account modal** and the **create-account page**. Both render `app/views/registrations/_form.html.erb`, so this is one partial change. Registration has a single password field (no confirm) — the "Matching confirmation" rule item is omitted there (parameterize the partial/controller: confirmation rule only when a confirm field exists). Reveal-on-edit behavior identical.

## Execution order
After 024. Parallel with 025.

## Usage flow
1. User opens Create account (modal via topbar `_auth_modals`, or `/registration/new` page).
2. Starts typing in the password field → rules panel appears below it with the live checks (8+ chars, uppercase, number).
3. Server-side registration validation unchanged.

## References
- **Design system:** `.password-rules` (024).
- **Partials/code:** `app/views/registrations/_form.html.erb` (shared by page + modal `app/views/sessions/_auth_modals.html.erb`), `password_rules_controller.js`.
- **Spec:** none beyond spec 09 cross-link (registration rules live in `User` model; unchanged).

## Implementation scope
### Persistence / Backend
None.

### Frontend
- Extract the rules panel from `_password_fields` into its own sub-partial (e.g. `shared/_password_rules.html.erb`) if not already separate, so registration can use the panel without the confirm field; `_password_fields` renders it too (no duplication).
- Wire `password-rules` controller in `registrations/_form` (works inside the `dialog` modal — verify Stimulus scope inside `<dialog>`).
- Handle Turbo-Stream error re-render: panel state resets gracefully after form replace.
- I18n: reuse 024 keys.

### States
Hidden until edit; live toggling; unaffected by modal open/close cycles.

## Acceptance criteria
- [ ] Checklist appears on first edit in BOTH the modal and the page; rules limited to the 3 applicable items (no confirmation rule).
- [ ] Works after a failed submit re-renders the form via Turbo Stream.
- [ ] No visual regression in the modal (browser-validated, mockup conformance).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; `bin/i18n-check` green.

## Testing strategy (TDD — tests first)
1. Integration: registration page + modal markup include the rules panel bound to the controller; existing registration flow tests stay green.

## Best practices
- Partial parameterization over duplication; keep ERB conditional-attribute rule in mind (`<% if %>attr<% end %>`, not interpolated quotes).

## Recommended LLM model
**Haiku** — small view/controller-reuse change; Sonnet if the Turbo re-render edge gets fiddly.

## Commit strategy
Branch `feat/026-registration-password-rules`. Commits:
1. `test: registration form renders password rules panel`
2. `refactor: extract password rules panel sub-partial`
3. `feat: live password rules on registration modal and page`
