# 08 — i18n Conventions

> **How agents use this:** every user-facing string in `/app` MUST live in `config/locales/en.yml` — never hardcode text in views, controllers, services, mailers, or model validations. Follow the key conventions below when adding text. `test/i18n_test.rb` enforces no-missing / no-unused / normalized keys via `i18n-tasks`.

## Rules

| # | Rule |
|---|---|
| R1 | English (`en`) is the default locale. Available locales: `en`, `pt-BR`, `es`, `tr`, `ko`, `zh-CN` (`config.i18n.available_locales`). Test fixtures/factories stay English; tests may assert literal English text (tests run under `en` unless they set an `Accept-Language` header). |
| R2 | Views and controllers use **lazy lookup**: `t(".key")` resolves via view path (`characters/show` → `characters.show.key`) or controller/action (`CharactersController#create` → `characters.create.key`). |
| R3 | Keys shared across a controller's actions live at the controller root (e.g. `passwords.invalid_token`). |
| R4 | Shared partials resolve lazily under `shared.*` (e.g. `shared/_char_bar` → `shared.char_bar.*`). Truly global strings: `shared.close`, `shared.log_out`, `app.name`. |
| R5 | Cross-cutting flash text lives under `flash.` (e.g. `flash.rate_limited`). |
| R6 | Service-layer error strings live under `errors.` with interpolation (e.g. `errors.skill_level.above_max`). Service warnings live under `warnings.`. |
| R7 | Mailer subjects resolve implicitly via `default_i18n_subject` (`<mailer_underscored>.<action>.subject`) — do not pass `subject:` to `mail`. Mailer body keys live in the same scope. |
| R8 | Strings interpolating HTML use an `_html` key suffix (auto-marked html_safe); interpolated values must themselves be safe (`tag.*` / `link_to` output). Never embed CSS classes in locale values. |
| R9 | Model validation messages prefer built-in ActiveModel keys (e.g. `errors.add(:attr, :less_than_or_equal_to, count: cap)`) over custom strings. |
| R10 | `config.i18n.raise_on_missing_translations = true` in development and test — a missing key is a test failure, not a silent fallback. |
| R11 | `config/locales/en.yml` is kept normalized (`bundle exec i18n-tasks normalize`); false-positive "unused" keys (implicit subjects, multiline `I18n.t` calls) are listed in `config/i18n-tasks.yml` `ignore_unused` with a comment. |
| R12 | The request locale is detected from the browser's `Accept-Language` header only (no IP/geo/cookies, no locale in URLs) by `LocaleDetection` (`app/controllers/concerns/locale_detection.rb`, `around_action` on `ApplicationController`): tags sorted by `q`, exact case-insensitive match first (`pt-BR` → `pt-BR`), then language-only match (`pt` → `pt-BR`, `en-US` → `en`, `zh-Hans` → `zh-CN`), else `en`. `I18n.with_locale` scopes it to the request. |
| R13 | Missing translations in non-`en` locales fall back to `en` (`config.i18n.fallbacks = [:en]`) — never raise for a key that exists in `en`. |

## Out of scope

- `app/views/docs/**` (development-only design-system reference) stays hardcoded.
- Game data names (masteries, skills, races) come from the database, not locale files.
- `app/views/pwa/**` — PWA routes are disabled in `config/routes.rb`; extract when enabled.
- Design-system-only demo partials (`shared/_modal`, `_drawer`, `_sheet`, `_skill_row`, `_legend_badge`, `_chars_pill`) keep literal defaults until used in production views.
