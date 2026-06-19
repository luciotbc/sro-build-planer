# 010 — Skill editor screen (skills_editor.html)

## Execution order
Depends on: 002, 007, 008
Run before: 011, 012, 013, 014, 015, 016, 017.

## Objective
The skill editing screen (SkillEditor) from `skills_editor.html`, parameterized by **side** (current or planned): collapsible series (SkillSeries), skill rows (SkillRow) with ± steppers showing `level / cap`, and the mastery header. Editing respects the cascade rules.

## Usage flow
From the planner, "Edit Current"/"Edit Planned" opens the editor on that side for the active mastery. The user expands a series, uses ± to adjust skills; cascade applies prerequisites/mastery; on save it persists; back to the planner.

## References
- Mockup: `skills_editor.html`.
- Design System: SkillEditor, SkillRow, SeriesInfoPanel, `_skill_row`, `_button`, `_tabs`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R2/R3), [03](../specs/03-prerequisites-and-cascade.md), [04](../specs/04-skill-access-and-caps.md).
- Code: `app/views/shared/_skill_row.html.erb`, `app/javascript/controllers/stepper_controller.js`, `CharacterSkills::{Add,Update,Clear}Service` (per-side after 002).

## Implementation scope
- **Frontend**: `shared/_skill_editor` + `shared/_series_group` (collapsible, `X/Y` counter); `_skill_row` with ± (Stimulus stepper) showing `level / effective_cap`; side from the param; hold-+/− hint.
- **Working-state / undo substrate (foundation for 012)**: define and deliver the unsaved-edit-state mechanism that enables **single-step undo** (spec 06 R7/R8) — a snapshot of the active mastery's prior state before each bulk action. Decide and document the approach (client working copy via Stimulus values vs per-action round-trip with a server snapshot). 012 consumes this substrate.
- **Backend**: ± actions call the per-side services; `effective_cap = min(max_skill_level, reachable via server cap)`; cascade via the resolver (002).
- **Validations/errors**: decrement blocked by dependents → error/toast (detailed toast in 013); cap respected.
- **States**: empty/0-allocated series; per-action loading; success; error.

## Acceptance criteria
- [ ] Editor opens on the correct side (current/planned) per the entry point.
- [ ] Working-state substrate (active-mastery snapshot) delivered and documented — enables single-step undo (consumed by 012).
- [ ] ± respects the effective cap and applies cascade (prerequisites/mastery) on the correct side.
- [ ] Series collapse/expand; counters correct.
- [ ] Decrement blocked by a dependent → feedback (without corrupting state).
- [ ] Faithful to mockup + DS; current untouched when editing planned.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- System/integration: raising a planned skill → planned prerequisite appears; effective cap limits; current unchanged; blocked decrement shows an error; series collapse.

## Best practices
Reuse `_skill_row`/`stepper`, DS, SRP, low coupling, a11y, I18n; business rules from the specs (not the mockup).

## Recommended LLM model
Opus — most complex interaction, per-side cascade, many edge cases.

## Commit strategy
`feat: series group collapsible partial` · `feat: skill editor screen (side-parameterized)` · `feat: stepper ± wired to side services` · `test: editor cascade + cap + independence`.
