# 018 — Public landing page (anon home redesign)

## Execution order
Depends on: 004 (characters controller exists)
Run before: — (independent; ships after responsive mobile, design-system parity)

## Objective
Convert anonymous visitors at `/` (home#index) into registered users by showcasing core
functionality. Today the anon home renders nothing — only the topbar with "Log in". Add
a hero section with signup CTA, a live read-only build demo, three feature cards, and a
bottom call-to-action to drive account creation.

## Usage flow
1. Visitor lands on `/` (anon).
2. Hero pitch + "Create account" button (primary) and "Log in" (secondary) in topbar.
3. Read-only preview of a seeded demo character (Chinese Blader, Lv 1→80) with real
   SP costs from the database.
4. Three feature cards: full skill trees, exact SP math, multiple characters.
5. Bottom CTA band repeats signup.
6. Logged-in home behavior unchanged: auto-open create-character modal if no characters.

## References
- Specs: [01](../specs/01-level-and-progression.md) (SP cumulative cost), [05](../specs/05-character-lifecycle.md) (character/mastery/skill domain).
- Design System: `/docs/design_system` (live reference); reuse `_char_bar`, `_stats_summary`, `_skill_row`, `_mastery_header`, `_badge`, race glyphs from `app/views/shared`; width caps 520px (char-bar, skill-card), 380px (ro-tabs) per [project_ds_demo_maxwidth_caps](../memory/project_ds_demo_maxwidth_caps.md).
- Mockup: Landing page mockup (4 sections: hero, demo, cards, bottom CTA); design governed by DS, not mockup pixel-perf.
- Code: `app/views/home/index.html.erb` (today minimal), `app/views/shared/_topbar.html.erb` (auth area), `app/controllers/home_controller.rb`.

## Implementation scope

### FE
- **home/index.html.erb**: conditional render: if authenticated & no characters, show create-character modal (existing behavior); else (anon), render 4-section landing: hero (pitch + topbar CTAs) + demo section (read-only build UI) + 3 feature cards + bottom CTA band.
- **Topbar update** (`_topbar.html.erb`): anon state shows both "Log in" and "Create account" buttons; "Create account" is `btn-primary` (visually dominant); "Log in" is secondary/ghost. Both trigger existing `auth` Stimulus controller (`showLogin` / `showSignup` actions). Add `showSignup` action if missing.
- **Auth modal** (`_auth_modals`): ensure signup path opens directly (not login-first) when triggered from the landing-page hero CTA.
- **Partials reuse**: `_char_bar`, `_stats_summary`, `_skill_row`, `_mastery_header`, `_badge`, `_chinese_glyph` / `_european_glyph` — all read-only (no Stimulus editor targets).
- **No new CSS**: all styling via DS `@layer components` and Tailwind utilities; if a component is missing, add to DS, re-check `/design_system`, then use.

### BE
- **Demo build data**: seeded demo character (`spec/seeds/demo_build.rb` or embedded in `home_controller`). A `Character` owned by an internal demo user (or nil, marked demo flag) with a seeded mastery/skill layout. Reuse existing factories + seed data.
- **HomeController#index**: load demo character on first render (anon state); render into view context as `@demo_character`. No business logic change; lean controller.
- **No database changes**: demo character can be a real character in seeds or a read-only view model (either works; prefer seeds for simplicity).

### Testing strategy (TDD)
- **Unit**: demo character loads, renders without console errors, read-only (no form submissions).
- **Integration**: anon GET `/` returns 200, renders hero + demo + cards + CTA; logged-in (no chars) GET `/` returns 200, shows create-character modal; logged-in (with chars) GET `/` returns 200, does not auto-open modal (redirected elsewhere or shows list).
- **Browser (Chrome)**: hero CTA clicks open signup modal; demo section displays real skill data; no Stimulus-controller action firing (read-only); no console errors; DS width caps respected (char-bar ≤520px); responsiveness on tablet (768px) and mobile (375px).

## Acceptance criteria
- [ ] Hero section: one-line pitch + primary "Create account" CTA + secondary "Log in".
- [ ] Demo build section: reads real character/mastery/skill data; displays char-bar, stats, skill rows; real `LevelDatum.sp_cumulative` numbers shown; no form submissions (read-only UI).
- [ ] Three feature cards: full skill trees, exact SP math, multiple characters; use DS components + race glyphs.
- [ ] Bottom CTA band: repeats signup button.
- [ ] Logged-in home behavior unchanged: create-character modal auto-opens for users with no characters; no change to logged-in-with-characters state.
- [ ] Topbar: anon state shows both "Log in" + "Create account"; "Create account" is `btn-primary`.
- [ ] Auth modal: signup CTA from hero opens signup form directly (not login-first).
- [ ] No console errors (Chrome DevTools).
- [ ] DS conformance: width caps respected, existing partials reused, no new CSS unless a DS component is missing.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; `bin/rubocop` clean; `bin/brakeman` clean.
- [ ] Responsive: hero, demo, cards, CTA all visually correct at tablet (768px) and mobile (375px).
- [ ] Specs README unchanged, or updated if a rule changed (GR3).

## Best practices
- Reuse existing partials; do not invent new styles. If a component doesn't exist, add it to the DS partials + re-run `/design-sync` so the published DS stays in sync (GR2).
- Demo data in seeds, not hardcoded HTML (keep views clean, data testable).
- Controller thin: `@demo_character = Character.find_by(demo: true)` or similar; no complex queries in the view.
- All user-facing text in English (GR).
- No new validations or business logic: this is a UI/layout task (GR — no scope creep).

## Recommended LLM model
Claude Sonnet 5 — frontend layout and component reuse, moderate scope, fast iteration.

## Commit strategy
One branch (`feat/landing-page`), stacked commits:
- `test: landing page integration + feature card snapshot tests`
- `feat: add demo character seed for landing page` (if needed)
- `feat: landing page hero, demo section, feature cards` (views + topbar update)
- `feat: auth modal signup shortcut + anon topbar CTAs`
- `test: browser validation (Chrome DevTools, responsive, no console errors)` (evidence only, not a code commit)

Total: ≤400 LOC, ≤15 files (home/index.erb, topbar update, controller, seeds if new, tests). Split using stacked PRs if sizing exceeded per [docs/code-review/pr-sizing-and-stacking.md](../code-review/pr-sizing-and-stacking.md).
