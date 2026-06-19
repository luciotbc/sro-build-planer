# 008 — Mastery section tabs

## Execution order
Depends on: 007
Run before: 010.

## Objective
The mockup's mastery navigation: type tabs (Weapon/Force/Recovery) + mastery sub-tabs (e.g. Bicheon/Heuksal/Pacheon), swapping the skill window content without a reload (Turbo frame / Stimulus).

## Usage flow
In the planner, the user switches mastery type (row 1) and specific mastery (row 2) → the skill window updates to the chosen mastery.

## References
- Mockup: `index.html` and `skills_editor.html` (two tab rows).
- Design System: MasterySection, `_tabs` (default + underline), TopBar.
- Specs: [glossary](../specs/glossary.md) (mastery vs mastery type).
- Code: `app/views/shared/_tabs.html.erb`, `app/javascript/controllers/tabs_controller.js`, `app/models/mastery.rb` (mastery_type enum).

## Implementation scope
- **Frontend**: `shared/_mastery_section` with `mastery_type` tabs (row 1, pill variant) + sub-tabs of that type/race's masteries (row 2, underline variant); switch via Turbo Frame (reload skill window) or Stimulus + Turbo.
- **Backend**: `mastery_id` param/endpoint on show; list masteries by race grouped by type.
- **States**: type with no masteries → disabled/hidden tab; active mastery highlighted.

## Acceptance criteria
- [ ] Type tabs and sub-tabs rendered per the character's race.
- [ ] Switching a tab updates the skill window without a full reload.
- [ ] Active mastery persisted across navigation (param/state).
- [ ] Faithful to mockup + DS (MasterySection, `_tabs`).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration/system: tabs reflect the race's masteries; switching a tab changes displayed skills; correct active state.

## Best practices
Reuse `_tabs`, DS, Turbo, DRY, a11y (roles/aria-selected), I18n.

## Recommended LLM model
Sonnet — tab wiring over an existing component.

## Commit strategy
`feat: mastery section type + sub tabs` · `feat: turbo frame skill window swap` · `test: mastery tab navigation`.
