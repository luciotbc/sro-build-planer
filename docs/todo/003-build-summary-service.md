# 003 — Build summary service

## Execution order
Depends on: 001, 002
Run before: 007, 009.

## Objective
`Builds::SummaryService` computing the three StatsSummary numbers (SKILL POINTS, MASTERY TOTAL, REQUIRED LEVEL) for a character, current and planned, per [spec 02](../specs/02-sp-and-summary.md).

## Usage flow
Given a `Character`, returns a `ServiceResult` with `{ skill_points: {current,planned,delta}, mastery_total: {…}, required_level: {…} }` ready for the view.

## References
- Specs: [02](../specs/02-sp-and-summary.md) (R1–R5, mind R1a), [01](../specs/01-level-and-progression.md).
- Design System: StatsSummary, Stat (consumed in 009).
- Code: `app/models/level_datum.rb`, `skill.rb`, `character_mastery.rb`, `character_skill.rb`, `app/services/service_result.rb`.

## Implementation scope
- **Backend**: `self.call(character)`; mastery SP = `Σ per-mastery sp_cumulative(level)` (JOIN, never `IN` — R1a); skill SP = `Σ sp_cost 1..level`; mastery total = `Σ` levels; required level = `MAX` levels (current→target).
- **Performance**: avoid N+1 (preload masteries/skills/level_data; sum in memory or with correct aggregate SQL).
- **Validations/errors**: character with no masteries/skills → zeros; levels missing in `level_data` → treat as 0 with a warning.
- **States**: deterministic return; no UI dependency.

## Acceptance criteria
- [ ] Formulas match spec 02 (including per-mastery sum, not IN).
- [ ] current/planned/delta correct; delta may be negative.
- [ ] Empty character → all zeros.
- [ ] No N+1 (verified in a test with query count).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green.

## Testing strategy (TDD)
- Unit: scenario with 2 masteries at the same level (proves R1a — no dedup); cumulative skill 1..N; negative delta; empty → zeros.
- Integration: realistic fixture → expected numbers.

## Best practices
SRP, ServiceResult, pure/testable computation, no side effects, performance-aware.

## Recommended LLM model
Opus — numeric logic with a dedup trap (R1a), heavy TDD.

## Commit strategy
`feat: Builds::SummaryService skeleton + result shape` · `test: skill points / mastery total / required level` · `feat: implement per-mastery SP sum (avoid IN dedup)` · `perf: preload to avoid N+1`.
