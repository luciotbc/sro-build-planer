# 008 — Mastery section tabs

## Execution order
Depends on: 007
Run before: 010.

## Objective
Implement mastery navigation on the character planner show page: two rows of tabs (mastery type pills + mastery sub-tabs) with a Turbo Frame skill window. Navigation state is managed client-side via a dedicated Stimulus controller (`mastery_tabs_controller`). The complete navigation rules are specified in [docs/specs/07-mastery-navigation.md](../specs/07-mastery-navigation.md).

## Usage flow
1. Page loads → first mastery group pill is active → first mastery of that group is active → skill window shows that mastery's content.
2. User clicks a different group pill → sub-tabs update to that group's masteries → last-selected (or first) mastery is restored → skill window updates.
3. User clicks a mastery sub-tab → that sub-tab becomes active → skill window updates → selection is remembered for that group.
4. Reload → state resets to first group + first mastery (no persistence).

## References
- Spec: [07-mastery-navigation.md](../specs/07-mastery-navigation.md) (navigation rules, invariants).
- Mockup: `index.html` and `skills_editor.html` (two tab rows).
- Design System: MasterySection, `_tabs` (default + underline), TopBar.
- Specs: [glossary.md](../specs/glossary.md) (mastery vs mastery type).
- Code: `app/views/shared/_tabs.html.erb`, `app/javascript/controllers/mastery_tabs_controller.js`, `app/models/mastery.rb`.

## Implementation scope
- **Frontend:** `show.html.erb` wired to `mastery-tabs` Stimulus controller; pill row (type filter, row 1) + sub-tab row (per-group masteries, row 2); server renders correct initial active state.
- **Backend:** `CharactersController#show` sets `@active_mastery` to first mastery of first group on initial load; `mastery_id` param still used for Turbo Frame content requests.
- **Stimulus:** `mastery_tabs_controller.js` — domain-specific, handles group switching (show/hide panels, restore last selection, navigate frame) and mastery switching (mark active, persist per-group selection).
- **Design System:** document MasteryNav component in design system.
- **States:** empty groups not rendered; no-mastery empty state; active mastery always highlighted.

## Acceptance criteria
- [x] Type pills rendered per character's race; pill for active group has `on`.
- [x] Sub-tabs rendered per active group; sub-tab for active mastery has `on`.
- [x] Clicking a pill switches visible sub-tabs and updates skill window.
- [x] Clicking a sub-tab marks it active and updates skill window.
- [x] Last selected mastery per group is restored when switching back to that group.
- [x] Reload always resets to first group + first mastery.
- [x] Empty groups not rendered.
- [x] INV-1 through INV-4 hold at all times (see spec 07).
- [x] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Controller tests: initial render shows first group/mastery active; `mastery_id` param returns correct frame content; empty state when no masteries.
- Integration: switching groups and masteries works; invariants hold.

## Best practices
Reuse `_tabs` CSS classes. Keep Stimulus controller UI-only. Keep Turbo Frame responsible only for content replacement. No `localStorage`/`sessionStorage`. One commit per logical change.

## Recommended LLM model
Sonnet — client-side state + Turbo integration over existing component.

## Commit strategy
```
fix(mastery-navigation): select first mastery on initial render
fix(mastery-navigation): update mastery list when switching groups
test(mastery-navigation): add/update mastery navigation tests
refactor(mastery-navigation): extract mastery-specific tabs controller
docs(design-system): document mastery navigation component
```
