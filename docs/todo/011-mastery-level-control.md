# 011 — Mastery level control

## Execution order
Depends on: 010
Run before: 012.

## Objective
Mastery level control in the editor: slider + stepper (− / +) and a "Max mastery" button, operating on the edited side, with skill cascade on decrease (auto-downgrade skills above the new level) per the rules.

## Usage flow
In the editor, the user drags the slider / uses ± / clicks "Max mastery" → the mastery level (edited side) changes; raising unlocks skills; "Max mastery" goes to `server_level_cap`.

## References
- Mockup: `skills_editor.html` (slider + Max mastery).
- Design System: MasterySection, SkillEditor, `_button`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R4 Max mastery), [03](../specs/03-prerequisites-and-cascade.md) (**R7 mastery decrease auto-downgrades skills**), [01](../specs/01-level-and-progression.md) (R-cap), [04](../specs/04-skill-access-and-caps.md).
- Code: `app/javascript/controllers/stepper_controller.js`, `CharacterMasteries::UpdateService` (per-side after 002).

## Implementation scope
- **Frontend**: mastery slider + stepper + "Max mastery" (= `server_level_cap`); shows `MASTERY LV X / server_cap`.
- **Backend**: `CharacterMasteries::UpdateService` on the edited side; lowering the mastery below the `mastery_level_req` of allocated skills → **auto-downgrade** each skill to its highest valid level (spec 03 R7), with a warning per downgrade; sync the class-level cache.
- **Validations/errors**: never above `server_level_cap` (error if attempted); auto-downgrade warnings (non-blocking).
- **States**: loading; success; error (attempt above cap); min/max bounds on the control.

## Acceptance criteria
- [ ] Slider/stepper change the mastery on the edited side; cap = `server_level_cap`.
- [ ] "Max mastery" goes to the cap.
- [ ] Lowering the mastery auto-downgrades skills coherently (spec 03 R7, without violating caps) + warnings; does not block.
- [ ] Class-level cache updated.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- System/integration: Max mastery = cap; lowering the mastery clamps skills; other side untouched; level sync.

## Best practices
Reuse stepper, DS, SRP, a11y (keyboard slider), I18n.

## Recommended LLM model
Opus — cascade rules on decrease, edge cases.

## Commit strategy
`feat: mastery level slider + stepper` · `feat: max mastery action` · `feat: skill auto-downgrade on mastery decrease` · `test: mastery control cascade`.
