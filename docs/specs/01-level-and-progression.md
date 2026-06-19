# 01 — Level & Progression

**Purpose:** define every "level" number in the planner and how they relate.
**How agents use this:** when rendering the character bar, the StatsSummary "REQUIRED LEVEL" row, or validating level inputs, follow these rules. Cross-links: [glossary](glossary.md), SP calc (TBD), prerequisite cascade (TBD).

## Concepts

| Term | Meaning | Stored? | Range |
|---|---|---|---|
| Game max level | Absolute engine limit. `Character::MAX_LEVEL`. | constant | 150 |
| **Server level cap** | The server's max level, chosen at character creation. New attribute `Character#server_level_cap`. A domain concept distinct from game max level. | stored (enum) | 90, 100, 110, 120, 130 |
| **Class level (current)** | The character's real class level now = highest current mastery level. Cached in `Character#current_level`. | cached | 0..server_level_cap |
| **Class level (target/planned)** | Planned class level = highest planned mastery level. Cached in `Character#target_level`. | cached | 0..server_level_cap |

## Rules

- **R1 — Class level is derived from masteries (cache).**
  `Character#current_level` = `MAX(CharacterMastery#current_mastery_level)` over the character's masteries.
  `Character#target_level` = `MAX(CharacterMastery#target_mastery_level)`.
  Equivalent: `SELECT MAX(current_mastery_level), MAX(target_mastery_level) FROM character_masteries WHERE character_id = ?`.
  These columns are a **cache** of that aggregate, kept in sync whenever a mastery level changes. (No character with zero masteries ⇒ both default 0.)

- **R2 — REQUIRED LEVEL summary row** = `current_level → target_level`.
  Displayed as `current_level  +  (target_level − current_level)  =  target_level`.
  The delta `target_level − current_level` **may be negative** (planned lower than current).

- **R3 — Server cap is the planning ceiling.** `server_level_cap` is shown as "LEVEL CAP" in the UI. It bounds how high the planned build can be driven (mastery/skill caps derive from it — see SP calc / mastery rules, TBD). `server_level_cap ≤ MAX_LEVEL`.

- **R-cap — mastery level is hard-bounded by `server_level_cap`.** `CharacterMastery#{current,target}_mastery_level ≤ server_level_cap ≤ MAX_LEVEL`. This is the active validation bound (replaces the model's current `MAX_LEVEL`-only check). Consequently class level ([R1]) ≤ `server_level_cap`, and skill reachability is gated (see [04](04-skill-access-and-caps.md) R4).

## Open (to resolve in interview)
- Is `server_level_cap` editable after creation, or create-only? (If editable and lowered below an existing mastery level, define the cascade.)
- How are `current_level`/`target_level` caches recomputed (callback vs service) — implementation detail, but invariant R1 must hold.
