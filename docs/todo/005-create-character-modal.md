# 005 — Create character modal

## Execution order
Depends on: 004
Run before: 007. Parallel with: 006.

## Objective
"New character" modal (CreateCharacter component) with name, type (Chinese/European) and server level cap (90/100/110/120/130), wired to `Characters::CreateService`.

## Usage flow
Logged-in user clicks "New character" → modal opens → fills name, picks race (Chinese/European glyph), picks cap → "Start Build" → creates and navigates to the new character's planner.

## References
- Mockup: `index.html` (New character modal).
- Design System: CreateCharacter, ChineseGlyph, EuropeanGlyph, `_modal`, `_button`.
- Specs: [05](../specs/05-character-lifecycle.md) (R1 create), [01](../specs/01-level-and-progression.md) (cap enum).
- Code: `app/views/shared/_modal.html.erb`, `app/javascript/controllers/dialog_controller.js`, `Characters::CreateService`.

## Implementation scope
- **Frontend**: `shared/_create_character` partial using `_modal`; race selector (two glyph cards); cap selector (5 options, default 110/Standard); uses the Stimulus `dialog` controller.
- **Glyphs**: create `_chinese_glyph` / `_european_glyph` partials (DS icons).
- **Backend**: submit → CreateService (exists); sets `race_id` + `server_level_cap` + `name`.
- **Validations/errors**: name required, cap required; errors rendered in the modal (preserve state).
- **States**: loading on submit; success → redirect to planner; error → inline messages.

## Acceptance criteria
- [ ] Modal opens/closes (Esc/backdrop) via Stimulus.
- [ ] Creates a character with the correct race and cap; navigates to the planner.
- [ ] Validation errors shown without losing typed data.
- [ ] Faithful to the mockup (layout/tokens) and DS (CreateCharacter, glyphs).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; no console errors.

## Testing strategy (TDD)
- System/integration: open modal, valid create → planner; invalid submit → inline error; correct default cap.
- Unit: partial renders cap/race options.

## Best practices
Reuse `_modal`/`_button`, DS, DRY, a11y (focus trap, labels), I18n.

## Recommended LLM model
Sonnet — form + modal over existing components.

## Commit strategy
`feat: chinese/european glyph partials` · `feat: create character modal partial` · `test: create character flow` · `feat: wire modal to CreateService`.
