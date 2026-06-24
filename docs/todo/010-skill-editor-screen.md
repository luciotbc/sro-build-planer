# 010 — Skill editor screen (skills_editor.html)

## Execution order
Depends on: 002, 007, 008
Run before: 011, 012, 013, 014, 015, 016, 017.

## Objective
The skill editing screen (SkillEditor) from `skills_editor.html`, parameterized by **side** (current or planned): collapsible series (SkillSeries), skill rows (SkillRow) with ± steppers showing `level / cap`, and the mastery header. Editing respects the cascade rules.

## Usage flow
From the planner, "Edit Current"/"Edit Planned" opens the editor on that side for the active mastery. The user expands a series, uses ± to adjust skills; each click persists immediately via Turbo Stream (per-step persistence, spec 06 R8); cascade applies prerequisites/mastery on the correct side; back to the planner.

## References
- Mockup: `skills_editor.html`.
- Design System: SkillEditor, SkillRow, SeriesInfoPanel, `_skill_row`, `_button`, `_tabs`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R2/R3), [03](../specs/03-prerequisites-and-cascade.md), [04](../specs/04-skill-access-and-caps.md).
- Code: `app/views/shared/_editor_skill_row.html.erb` (wired editor row, Turbo Stream), `app/views/shared/_skill_row.html.erb` (DS demo component — do not wire), `app/javascript/controllers/stepper_controller.js`, `app/controllers/character_skills_controller.rb`, `CharacterSkills::{Add,Update,Clear}Service`.

## Implementation scope
- **Frontend**: `shared/_skill_editor` + `shared/_series_group` (collapsible, `X/Y` counter); `_skill_row` with ± (Stimulus stepper) showing `level / effective_cap`; side from the param; hold-+/− hint.
- **Working-state / undo substrate (foundation for 012)**: define and deliver the unsaved-edit-state mechanism that enables **single-step undo** (spec 06 R7/R8) — a snapshot of the active mastery's prior state before each bulk action. Decide and document the approach (client working copy via Stimulus values vs per-action round-trip with a server snapshot). 012 consumes this substrate.
- **Backend**: ± actions call the per-side services; `effective_cap = min(max_skill_level, reachable via server cap)`; cascade via the resolver (002).
- **Validations/errors**: decrement blocked by dependents → error/toast (detailed toast in 013); cap respected.
- **States**: empty/0-allocated series; per-action loading; success; error.

## Acceptance criteria
- [x] Editor opens on the correct side (current/planned) per the entry point. _(010/01)_
- [x] Working-state substrate (active-mastery snapshot) delivered and documented — enables single-step undo (consumed by 012). _(010/03 — `skill_editor_controller.js` snapshot/restore)_
- [x] ± respects the effective cap and applies cascade (prerequisites/mastery) on the correct side. _(010/02)_
- [x] Series collapse/expand; counters correct. _(010/03 — collapsible_controller.js, X/Y counter)_
- [x] Decrement blocked by a dependent → feedback (without corrupting state). _(010/02)_
- [x] Faithful to mockup + DS; current untouched when editing planned. _(mockup-parity pass: char-bar, Box Skills panel, mastery nav, mastery-level box, action buttons, series box + rows; reuses DS partials/classes; spec 07 nav now wired on the editor)_
- [x] `PARALLEL_WORKERS=1 bin/rails test` green; console clean. _(500 runs, 0 failures)_

## Testing strategy (TDD)
- System/integration: raising a planned skill → planned prerequisite appears; effective cap limits; current unchanged; blocked decrement shows an error; series collapse.

## Best practices
Reuse `_skill_row`/`stepper`, DS, SRP, low coupling, a11y, I18n; business rules from the specs (not the mockup).

## Recommended LLM model
Opus — most complex interaction, per-side cascade, many edge cases.

## Commit strategy
`feat: series group collapsible partial` · `feat: skill editor screen (side-parameterized)` · `feat: stepper ± wired to side services` · `test: editor cascade + cap + independence`.
