# 012 — Bulk skill actions (Max skills / Clear all)

## Execution order
Depends on: 010, 011
Run before: 018 (single-step undo builds on these actions).

## Objective
The editor's bulk actions, scoped to the **active mastery** and the **edited side**: Max skills, Max mastery, and Clear all.

## Usage flow
In the editor: "Max mastery" raises the active mastery level to the server cap; "Max skills" raises all the active mastery's skills to their effective cap (respecting prerequisites); "Clear all" zeroes the edited side of the active mastery only.

## References
- Mockup: `skills_editor.html` (Max skills, Max mastery, Clear all).
- Design System: SkillEditor, `_button` (incl. destructive variant).
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R3 scope, R4 Max mastery, R5 Max skills, R6 Clear all), [04](../specs/04-skill-access-and-caps.md).
- Code: `CharacterSkills::{Update,Clear}Service` (per-side), resolver (002).

## Implementation scope
- **Frontend**: Max mastery / Max skills / Clear all (destructive) buttons; all scoped to the active mastery.
- **Backend**:
  - Max mastery → set active mastery level to `server_level_cap` (`CharacterMasteries::MaxMasteryLevelService`).
  - Max skills → for each of the mastery's skills, set to `min(max_skill_level, reachable via server cap)` respecting prerequisites (`CharacterSkills::MaxMasteryService`).
  - Clear all → zero the edited side's skills + that mastery's level, in this mastery only (`CharacterMasteries::ClearService`).
- **Validations/errors**: Turbo Stream error toast on failure.
- **States**: loading; success.

## Acceptance criteria
- [ ] Max mastery sets the active mastery level to the server cap on the edited side only.
- [ ] Max skills raises to the effective cap respecting prerequisites, in the active mastery/side only.
- [ ] Clear all zeroes only the active mastery (others untouched) on the edited side.
- [ ] The other side is never affected.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Server-side: Max mastery → cap; Max skills → caps; Clear all does not affect another mastery or the other side.

## Best practices
SRP, reuse services, DS, a11y, I18n, idempotency where applicable.

## Recommended LLM model
Haiku — mechanical service wiring, no architectural complexity.

## Commit strategy
`feat: max mastery action` · `feat: max skills action` · `feat: clear all (mastery-scoped)` · `test: bulk actions scope`.
