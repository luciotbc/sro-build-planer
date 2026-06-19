# 015 — Empty / loading / error states

## Execution order
Depends on: 007, 010
Run before: —. Parallel with: 016, 017.

## Objective
Consistent states across all feature screens: no characters, no skills in the mastery, loading, and save errors — with English copy and a11y.

## Usage flow
A new user with no characters sees a create CTA; a mastery with no skills shows empty; actions show loading; failures show a recoverable error.

## References
- Mockup: `index.html`, `skills_editor.html` (implicit states).
- Design System: Hero/CharsDrawer/PlannerCard/SkillEditor (empty variants), `_button`.
- Specs: [05](../specs/05-character-lifecycle.md) (R10 auth/landing).
- Code: screens from 006/007/010, controllers.

## Implementation scope
- **Frontend**: empty states (no characters → CTA; empty mastery; empty drawer); skeleton/spinner loading; inline/toast error.
- **Backend**: ensure controllers return data/errors consumable by these states.
- **States**: empty, loading, success, error — covered per screen.

## Acceptance criteria
- [ ] Each screen has defined and styled empty/loading/error states (DS).
- [ ] English copy (project rule), a11y (aria-live on errors).
- [ ] No "broken" screens when data is missing.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration/system: user with no characters → CTA; mastery with no skills → empty; save error → message.

## Best practices
Consistency, DS, a11y, English-only, DRY (reusable empty-state partial).

## Recommended LLM model
Sonnet — states/UX over existing screens.

## Commit strategy
`feat: empty states (characters/skills)` · `feat: loading + error states` · `test: state coverage`.
