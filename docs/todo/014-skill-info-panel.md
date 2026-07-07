# 014 — Skill & series info panel

## Execution order
Depends on: 010
Run before: —. Parallel with: 013.

## Objective
Detail panels: SkillInfoPanel (per skill: sp_cost, mp_cost, mastery_level_req, prerequisites) and SeriesInfoPanel (per series), accessible from the editor/planner.

## Usage flow
The user clicks/hovers a skill (or a series header) → the panel shows details (costs, mastery requirement, prerequisites, description if any).

## References
- Mockup: `skills_editor.html` (skill rows / series).
- Design System: SkillInfoPanel, SeriesInfoPanel, `_sheet`/`_drawer` (overlay).
- Specs: [04](../specs/04-skill-access-and-caps.md) (mastery_req, unlock), [02](../specs/02-sp-and-summary.md) (sp_cost).
- Code: `app/models/skill.rb`, `skill_group_requirement.rb`, `skill_series.rb`, `_sheet.html.erb`.

## Implementation scope
- **Frontend**: `app/views/skills/_skill_detail_modal.html.erb` and `_skill_series_detail_modal.html.erb` — centered modal (440px, `.overlay-head`, `dialog` controller) instead of `_sheet`, per the approved mockup (`skills_editor.html`).
- **Backend**: load skill by level (`skill_at_level`, level-1 fallback) + requirements; done inline in trigger views (presentational partials, no controller logic).
- **States**: skill with no requirements (basic, rows omitted); no skill data (icon stays non-interactive); SP cost "N/A" at max level.

## Acceptance criteria
- [x] Skill panel shows the correct next-level sp_cost, mastery_level_req, prerequisites (mp_cost slot-ready via data-driven rows).
- [x] Series panel shows the series summary.
- [x] Opens/closes accessibly (Esc/backdrop via `dialog` controller); faithful to the DS; live demo on `/docs/design_system`.
- [x] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration/system: panel shows the selected skill's costs/reqs; series lists its groups; basic group with no reqs.

## Best practices
Reuse `_sheet`, DS, a11y, I18n, presentation separated from data.

## Recommended LLM model
Sonnet — presentational over existing data.

## Commit strategy
`feat: skill info panel` · `feat: series info panel` · `test: info panels content`.
