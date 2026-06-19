# 02 — SP cost & StatsSummary

**Purpose:** define how the StatsSummary panel numbers are computed (SKILL POINTS, MASTERY TOTAL, REQUIRED LEVEL).
**How agents use this:** `Builds::SummaryService` implements exactly these formulas; the StatsSummary view binds to them. Cross-links: [01-level-and-progression](01-level-and-progression.md), [glossary](glossary.md).

## Data sources
- `Skill#sp_cost` — SP cost of **that single skill level** (incremental, per-level). Owning a skill at level N costs the sum of `sp_cost` for that group's skill rows level `1..N`.
- `LevelDatum#sp_cumulative` — **the SP cost to raise one mastery to a given level** (cumulative of `sp_gained`). I.e. bringing a mastery to level L costs `sp_cumulative(L)`.
- `CharacterMastery#{current,target}_mastery_level`, `CharacterSkill#{current,target}_skill_level`.

## SKILL POINTS

Total SP a build costs = **mastery SP + skill SP**, computed independently for `current` and `planned`.

- **R1 — mastery SP** (`skill_sp_mastery`):
  For each `CharacterMastery`, look up `LevelDatum.sp_cumulative` at that mastery's level; **sum across masteries**.
  - current = `Σ_m sp_cumulative(m.current_mastery_level)`
  - planned = `Σ_m sp_cumulative(m.target_mastery_level)`

  > ⚠️ **R1a — sum per mastery, never `IN`.** Compute as a per-row JOIN/sum, not `WHERE level IN (… mastery levels …)`. `IN` deduplicates equal levels, so two masteries at the same level would be counted once — wrong. Each mastery contributes its own `sp_cumulative`.

- **R2 — skill SP** (`skill_sp_cost`):
  For each `CharacterSkill`, sum `sp_cost` over that skill group's levels `1..level`; sum across skills.
  - current = `Σ_s ( Σ_{l=1..s.current_skill_level} sp_cost(s.group, l) )`
  - planned = `Σ_s ( Σ_{l=1..s.target_skill_level} sp_cost(s.group, l) )`

- **R3 — SKILL POINTS row:**
  - current = `skill_sp_mastery.current + skill_sp_cost.current`
  - planned = `skill_sp_mastery.planned + skill_sp_cost.planned`
  - displayed `current + (planned − current) = planned`. Delta may be negative.

## MASTERY TOTAL

- **R4 —** sum of mastery **levels** (not a count) across all the character's masteries.
  - current = `Σ_m m.current_mastery_level`; planned = `Σ_m m.target_mastery_level`.
  - displayed `current + delta = planned`.

## REQUIRED LEVEL

- **R5 —** = class level current → target (see [01](01-level-and-progression.md) R1/R2): `current_level → target_level`, i.e. `MAX(current_mastery_level) → MAX(target_mastery_level)`. Delta may be negative.

## Notes
- All three rows share the display shape `current  +  delta  =  planned` with `.tnum` tabular figures.
- No separate "SP budget/affordability" concept exists — `sp_cumulative` is a **cost** input (mastery SP), not a budget ceiling.
