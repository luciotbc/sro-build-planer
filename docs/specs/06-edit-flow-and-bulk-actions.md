# 06 — Edit flow & bulk actions

**Purpose:** define the current/planned edit flow and the editor's bulk actions.
**How agents use this:** the planner (`index.html`) toggle/edit buttons, the editor (`skills_editor.html`) controls, and `CharacterSkills::*` / `CharacterMasteries::*` services follow these rules. Cross-links: [03-prerequisites-and-cascade](03-prerequisites-and-cascade.md), [04-skill-access-and-caps](04-skill-access-and-caps.md), [02-sp-and-summary](02-sp-and-summary.md).

## current/planned (white/brass)
- **R1 —** the planner shows both builds: **current = white**, **planned = brass** ([glossary](glossary.md)). The "Current ↔ Planned" control toggles which side is emphasized in the read-only view.
- **R2 —** two entry points to editing: **Edit Current** and **Edit Planned**. The editor is **parameterized by side**; it edits exactly one side at a time (`:current` or `:target`), applying all cascade rules ([03](03-prerequisites-and-cascade.md) R2) to that side only.

## Editor scope
- **R3 — all editor actions are scoped to the currently selected mastery (the active tab).** Never the whole character. Switching mastery tab changes the scope.

## Bulk actions (operate on the active mastery, on the edited side)
- **R4 — Max mastery.** Raise the active mastery's level (edited side) to `server_level_cap` ([01](01-level-and-progression.md) R-cap). This is the mastery's max.
- **R5 — Max skills.** Raise every skill in the active mastery to its **effective cap** = `min(max_skill_level, highest level with mastery_level_req ≤ server_level_cap)` ([04](04-skill-access-and-caps.md) R1/R4), respecting prerequisites ([03](03-prerequisites-and-cascade.md) R3).
- **R6 — Clear all.** Reset the edited side to 0 for **the active mastery only** (its skills and that mastery's level on the edited side). Other masteries untouched.
- **R7 — Undo.** Single-step undo: restore the **immediately previous unsaved state** of the active mastery (e.g. recover after an accidental Clear all). Not a full multi-step history.

## Persistence
- **R8 —** edits are committed via the existing services on **Save**; until saved, the editor holds working state (enabling R7 single-step undo). _(Implementation choice — server round-trip per step vs client working copy — to be decided in the editor task; the single-step-undo behavior is the requirement.)_
