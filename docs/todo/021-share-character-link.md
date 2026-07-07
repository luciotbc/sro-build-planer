# 021 — share-character-link

> **How agents use this:** add a public, read-only "shared build" page reachable by a UUID link, plus a share (copy-link) icon on the owner's planner. New route/controller/view — **zero edit affordances** on the public page. Data is live (renders current build state, no snapshot). Specs govern business rules; DS governs visuals. Per GR3, spec 05 must gain the new sharing rules in the same change.

## Execution order
After 020 (edit-character-modal). No other open dependencies.

## Objective
Let a player share a link to a character so anyone — including unauthenticated visitors — can view (not edit) the build, with rich OG tags for link previews.

## Usage flow
1. Every `Character` carries a permanent `share_token` (UUIDv4), auto-generated on create and backfilled for existing rows. Not regenerable, not revocable (scope decision).
2. On `characters#show`, the owner sees a share icon in the char bar; clicking it copies the public URL to the clipboard and shows a confirmation toast.
3. Anyone opening `/shared/:share_token` — logged in or not — sees the read-only shared-build page.
4. Unknown/invalid token → 404.

## References
- **Design system:** `.char-bar`, `.icon-btn`, `.stats-summary` panel, skill grid components, toast (`/docs/design_system`).
- **Partials:** `app/views/shared/_char_bar.html.erb` (share trigger + reuse on public page), `app/views/shared/_stats_summary.html.erb`, `app/views/characters/show.html.erb` (source of the read-only skills view), `app/views/layouts/application.html.erb` (meta tags).
- **Spec:** [05-character-lifecycle](../specs/05-character-lifecycle.md) — **add new rules** (share token lifecycle, public read-only access, 404 on bad token) per GR3; [02-sp-and-summary](../specs/02-sp-and-summary.md) (summary shown on the page).
- **Helper:** `race_icon_tag` in `app/helpers/application_helper.rb` (OG image source: china.png / europe.png).

## Implementation scope
### Persistence
- Migration: `add_column :characters, :share_token, :string, null: false` + unique index. Backfill existing rows with `SecureRandom.uuid` inside the migration; model `before_create` (or `has_secure_token`-style callback generating a UUID) for new rows.
- `db/schema.rb` committed with the migration.

### Backend
- Route: `get "shared/:share_token" => "shared_builds#show", as: :shared_build`.
- New `SharedBuildsController#show`: `allow_unauthenticated_access`, finds `Character.find_by!(share_token: params[:share_token])` (404 via `RecordNotFound`), loads the same read-only build data `characters#show` uses (masteries, skill grid, `@summary`). Extract shared loading into a service/query object or shared private concern if `characters#show` logic would otherwise be duplicated — controllers stay thin.
- No mutating routes; controller exposes only `show`.

### Frontend
- **Share icon (owner):** `icon-btn` in `_char_bar` on `characters#show` (opt-in local, same pattern as the 020 pencil — other call sites unaffected). Small Stimulus `clipboard` controller: `navigator.clipboard.writeText`, then success toast/tooltip. `data` holds the full `shared_build_url(character.share_token)`.
- **Shared page `app/views/shared_builds/show.html.erb`:** shows —
  - the share link itself (read-only input + copy button, same clipboard controller),
  - avatar (race crest), character name, level cap (`_char_bar` without `editable`/edit affordances),
  - the skills view (mastery tabs + skill grid) in **pure read-only** form — no steppers, bulk actions, edit pencil, or PATCH forms; reuse/parameterize existing partials rather than forking where feasible,
  - the stats summary (`_stats_summary`).
- **OG tags:** layout gains `content_for`-driven meta; shared page sets:
  - `og:title` — character name,
  - `og:image` — absolute URL of the race crest (china.png / europe.png via asset URL helper),
  - `og:description` — one line per chosen mastery: `"<Mastery> <current_lvl> → <target_lvl>"`, newline-joined,
  - plus `og:type`, `og:url` (the shared URL). Other pages keep no OG tags (or sensible defaults) — layout must not break when `content_for` absent.
- I18n: new keys (`shared_builds.show.*`, share button label/tooltip, copied toast) in **all 6 locales**; jargon (Mastery, Skill, SP, Level Cap, Build) stays English (spec 08 R14).

### States
- **Success:** page renders for anonymous visitor; copy click → toast.
- **Error:** invalid token → 404 page.
- **Empty:** character with no masteries/skills renders gracefully (empty summary, no crash); OG description empty-safe.
- **Loading:** n/a (server-rendered).

## Acceptance criteria
- [ ] Existing and new characters all have a unique UUID `share_token`.
- [ ] Share icon on owner's `characters#show` copies `.../shared/<uuid>` to clipboard with visual confirmation; icon absent on other `char_bar` call sites.
- [ ] `/shared/:share_token` renders for an **unauthenticated** visitor: share link field, avatar, name, cap, read-only skills view, summary.
- [ ] Page contains no edit affordances: no steppers, bulk-action buttons, edit pencil, or forms that mutate (copy-link form excepted); direct PATCH/POST attempts on character resources still require auth/ownership as today.
- [ ] Invalid token returns 404.
- [ ] OG tags present with race-crest image (absolute URL), character-name title, per-mastery `lvl → lvl` description lines.
- [ ] Live data: owner edits then reload of shared page shows updated build.
- [ ] Spec 05 updated with the sharing rules + spec README index (GR3); all 6 locales updated; `bin/i18n-check` passes.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; no console errors; DS conformance; browser-validated.

## Testing strategy (TDD — tests first)
1. **Model:** share_token auto-generated on create; uniqueness.
2. **Integration (`ActionDispatch::IntegrationTest`, unauthenticated):** GET shared page → 200 with name/summary markup; invalid token → 404; page body contains no stepper/bulk-action/edit markup; OG meta tags present with expected title/description/image.
3. **Integration (owner):** share icon markup on `characters#show`; absent for other char_bar call sites.
4. Follow-redirect quirk n/a (direct GETs), but keep `class X < ActionDispatch::IntegrationTest` form.

## Best practices
- Reuse existing partials via locals (e.g. `read_only: true`) instead of forking views; if forking is unavoidable, note it in the PR.
- Token in URL is the only credential — never render owner email/user data on the public page.
- `bin/rails tailwindcss:build` after CSS/template edits; ERB comment + conditional-attr rules apply.
- Watch PR size (≤400 LOC, ≤15 files). If the read-only extraction of the skills view balloons, split: PR-1 token + controller + minimal page, PR-2 full skills view + OG (stacked PRs).

## Recommended LLM model
**Sonnet** — mostly view reuse + one controller; the only subtle part is parameterizing existing partials as read-only.

## Commit strategy
Branch `feat/021-share-character-link`. Commits:
1. `test: shared build page, share token, OG tags`
2. `feat: add share_token uuid to characters with backfill`
3. `feat: public read-only shared build route and page`
4. `feat: share icon with clipboard copy on planner char bar`
5. `feat: og meta tags for shared build page`
6. `docs: spec 05 sharing rules + i18n keys (6 locales)`
