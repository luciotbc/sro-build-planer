# 016 — Responsive / mobile

## Execution order
Depends on: 007, 010
Run before: —. Parallel with: 015, 017.

## Objective
Adapt the planner and editor to narrow viewports: drawer→sheet where it fits, scrollable mastery tabs, a usable editor on mobile, respecting `--spacing-tap` (44px).

## Usage flow
On a small screen, the user navigates masteries, edits skills (steppers with adequate touch targets), opens the character drawer/sheet and info panels without layout breakage.

## References
- Mockup: `index.html`, `skills_editor.html` (desktop reference; derive mobile).
- Design System: `_drawer`/`_sheet`, tokens (`--spacing-tap`), tabs.
- Specs: —.
- Code: `app/assets/tailwind/application.css`, partials from 006–014.

## Implementation scope
- **Frontend**: Tailwind breakpoints; convert overlays to `_sheet` on mobile; horizontally scrollable tabs; touch targets ≥44px; stackable tables/stat rows.
- **States**: same as desktop, validated on mobile.

## Acceptance criteria
- [ ] Planner and editor usable at ~380px with no horizontal overflow.
- [ ] Touch targets ≥44px; tabs accessible on mobile.
- [ ] Appropriate overlays (sheet) on mobile.
- [ ] Validated in Chrome (mobile emulation); console clean.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green.

## Testing strategy (TDD)
- System (mobile viewport): tab navigation, skill editing, opening drawer/sheet without breakage.

## Best practices
Mobile-first where possible, DS tokens, touch a11y, no forked CSS.

## Recommended LLM model
Sonnet — CSS/responsive.

## Commit strategy
`feat: responsive planner` · `feat: responsive editor + sheet overlays` · `test: mobile viewport flows`.
