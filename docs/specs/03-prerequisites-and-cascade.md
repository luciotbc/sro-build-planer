# 03 — Prerequisites & cascade

**Purpose:** define how editing one skill cascades to prerequisites, mastery level, and class level — for both the current and planned builds.
**How agents use this:** `CharacterSkills::*` and `CharacterMasteries::*` services + `PrerequisiteResolver` must obey these rules. Cross-links: [01-level-and-progression](01-level-and-progression.md), [02-sp-and-summary](02-sp-and-summary.md).

## Meta-rule (authority)
- **M1 — Specs over mockup.** The mockups (`index.html`, `skills_editor.html`) are functional but **do not implement business rules correctly**. They are the authority for *layout / visual / interaction*, **not** for domain behavior. When mockup and these specs disagree on a rule, the spec wins.

## Two independent builds
- **R1 — current and planned are fully independent.** Each `CharacterSkill` has `current_skill_level` and `target_skill_level`; each `CharacterMastery` has `current_mastery_level` and `target_mastery_level`. There is **no ordering constraint** between them — `target` may be less than, equal to, or greater than `current`.
- **R2 — symmetric cascade by side.** All cascade logic runs on **one side at a time**, parameterized by side ∈ {`:current`, `:target`}:
  - editing the **planned** build (the "FUTURE SKILLS / PLANNING" editor, "Edit Planned") cascades on `target_*` fields;
  - editing the **current** build ("Edit Current") cascades on `current_*` fields.
  - The two sides never affect each other.

## Cascade on increase (per side)
Given a skill raised to level N on side S:
- **R3 — auto-add prerequisites.** For each `SkillGroupRequirement` of the skill's group with `required_skill_level > 0`: ensure the required group exists for the character at side-level ≥ `required_skill_level`, recursively (DFS, cycle-guarded). Newly added groups are created on side S. Emits a warning per auto-add.
- **R4 — mastery escalation.** Raising a skill to a level whose `mastery_level_req` exceeds the character's side mastery level raises that `*_mastery_level` to the requirement. Emits a warning.
- **R5 — class-level sync.** After R4, the side class-level cache (`current_level`/`target_level`, see [01](01-level-and-progression.md) R1) is kept = `MAX` of that side's mastery levels.

## Cascade on decrease (per side)
- **R6 — blocking dependents (skill decrease).** Lowering a **skill** below a level still required by another allocated skill (on the same side) is **rejected** with an error listing the blockers. (No silent cascade-down of skill→skill dependents.)
- **R7 — mastery decrease auto-downgrades skills.** Lowering a **mastery** level (on a side) below the `mastery_level_req` of skills allocated under it **auto-downgrades** each affected skill to the highest level still valid for the new mastery level (per [04](04-skill-access-and-caps.md) R2), emitting a warning per downgrade. This is asymmetric to R6 by design (confirmed): mastery decrease cascades down to skills; skill decrease blocks on skill dependents. Matches the existing `CharacterMasteries::UpdateService` behavior. The side class-level cache is then resynced ([01](01-level-and-progression.md) R1).

## Implementation status
- **Resolved (task 002).** `PrerequisiteResolver`, `update_mastery`, and `find_blocking_dependents` are fully side-parameterized: all use `:"#{side}_skill_level"` / `:"#{side}_mastery_level"` and accept a `side` argument. `CharacterSkills::{Add,Update,Clear}Service` pass the correct side for each cascade operation. R3–R6 apply to both sides independently.
