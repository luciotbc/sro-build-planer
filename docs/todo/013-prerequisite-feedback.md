# 013 — Prerequisite feedback (toasts)

## Execution order
Depends on: 010
Run before: —. Parallel with: 014.

## Objective
Surface the services' `warnings` (auto-added prerequisite, escalated mastery, adjusted class level, downgrade) as non-blocking toasts in the editor.

## Usage flow
When adjusting a skill triggers a cascade, the user sees toasts describing what changed automatically (e.g. "Pierce I added as a prerequisite").

## References
- Mockup: `skills_editor.html` (action feedback).
- Design System: **Toast — new canonical component created here**: partial `app/views/shared/_toast.html.erb` + Stimulus `toast_controller.js`. Reuses tokens (`--color-card`, semantic `--color-green`/`--color-red`/`--color-blue`) and `_button`/`icon-btn` for dismiss. Not yet in SROLabDS; registered in the living docs and republished via design-sync in 017.
- Specs: [03](../specs/03-prerequisites-and-cascade.md) (warnings in R3/R4/R5).
- Code: `ServiceResult#warnings`, `CharacterSkills::*` services, I18n `warnings.*` (already present).

## Implementation scope
- **Frontend**: create `app/views/shared/_toast.html.erb` + `app/javascript/controllers/toast_controller.js` rendering `result.warnings`; auto-dismiss; stack; error variant.
- **Backend**: warnings already returned; controller/Turbo Stream delivers them to the toast.
- **Validations/errors**: errors (fail) also displayable as an error toast (variant).
- **States**: multiple warnings stack; manual and automatic dismiss.

## Acceptance criteria
- [ ] Cascade warnings appear as toasts (I18n).
- [ ] Errors appear as an error toast.
- [ ] Auto-dismiss + manual dismiss; accessible (aria-live).
- [ ] Faithful to the DS (after 017 registers the component).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- System/integration: an action with a prerequisite → toast with I18n text; error → error toast; aria-live present.

## Best practices
Reuse existing warnings, DS, a11y (live region), I18n, DRY.

## Recommended LLM model
Sonnet — feedback wiring over ready-made warnings.

## Commit strategy
`feat: toast component` · `feat: surface service warnings as toasts` · `test: prerequisite feedback toasts`.
