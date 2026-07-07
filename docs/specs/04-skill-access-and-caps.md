# 04 — Skill access & caps

**Purpose:** define a skill's level ceiling and the conditions under which a character may allocate it.
**How agents use this:** validations in `CharacterSkills::*` and the editor UI follow these rules. Cross-links: [03-prerequisites-and-cascade](03-prerequisites-and-cascade.md), [01-level-and-progression](01-level-and-progression.md).

> Notation: `??` = applies identically to the `current` or `target` side. The two sides are independent ([03](03-prerequisites-and-cascade.md) R1).

## Ceiling
- **R1 — skill ceiling is `SkillGroup#max_skill_level`.** A skill level may never exceed it. (The editor mockup's "/ 42 = mastery level" framing is **invalid** — ignore it; the cap is `max_skill_level`.)

## Access conditions (to allocate / level a skill in a group)
- **R2 — mastery requirement (per skill level).** To hold a skill at level N, `CharacterMastery#??_mastery_level >= Skill#mastery_level_req` for that group+level (each skill level has its own `mastery_level_req`).
- **R3 — group unlock.** A character may access a `SkillGroup` iff **either**:
  - all its `SkillGroupRequirement`s are satisfied — the `required_group` is held at ≥ `required_skill_level` (same side); **or**
  - the group has **no** `SkillGroupRequirement` rows (a basic group with no dependencies).

## Relationship to cascade
- R2 and R3 are normally satisfied **automatically** when raising a skill, via the cascade ([03](03-prerequisites-and-cascade.md) R3 auto-add prerequisites, R4 mastery escalation). Raising a skill pulls up its mastery and prerequisite groups on the same side rather than blocking.

## Server-cap gating
- **R4 — server cap gates reachable skill level.** Mastery level is hard-bounded by `server_level_cap` ([01](01-level-and-progression.md) R-cap). Because R2 ties skill level to mastery level via `mastery_level_req`, a skill level whose `mastery_level_req > server_level_cap` is **unreachable** on that server. Effective reachable skill level = highest level with `mastery_level_req ≤ server_level_cap` (and ≤ `max_skill_level`).
- **R5 — fully unreachable groups are hidden.** A `SkillGroup` whose effective reachable skill level (R4) is **0** — i.e. even its lowest skill level has `mastery_level_req > server_level_cap` — is **not rendered** in the planner view or the skill editor. Exception: if the character holds an allocation in the group (`current`/`target` > 0 on show; the edited side > 0 in the editor — e.g. the cap was lowered after allocation), the group stays visible so the player can correct it. A `SkillSeries` whose groups are all hidden is hidden entirely. Implemented in `EditorSeriesBuilder`.
