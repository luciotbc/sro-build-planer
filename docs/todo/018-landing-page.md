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
3. Static screenshot of a real build (`app/assets/images/landing/demo_build.png`) —
   deliberately not a live partial render (per implementation decision below).
4. Three feature cards: full skill trees, exact SP math, multiple characters.
5. Bottom CTA band repeats signup.
6. Logged-in home behavior unchanged: auto-open create-character modal if no characters.

**Implementation decision (superseding the BE section below):** the live-preview section
ships as a pre-rendered screenshot, not a server-rendered partial reusing `_char_bar` /
`_skill_row` at request time. Rationale: keeps the anonymous landing route free of any
character-data query, avoids maintaining a permanent demo `Character` row, and the
screenshot is still pixel-accurate DS output (captured once from a real character build
via headless Chrome, not hand-drawn). Generation is a one-time asset step, not part of
the request path — see `app/views/home/_live_preview.html.erb` for the rationale comment.

## References
- Specs: [01](../specs/01-level-and-progression.md) (SP cumulative cost), [05](../specs/05-character-lifecycle.md) (character/mastery/skill domain).
- Design System: `/docs/design_system` (live reference); reuse `_char_bar`, `_stats_summary`, `_skill_row`, `_mastery_header`, `_badge`, race glyphs from `app/views/shared`; width caps 520px (char-bar, skill-card), 380px (ro-tabs) per [project_ds_demo_maxwidth_caps](../memory/project_ds_demo_maxwidth_caps.md).
- Mockup: Landing page mockup (4 sections: hero, demo, cards, bottom CTA); design governed by DS, not mockup pixel-perf.
- Code: `app/views/home/index.html.erb` (today minimal), `app/views/shared/_topbar.html.erb` (auth area), `app/controllers/home_controller.rb`.

## Implementation scope

### FE
- **home/index.html.erb**: conditional render: if authenticated & no characters, show create-character modal (existing behavior); else (anon), render 4-section landing via `home/_hero`, `home/_live_preview`, `home/_features`, `home/_cta_band` partials.
- **Topbar update** (`_auth_modals.html.erb`): anon state shows both "Log in" (`btn-ghost`) and "Create account" (`btn-primary`, visually dominant) triggers. Both call the page-level `auth` Stimulus controller (`showLogin` / `showSignup`) — the controller moved from the auth-modals wrapper `<div>` up to `<body>` (`application.html.erb`) so buttons anywhere on the page (hero, bottom CTA) share the same dialogs.
- **Auth modal**: signup opens directly (not login-first) via `data-action="auth#showSignup"` on the hero/CTA buttons — `showSignup` action already existed in `auth_controller.js`, no JS change needed.
- **Live preview**: static `<img>` (`app/assets/images/landing/demo_build.png`), not partial reuse — see usage-flow note above.
- **No new CSS**: hero/features/cta built entirely from existing Tailwind utilities + DS component classes (`btn-primary`, `btn-ghost`, `rounded-panel`/`border-line`/`bg-card`, `shared/badge`); no additions to `application.css`.

### Asset generation (one-time, not part of the app)
`app/assets/images/landing/demo_build.png` was captured via a throwaway Selenium script driving headless Chrome against a real logged-in build (`app/controllers/characters_controller.rb#show`), then cropped to the char-bar + skills panel. Not part of the request path or the test suite — regenerate manually if the DS visuals change materially.

### Testing strategy (TDD)
- **Integration** (`test/controllers/home_controller_test.rb`): anon GET `/` renders hero heading, live-preview `<img>`, all three feature-card headings, a `data-action*='auth#showSignup'` CTA button, and does *not* render the create-character dialog; authenticated-no-characters GET `/` renders the create-character dialog and *not* the hero; authenticated-with-characters GET `/` redirects to the character.
- **Integration** (`test/integration/topbar_auth_test.rb`): anon topbar renders a `btn-primary` "Create account" trigger alongside "Log in".
- **Browser (Chrome)**: hero/CTA clicks open the signup modal directly; no console errors; responsive at desktop/mobile viewport widths (verified via claude-in-chrome).

## Acceptance criteria
- [x] Hero section: one-line pitch + primary "Create account" CTA + secondary "Log in".
- [x] Live-preview section: static screenshot of a real build (see decision above), not live partial reuse.
- [x] Three feature cards: full skill trees, exact SP math, multiple characters.
- [x] Bottom CTA band: repeats signup button.
- [x] Logged-in home behavior unchanged: create-character modal auto-opens for users with no characters; no change to logged-in-with-characters redirect.
- [x] Topbar: anon state shows both "Log in" + "Create account"; "Create account" is `btn-primary`.
- [x] Auth modal: signup CTA from hero/CTA opens signup form directly (not login-first).
- [x] No console errors (Chrome DevTools via claude-in-chrome).
- [x] DS conformance: no new CSS added; existing button/card/badge classes reused.
- [x] `PARALLEL_WORKERS=1 bin/rails test` green (524 runs); `bin/rubocop` clean; `bin/brakeman` clean (0 warnings).
- [x] Responsive: verified at desktop and mobile widths via claude-in-chrome.
- [x] Specs README unchanged (no business-rule change — UI/layout only).

## Best practices
- Reuse existing partials/component classes; do not invent new styles. No additions needed to `/design_system` for this task.
- Controller stays untouched (`HomeController#index` had no logic changes — only the view branched).
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
