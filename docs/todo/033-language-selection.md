# 033 — language-selection

> **How agents use this:** add a **Language** entry to the topbar user menu (task 032) that lets an authenticated user pick the application locale and **persists it on their `User` record**. The saved locale then drives (1) every future request while logged in, (2) transactional emails, and (3) the default captured at sign-up. This **revises spec [08](../specs/08-i18n-conventions.md) R12** (request-locale precedence gains a "logged-in user's saved locale wins" step) — reconcile the spec in the same change (GR3). Visual/interaction is governed by the `character_show.html` mockup (design project `e76dd313-b147-4234-8ac9-4f3d80c3f9e0`, open the user menu → **Language**) — read it JIT via **Claude-in-Chrome** (workflow rule 14), not WebFetch (Cloudflare-gated).

## Execution order
Depends on: 032 (user-settings menu + `menu` component/Stimulus controller + `shared/_user_menu`), and the existing `LocaleDetection` concern (spec 08 R12). Independent of 023–031. No blockers downstream.

## Objective
An authenticated user opens the topbar user menu, hovers/activates **Language**, and picks one of the 6 supported locales from a flyout submenu. The choice is saved on `users.locale` and takes effect immediately (page re-renders localized). On every later login the app renders in the saved locale; transactional emails are sent in it; and a brand-new account defaults to whatever locale was being shown at sign-up.

## Usage flow
1. Logged-in user opens the user menu; sees a **Language** item showing the **flag of the currently-active locale** on the right and a submenu affordance (`◀`, opens to the left per mockup).
2. Activating **Language** opens a flyout submenu listing all 6 locales, each row: `flag · native name · code` (the code as secondary `text-text-dim` text); the active locale row carries a check mark.
3. Selecting a row submits the change (`PATCH /settings/locale`), the menu closes, and the page reloads in the chosen locale.
4. Every subsequent request (this session and future logins) renders in the saved locale.
5. Transactional emails (email confirmation, password reset, data export) render in the saved locale.

## References
- **Mockup:** `character_show.html` (design project `e76dd313-b147-4234-8ac9-4f3d80c3f9e0`) — user menu → Language submenu. Read via Claude-in-Chrome (rule 14); rendered mockup is a cross-origin iframe → capture via screenshots.
- **Design system:** extends the existing `menu` component (task 032). Add a **submenu / flyout** treatment: `.menu-submenu` (positioning context), `.menu-submenu-trigger`, `.submenu-panel` (opens `right: 100%`, auto-fits width — `white-space: nowrap`, no line wrap), `.menu-locale` row (`flag · name · code`), `.menu-locale-code` (`text-text-dim`), `.menu-locale-check`. Classes in `@layer components` (`app/assets/tailwind/application.css`). Nest a second `data-controller="menu"` for the flyout — the existing controller already handles toggle / Esc / outside-click / `aria-expanded`. Re-run `/design-sync` if the DS page needs the new component (workflow rule 11).
- **Partials:** `app/views/shared/_user_menu.html.erb` — insert the **Language** submenu above **Account settings**.
- **Spec:** revise [`docs/specs/08-i18n-conventions.md`](../specs/08-i18n-conventions.md) **R12** (add the saved-locale precedence step) and refresh the spec README index if wording changes (GR3). Game jargon stays English in every locale (spec 08 R14) — no new translatable jargon.
- **I18n:** add `shared.user_menu.language` (item label) + `settings.locales.update.*` (flash) in **all 6 locales** (en, es, ko, pt-BR, tr, zh-CN). Native language names + flags are **display data, not translated strings** — they live in a single source-of-truth `LocaleOption` map, never in locale files.

## Implementation scope
### Persistence
- Migration: add `locale` (`string`, nullable, no default) to `users`. `nil` = "not chosen" → fall through to browser detection. Commit migration + `db/schema.rb` together.

### Backend
- **`User`**: validate `locale` inclusion in `I18n.available_locales.map(&:to_s)`, `allow_nil: true`.
- **`LocaleOption`** (`app/models/locale_option.rb`): plain module holding `{ code, flag, native_name }` for each supported locale, ordered by code; `.all`, `.flag(code)`. A test asserts parity with `I18n.available_locales`.
- **`Users::UpdateLocaleService`** (`ServiceResult`): assigns and saves `user.locale`; unsupported values fail via the model validation.
- **`Users::RegisterService`**: set `locale: I18n.locale.to_s` on `User.new` (captures the locale being rendered at sign-up).
- **`LocaleDetection`** (revises spec 08 R12): request locale precedence becomes **(1)** signed-in user's saved `locale` (if present & supported) → **(2)** browser `Accept-Language` match → **(3)** `I18n.default_locale`. Resume the session inside the concern so the saved locale also applies on `allow_unauthenticated_access` pages (e.g. the post-login landing redirect). Keep the concern the single source of truth.
- **`ApplicationMailer`**: wrap `mail` in `I18n.with_locale(@user&.locale.presence || I18n.default_locale)` so every mailer renders its subject + body in the recipient's locale (works with `deliver_later` — the job does not carry request locale). All mailers already set `@user`.
- **Route/controller:** `namespace :settings { resource :locale, only: :update }` → thin `Settings::LocalesController#update` calling the service and `redirect_back fallback_location: root_path` with a localized flash.

