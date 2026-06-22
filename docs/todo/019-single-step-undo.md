# 018 — Single-step Undo for bulk actions

## Execution order
Depends on: 012 (bulk actions backend — Max skills, Max mastery, Clear all)
Run before: —.

## Objective
Single-step client-side Undo for all bulk editor actions (Max skills, Max mastery, Clear all), scoped to the active mastery and edited side. Spec 06 R7/R8.

## Usage flow
After any bulk action, the Undo button becomes enabled. Clicking Undo restores all stepper levels (mastery + skills) to the state immediately before the bulk action was triggered. One level of history only; Undo clears itself after use.

## References
- Mockup: `skills_editor.html` (Undo button in bulk actions row).
- Design System: `_button`, SkillEditor.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) R7 (single-step undo), R8 (snapshot before bulk execute).
- Code: `skill_editor_controller.js` (snapshot/restore substrate), `edit.html.erb` (beforeBulk wiring).

## Implementation scope
- **Frontend only** (no backend changes):
  - `skill_editor_controller.js` — Stimulus controller with `snapshot()`, `restore()`, `beforeBulk()`, `snapshotValueChanged()`, `#steppers()` private method.
  - `edit.html.erb` — `data-controller="skill-editor"` wrapper containing mastery_header + skill rows; `data-action="submit->skill-editor#beforeBulk"` on each bulk action form; Undo button with `data-skill-editor-target="undo"` + `data-action="click->skill-editor#restore"`.
- **No backend**: Undo works by re-submitting PATCH requests for changed steppers, reusing existing `character_character_mastery_path` and `character_character_skill_path` endpoints.
- **Snapshot scope**: mastery stepper (mastery-header) + all skill-row steppers inside the skill-editor wrapper.
- **Validations**: Undo button disabled when no snapshot exists; enabled after any successful bulk action.

## Acceptance criteria
- [ ] Clicking any bulk action captures a snapshot → Undo button becomes enabled.
- [ ] Clicking Undo restores mastery level + all skill levels to pre-bulk state.
- [ ] Undo button returns to disabled after use.
- [ ] Undo after "Max mastery" restores mastery level only (skills unchanged).
- [ ] Undo after "Clear all" restores mastery + all skill levels.
- [ ] Undo after "Max skills" restores all skill levels only (mastery unchanged).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; no console errors.

## Testing strategy
- **JS-only behavior**: verify in browser (no Rails tests for client-side snapshot/restore).
- Browser checklist: (1) load editor, Undo disabled; (2) click Max mastery → Undo enabled; (3) click Undo → mastery restored; (4) click Clear all → Undo enabled; (5) click Undo → all levels restored.

## Best practices
- No backend changes; reuse existing PATCH endpoints.
- The `skill-editor` controller wrapper must contain both mastery_header and skill rows so `#steppers()` finds all stepper instances.
- `beforeBulk` action must be on the `<form>` element (not the submit button) — `submit` events bubble from the form, not down to children.

## Recommended LLM model
Haiku — pure JS/view wiring, no architectural complexity.

## Commit strategy
`fix: wire beforeBulk to form element (submit event target)` · `feat: single-step undo — skill_editor_controller` · `test: browser-validate undo flow`.
