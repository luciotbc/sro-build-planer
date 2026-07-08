# 028 — my-data-summary

> **How agents use this:** the "My data" card — a read-only description list of account facts. The "Export my data" button lives in this card visually but its behavior is task 029; this task renders the card WITHOUT the button (029 adds it) to keep scopes disjoint. **Data decision:** there is no `terms_accepted_at` column; terms are accepted at registration (checked by `Users::RegisterService`), so "Terms & Privacy Policy accepted" displays `user.created_at` — record this rule in spec 09. Do not add a column (scope).

## Execution order
After 022. Blocks 029. Parallel with 023/024/027/030.

## Usage flow
1. Card "My data", description "A summary of the data associated with your account.".
2. Rows (label left, bold value right, hairline separators): `Email address` → `email_address`; `Account created` → `created_at` (e.g. "March 12, 2023", localized via `l(date, format: :long)`); `Terms & Privacy Policy accepted` → `created_at`; `Total characters created` → `user.characters.count`.

## References
- **Mockup:** `account_settings.html` — fourth card.
- **Design system:** `_settings_card`; row styling — check `.stat-line`/`.stat-merged` first; they are game-stat-specific, so likely a small new `.data-row` component class → document it (`/design-sync`) if added.
- **Spec:** spec 09 — add the terms-date-equals-created-at rule and the row inventory.

## Implementation scope
### Persistence / Backend
None (controller already exposes `Current.user`; counts via association).

### Frontend
- Rows partial (local to `app/views/settings/`) or inline in a `_settings_card` block.
- Date localization: `date.formats.long` present in all 6 locales; "jargon stays English" does not apply to dates.

### States
- **Empty:** zero characters shows `0` (no crash). Others n/a.

## Acceptance criteria
- [ ] Card renders the four rows with correct live values; matches mockup layout.
- [ ] Dates localized per locale files.
- [ ] Spec 09 + i18n updated; `bin/i18n-check` green; tests green (`PARALLEL_WORKERS=1`); browser-validated.

## Testing strategy (TDD — tests first)
1. Integration: settings page body contains email, formatted created date (twice), and character count for a user with N characters (FactoryBot `create_list`); 0-character case.

## Best practices
- Pure display — no service, no queries beyond `characters.count` (use `size`/counter awareness; `count` fine here).

## Recommended LLM model
**Haiku** — static display card.

## Commit strategy
Branch `feat/028-my-data-summary`. Commits:
1. `test: my data summary rows`
2. `feat: my data summary card on settings page`
3. `docs: spec 09 my-data rules + i18n keys (6 locales)`
