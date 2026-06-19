# 012 — Bulk skill actions (Max skills / Clear all / Undo)

## Execution order
Depends on: 010 (working-state/undo substrate), 011
Run before: —.

## Objective
The editor's bulk actions, scoped to the **active mastery** and the **edited side**: Max skills, Clear all, and single-step Undo.

## Usage flow
In the editor: "Max skills" raises all the active mastery's skills to their effective cap (respecting prerequisites); "Clear all" zeroes the edited side of the active mastery only; "Undo" restores the immediately previous state (e.g. after an accidental Clear all).

## References
- Mockup: `skills_editor.html` (Max skills, Undo, Clear all).
- Design System: SkillEditor, `_button` (incl. destructive variant).
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R3 scope, R5 Max skills, R6 Clear all, R7 Undo), [04](../specs/04-skill-access-and-caps.md).
- Code: `CharacterSkills::{Update,Clear}Service` (per-side), resolver (002).

## Implementation scope
- **Frontend**: Max skills / Clear all (destructive) / Undo (enabled only when a prior state exists) buttons; all scoped to the active mastery. Uses the **working-state/snapshot substrate delivered in 010**.
- **Backend**: Max skills → for each of the mastery's skills, set to `min(max_skill_level, reachable via server cap)` respecting prerequisites; Clear all → zero the edited side's skills + that mastery's level, in this mastery only; Undo → restore the immediately previous snapshot (single step, spec 06 R7).
- **Clear all without a confirm dialog**: recovery is exclusively via **Undo** (decision: no confirm modal on Clear all; Undo covers accidental clears — spec 06 R7).
- **Validations/errors**: Undo unavailable when there is no prior state (button disabled).
- **States**: loading; success; Undo disabled (no snapshot).

## Acceptance criteria
- [ ] Max skills raises to the effective cap respecting prerequisites, in the active mastery/side only.
- [ ] Clear all zeroes only the active mastery (others untouched) on the edited side.
- [ ] Undo restores the immediately previous state (single step); Clear all has no modal (Undo covers).
- [ ] The other side is never affected.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- System/integration: Max skills → caps; Clear all does not affect another mastery or the other side; Undo after Clear all recovers; Undo disabled initially.

## Best practices
SRP, reuse services, DS, a11y, I18n, idempotency where applicable.

## Recommended LLM model
Opus — cascade integrity + Undo state.

## Commit strategy
`feat: max skills action` · `feat: clear all (mastery-scoped)` · `feat: single-step undo` · `test: bulk actions scope + undo`.
