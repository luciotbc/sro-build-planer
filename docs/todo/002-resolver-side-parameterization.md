# 002 — Resolver side-parameterization (current/planned cascade)

## Execution order
Depends on: 001
Run before: 003, 010, 011, 012.

## Objective
Generalize `PrerequisiteResolver` and the skill/mastery services to operate per **side** (`:current` | `:target`), enabling symmetric and independent cascade on the planned build (today only current cascades). Consolidates duplication and the remaining `dev2.todo` items.

## Usage flow
Backend — no direct UI. Raising a planned skill: auto-adds planned prerequisites, escalates the planned mastery, raises the target class level; lowering: blocks on planned dependents.

## References
- Specs: [03](../specs/03-prerequisites-and-cascade.md) (R1 independence, R2 symmetry, R3–R7), [04](../specs/04-skill-access-and-caps.md).
- Design System: —.
- Code: `app/services/character_skills/prerequisite_resolver.rb`, `add_service.rb`, `update_service.rb`, `clear_service.rb`, `app/services/character_masteries/*`.

## Implementation scope
- **Resolver**: parameterize by `side`; use `#{side}_skill_level` / `#{side}_mastery_level` / that side's class-level cache; `sync_character_level` and `update_mastery` per side.
- **Services**: `Add/Update/Clear` accept/derive the side; apply R3–R7 to the correct side; `find_blocking_dependents` per side.
- **DRY (dev2.todo #5)**: extract the duplicated `resolve_prerequisites` between Add/Update into the single mixin.
- **Remaining dev2.todo**: I18n on any stray warning strings (#8), consistent `ApplicationRecord.transaction` (#6/#10), consistent `RecordInvalid` rescue (#7), N+1 in `find_blocking_dependents` (#3).
- **Validations/errors**: decrement blocking with dependent list (per side); warnings via I18n.

## Acceptance criteria
- [ ] Raising a planned skill cascades only on the target side (current untouched) and vice versa.
- [ ] current and planned stay independent (planned may be < current).
- [ ] Decrement blocked by same-side dependents.
- [ ] No duplication of `resolve_prerequisites`.
- [ ] N+1 in blocking dependents fixed.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; rubocop clean.

## Testing strategy (TDD)
- Unit: resolver with side=:target adds prerequisites on target; side=:current does not affect target.
- Integration: raising a planned Pierce auto-adds a planned prerequisite + escalates the planned mastery + raises target_level; lowering with a planned dependent → error.
- Regression: existing current behavior preserved (current tests green).

## Best practices
DRY, SRP, low coupling, I18n, no regression of the current side.

## Recommended LLM model
Opus — recursive cascade logic, edge cases, correctness.

## Commit strategy
`refactor: parameterize prerequisite resolver by side` · `feat: planned-side cascade for skills/masteries` · `test: planned cascade + independence` · `fix: dedupe resolver and N+1 in blocking dependents`.
