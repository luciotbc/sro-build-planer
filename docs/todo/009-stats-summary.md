# 009 — Stats summary panel

## Execution order
Depends on: 003, 007
Run before: 017. Parallel with: 008/010 (after deps).

## Objective
The SUMMARY panel from `index.html` (StatsSummary): SKILL POINTS, MASTERY TOTAL, REQUIRED LEVEL, each in the `current + delta = planned` format, bound to `Builds::SummaryService`.

## Usage flow
In the planner, below the skill window, the user sees the build's three aggregate totals (current vs planned).

## References
- Mockup: `index.html` (SUMMARY section).
- Design System: StatsSummary, Stat, `_stat_row`.
- Specs: [02](../specs/02-sp-and-summary.md) (R3/R4/R5, `current+delta=planned` format).
- Code: `app/views/shared/_stat_row.html.erb`, `Builds::SummaryService`.

## Implementation scope
- **Frontend**: `shared/_stats_summary` reusing `_stat_row` (label, current, delta, planned) with `.tnum`; three rows.
- **Backend**: consumes `Builds::SummaryService.call(character).data`.
- **States**: empty build → zeros; negative delta formatted (sign); loading.

## Acceptance criteria
- [ ] Three rows with the SummaryService numbers (matching spec 02).
- [ ] `current + delta = planned` format, tabular (`.tnum`), correct negative delta.
- [ ] Updates when mastery/edits change (Turbo).
- [ ] Faithful to mockup + DS (StatsSummary/Stat).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration: rendered values = SummaryService; empty → zeros; negative delta.

## Best practices
Reuse `_stat_row`, DS, localized number formatting, DRY.

## Recommended LLM model
Sonnet — binding + formatting over a ready-made service.

## Commit strategy
`feat: stats summary partial` · `test: stats summary rendering` · `feat: bind summary service + tnum formatting`.