### Frontend
- `shared/_user_menu.html.erb`: add a **Language** submenu (nested `data-controller="menu"`). Trigger shows `t(".language")` + the active locale's flag (`LocaleOption.flag(I18n.locale)`). Flyout lists `LocaleOption.all`: each a `button_to settings_locale_path, method: :patch, params: { locale: opt.code }` rendering flag + native name + code (`.menu-locale-code`, `text-text-dim`) + check mark on the active locale.
- CSS: `.menu-submenu`, `.menu-submenu-trigger`, `.submenu-panel` (`right: 100%`, `white-space: nowrap`), `.menu-locale`, `.menu-locale-code`, `.menu-locale-check`. Rebuild: `bin/rails tailwindcss:build` (watcher dies in the sandbox).

### Accessibility
Submenu trigger: `aria-haspopup="menu"`, `aria-expanded` (handled by the reused `menu` controller). Locale rows are real submit buttons (keyboard-focusable, CSRF-safe forms). Active locale conveyed by the check mark.

### States
- **Success:** row check moves to the chosen locale, page re-renders localized, flash confirm.
- **Error:** unsupported locale rejected by the model/service; existing selection unchanged; alert flash.
- **Empty/Loading:** n/a (server-rendered).
- **Logged-out:** menu absent (unchanged); anonymous users keep browser `Accept-Language` detection.

## Acceptance criteria
- [ ] `users.locale` column exists (nullable); `User` validates inclusion, allows `nil`.
- [ ] Signed-in user's saved locale overrides `Accept-Language`; `nil` saved locale falls back to `Accept-Language`; anonymous unchanged (spec 08 R12 revised).
- [ ] New accounts persist the locale active at sign-up (`Users::RegisterService`).
- [ ] `PATCH /settings/locale` with a supported code persists it and redirects back localized; an unsupported code is rejected and leaves the selection unchanged.
- [ ] Transactional emails render subject + body in the recipient's saved locale.
- [ ] User menu shows a **Language** item with the active locale's flag; the flyout lists all 6 locales as `flag · native name · code` (code in `text-text-dim`), check mark on the active one, ordered by code, no line wrapping.
- [ ] `LocaleOption` map is in parity with `I18n.available_locales`.
- [ ] Spec 08 R12 reconciled + README index in sync (GR3); all 6 locales updated; `bin/i18n-check` passes.
- [ ] Faithful to the `character_show.html` mockup + DS.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; browser-validated (Chrome); no console errors.

## Testing strategy (TDD — tests first)
1. **Model** (`user_test`): `locale` inclusion (accept `"pt-BR"`, reject `"xx"`, allow `nil`).
2. **`LocaleOption`**: `.all` ordered by code and in parity with `I18n.available_locales`; `.flag` lookup.
3. **`Users::UpdateLocaleService`**: updates a supported locale; fails on an unsupported one (no change persisted).
4. **`Users::RegisterService`**: created user's `locale == I18n.locale` (assert under a non-`en` `I18n.with_locale`).
5. **`LocaleDetection`** (integration): signed-in user with saved `locale` overrides `Accept-Language`; `nil` saved locale → `Accept-Language`; anonymous → existing behavior (extend the current suite).
6. **Mailer** (`users_mailer_test`): with `user.locale = "pt-BR"`, `email_confirmation` subject is the pt-BR subject (localized rendering).
7. **`Settings::LocalesController`**: authenticated `PATCH` persists + redirects back; unsupported code rejected; unauthenticated blocked.
8. **Menu render** (integration): signed-in GET of a layout page renders the Language item + the active flag + all 6 locale options.
9. Run `PARALLEL_WORKERS=1 bin/rails test`; `bin/rubocop`; `bin/i18n-check`.

## Best practices
DS-first (extend the `menu` component + reuse its controller, don't fork it); business logic in a `ServiceResult` service; keep `LocaleDetection` the single locale source; flags/native names as data (never locale strings); `button_to` PATCH (CSRF-safe, non-GET); I18n across 6 locales; reconcile spec 08 R12 in the same PR (GR3); rebuild Tailwind after CSS edits.

## Recommended LLM model
**Sonnet** — small vertical slice (one column, one service, one thin controller, a submenu partial + CSS) over well-established patterns; the only subtlety is mailer-locale wrapping and the R12 precedence revision.

## Commit strategy
Branch `feat/033-language-selection`. Commits:
1. `test: language-selection (model, service, locale precedence, mailer, menu)`
2. `feat: persist users.locale + LocaleOption metadata`
3. `feat: saved-locale precedence in LocaleDetection + localized mailers`
4. `feat: language submenu in the user menu + settings/locale endpoint`
5. `docs: reconcile spec 08 R12 + i18n keys (6 locales)`
