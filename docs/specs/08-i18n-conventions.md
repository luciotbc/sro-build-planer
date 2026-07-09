# 08 — i18n Conventions

> **How agents use this:** every user-facing string in `/app` MUST live in `config/locales/en.yml` — never hardcode text in views, controllers, services, mailers, or model validations. Follow the key conventions below when adding text. `test/i18n_test.rb` enforces no-missing / no-unused / normalized keys via `i18n-tasks`; `bin/i18n-check` (read-only: missing, unused, consistent interpolations, normalized) is the shared gate run by CI (`lint` job + `bin/ci`) and the `pre-push` git hook — it never edits locale files, fixes are manual against the `en.yml` source of truth.

## Rules

| # | Rule |
|---|---|
| R1 | English (`en`) is the default locale. Available locales: `en`, `pt-BR`, `es`, `tr`, `ko`, `zh-CN` (`config.i18n.available_locales`). Test fixtures/factories stay English; tests may assert literal English text (tests run under `en` unless they set an `Accept-Language` header). |
| R2 | Views and controllers use **lazy lookup**: `t(".key")` resolves via view path (`characters/show` → `characters.show.key`) or controller/action (`CharactersController#create` → `characters.create.key`). |
| R3 | Keys shared across a controller's actions live at the controller root (e.g. `passwords.invalid_token`). |
| R4 | Shared partials resolve lazily under `shared.*` (e.g. `shared/_char_bar` → `shared.char_bar.*`). Truly global strings: `shared.close`, `shared.log_out`, `app.name`. |
| R5 | Cross-cutting flash text lives under `flash.` (e.g. `flash.rate_limited`). |
| R6 | Service-layer error strings live under `errors.` with interpolation (e.g. `errors.skill_level.above_max`). Service warnings live under `warnings.`. |
| R7 | Mailer subjects resolve implicitly via `default_i18n_subject` (`<mailer_underscored>.<action>.subject`) — do not pass `subject:` to `mail`. Mailer body keys live in the same scope. Transactional emails render (subject + body) in the recipient's saved `users.locale`: `ApplicationMailer#mail` wraps rendering in `I18n.with_locale(@user&.locale.presence || I18n.default_locale)`, so it holds under `deliver_later` (the delivery job does not carry the request locale). Every mailer sets `@user` before calling `mail`. |
| R8 | Strings interpolating HTML use an `_html` key suffix (auto-marked html_safe); interpolated values must themselves be safe (`tag.*` / `link_to` output). Never embed CSS classes in locale values. |
| R9 | Model validation messages prefer built-in ActiveModel keys (e.g. `errors.add(:attr, :less_than_or_equal_to, count: cap)`) over custom strings. |
| R10 | `config.i18n.raise_on_missing_translations = true` in development and test — a missing key is a test failure, not a silent fallback. |
| R11 | `config/locales/en.yml` is kept normalized (`bundle exec i18n-tasks normalize`); false-positive "unused" keys (implicit subjects, multiline `I18n.t` calls) are listed in `config/i18n-tasks.yml` `ignore_unused` with a comment. |
| R12 | The request locale is resolved by `LocaleDetection` (`app/controllers/concerns/locale_detection.rb`, `around_action` on `ApplicationController`) in precedence order: **(1)** the signed-in user's saved `users.locale` when present and supported (`Current.user&.locale`; the session is resumed inside the concern so this applies on `allow_unauthenticated_access` pages too); **(2)** a guest's session-stored choice (`session[:locale]`, when supported) — set when a signed-out visitor picks a language from the footer switcher; **(3)** the browser's `Accept-Language` header (no IP/geo, no locale in URLs) — tags sorted by `q`, exact case-insensitive match first (`pt-BR` → `pt-BR`), then language-only match (`pt` → `pt-BR`, `en-US` → `en`, `zh-Hans` → `zh-CN`); **(4)** else `en`. `I18n.with_locale` scopes it to the request. Anyone sets the language from the footer switcher or (signed in) the topbar language submenu (`PATCH /settings/locale` → `Users::UpdateLocaleService`, `allow_unauthenticated_access`): the controller always stores the choice in `session[:locale]` and, when signed in, also persists it to `users.locale` (so a saved account preference always wins over the session on the next visit). A new account captures the locale being rendered at sign-up (`Users::RegisterService`); flag + native-name display metadata lives in `LocaleOption`, never in locale files. |
| R13 | Missing translations in non-`en` locales fall back to `en` (`config.i18n.fallbacks = [:en]`) — never raise for a key that exists in `en`. |
| R14 | **Game jargon stays in English in every locale.** Terms listed in [game-jargon.md](game-jargon.md) (Mastery, Skill, SP, Build, Level Cap, …) are never translated — inflect the sentence around the English term (pt-BR "level da mastery", not "nível da maestria"). When translating reveals a new jargon term, add it to [game-jargon.md](game-jargon.md) in the same change. |

## Out of scope

- `app/views/docs/**` (development-only design-system reference) stays hardcoded.
- `app/views/pages/**` (public static legal pages — Privacy Policy, Terms of Service) render long-form copy **inline in per-locale view partials** (`pages/terms/_en`, `pages/terms/_pt_br`, …), not via locale files — legal prose is impractical in YAML. Only the short chrome (page `title`, footer link labels) lives under `pages.*` in `en.yml`. The view picks the partial by `I18n.locale`, falling back to English (R13).
- Game data names (masteries, skills, races) come from the database, not locale files.
- `app/views/pwa/**` — PWA routes are disabled in `config/routes.rb`; extract when enabled.
- Design-system-only demo partials (`shared/_modal`, `_drawer`, `_sheet`, `_skill_row`, `_legend_badge`, `_chars_pill`) keep literal defaults until used in production views.
