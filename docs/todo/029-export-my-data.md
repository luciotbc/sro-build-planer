# 029 — export-my-data

> **How agents use this:** the "Export my data" button (My data card) triggers a **background job** (Solid Queue) that builds CSVs, zips them into ONE archive named `Time.now.utc.strftime("srolabs_%Y%m%d%H%M%S.zip")`, and emails it to the user as an attachment. CSV only. `user.csv` must NOT contain the user id (or any uuid). One CSV per character named `{race}_{name}_{lvl}.csv` (e.g. `ch_BuckTBC_120.csv`). First background job and first zip usage in the repo — adds the `rubyzip` gem.

## Execution order
After 028 (button lives in that card). Last data task; parallel with 030.

## Usage flow
1. User clicks `⬇ Export my data` (ghost/secondary button in the My data card).
2. Controller enqueues `Users::ExportDataJob` (async) and immediately shows a toast: "We're preparing your export — you'll receive it by email."
3. Job builds, in memory or tmpfile:
   - `user.csv` — personal data only, **excluding id/uuid-like fields**: `email_address`, `email_confirmed_at`, `email_opt_in`, `created_at`. (No `password_digest`, no ids.)
   - one `#{race_code}_#{name}_#{current_level}.csv` per character (race code from `Race` — chinese → `ch`, european → `eu`; sanitize `name` for filesystem safety; level = `current_level`). Columns: `mastery name, mastery current level, mastery future level, skill group name, current skill level, future skill level` — one row per `CharacterSkill`, joined to its mastery's `CharacterMastery` levels ("future" = the `target_*` fields).
4. Zips all CSVs → `srolabs_YYYYMMDDHHMMSS.zip` (UTC) → `UsersMailer#data_export` with the zip attached → `deliver_now` inside the job (already async).
5. Duplicate filename collision (two chars, same race/name/level) → suffix `_2`, `_3`, ….

## References
- **Mockup:** `account_settings.html` — button in My data card.
- **Design system:** `btn-ghost` + download icon (`icon-btn` style); no new component expected.
- **Code to reuse:** `Character` associations (`character_masteries` → `current_mastery_level`/`target_mastery_level`; `character_skills` → `skill_group.name`, `current_skill_level`/`target_skill_level`); Solid Queue configured (`config/queue.yml`); `ApplicationJob`; mailer pattern (`UsersMailer`). CSV via Ruby stdlib `csv`.
- **New dependency:** `rubyzip` (Gemfile) — flag in PR.
- **Spec:** spec 09 — export contents, exclusions (no ids/uuid/password data), delivery channel, filename patterns.

## Implementation scope
### Persistence
None (no export tracking table — fire-and-forget; note as future hardening if abuse appears).

### Backend
- `Users::ExportDataService` (pure: user → `{filename => csv_string}` + zip bytes) — unit-testable without job/mailer.
- `Users::ExportDataJob < ApplicationJob` — calls service, sends mail.
- `UsersMailer#data_export` (+ html/text views) with zip attachment.
- `Settings::ExportsController#create` — enqueue + toast. Rate-limit (e.g. 1 per 10 min) as harden commit.

### Frontend
- Button (form POST) in the My data card; toast on enqueue.
- I18n: button label, toast, mail subject/body in 6 locales (game jargon — Mastery, Skill — stays English in CSV headers: headers are data, keep them English-only, note in spec).

### States
- **Success:** toast; email with zip. **Error:** job retries per Solid Queue defaults; enqueue failure → error toast. **Empty:** user with 0 characters gets zip with only `user.csv`; character with no skills → header-only CSV.

## Acceptance criteria
- [ ] Click enqueues the job (no synchronous export) and shows the toast.
- [ ] Zip name matches `srolabs_\d{14}\.zip` (UTC); attached to one email to the user.
- [ ] `user.csv` contains the personal fields and NO id/uuid column.
- [ ] Character CSVs named `{ch|eu}_{name}_{level}.csv` with the 6 specified columns; values match `CharacterMastery`/`CharacterSkill` current/target fields; name collisions suffixed.
- [ ] Empty-data edge cases don't crash.
- [ ] Spec 09 + i18n updated; `bin/i18n-check` green; tests green (`PARALLEL_WORKERS=1`); browser-validated (toast).

## Testing strategy (TDD — tests first)
1. **Service:** filenames, exclusion of ids, CSV rows for a factory character with masteries+skills; zip readable (Zip::File round-trip); collision suffixing; empty cases.
2. **Job:** performs → one mail with correctly-named attachment (`assert_emails`).
3. **Integration:** POST enqueues (`assert_enqueued_with`), toast rendered; anonymous → login redirect.

## Best practices
- Keep zip bytes in memory (small data); don't write to public dirs.
- If service+job+mailer+UI exceed 400 LOC, stack: PR-1 service (pure), PR-2 job+mailer+button.

## Recommended LLM model
**Opus** — multi-layer feature (service/job/mailer/zip) with data-mapping subtleties.

## Commit strategy
Branch `feat/029-export-my-data`. Commits:
1. `test: export data service csv and zip contents`
2. `feat: export data service building user and character csvs`
3. `feat: export data job and mailer with zip attachment`
4. `feat: export my data button on settings page`
5. `fix: rate limit export requests`
6. `docs: spec 09 export rules + i18n keys (6 locales)`
