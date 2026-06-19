# 007 — Planner read-only view (index.html)

## Execution order
Depends on: 003, 004
Run before: 008, 009, 010, 015, 016, 017.

## Objective
Render the main planner screen (read-only) from the `index.html` mockup: PlannerCard with character bar, ReadOnlySkillWindow showing current→planned levels, and the Edit Current / Edit Planned entry points.

## Usage flow
Logged-in user opens a character → sees the bar (name, race, LEVEL CAP), the SKILLS section with the active mastery and its skills (current→planned levels, white/brass), Current↔Planned toggle, Edit Current/Edit Planned buttons, and Delete/Save character actions.

## References
- Mockup: `index.html` (full planner).
- Design System: PlannerCard, ReadOnlySkillWindow, `_char_bar`, `_skill_row`, `_badge` (current/planned), `_button`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R1/R2), [01](../specs/01-level-and-progression.md), [04](../specs/04-skill-access-and-caps.md).
- Code: `app/views/shared/_char_bar.html.erb`, `_skill_row.html.erb`, `_badge.html.erb`, `CharactersController#show`, `Builds::SummaryService`.

## Implementation scope
- **Frontend**: `characters/show` with PlannerCard (`shared/_planner_card`), character bar (cap highlighted), `shared/_read_only_skill_window` reusing `_skill_row` (shows `current → planned` per skill, white/brass colors); Current↔Planned toggle (Stimulus); Edit Current/Edit Planned buttons (link to the editor 010 per side); Delete (confirm) / Save.
- **Backend**: show loads character + masteries + active mastery's skills; levels displayed per specs.
- **States**: no skills in the mastery → empty (rich in 015); loading.
- Mastery tabs come in 008 (here, default active mastery).

## Acceptance criteria
- [ ] Layout faithful to `index.html` (tokens, spacing, hierarchy).
- [ ] Skills show current→planned with the correct colors.
- [ ] Current↔Planned toggle works.
- [ ] Edit Current/Edit Planned go to the editor on the correct side.
- [ ] Read-only (no steppers here).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration/system: show renders bar + skills; toggle switches emphasis; edit links point to the correct side; empty state.

## Best practices
Reuse partials, DS, view/service separation, a11y, I18n.

## Recommended LLM model
Opus — composes calc + data + layout fidelity.

## Commit strategy
`feat: planner card + character bar` · `feat: read-only skill window` · `feat: current/planned toggle` · `test: planner show read-only` · `feat: edit-current/planned entry links`.
