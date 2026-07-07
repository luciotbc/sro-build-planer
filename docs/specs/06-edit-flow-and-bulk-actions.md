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
- **R7 — Undo.** Single-step undo: restore the state of the active mastery as it was **immediately before the last bulk action** (R4/R5/R6). Not a full multi-step history; applies only to bulk actions (individual ± stepper clicks persist immediately and are not undo-able via this mechanism). Implemented (task 019) via a snapshot taken by the `skill-editor` Stimulus controller before each bulk action fires: `beforeBulk` captures each stepper's `{url, side, level}`, and Undo re-submits the snapshotted absolute levels through the existing stepper PATCH endpoints (no dedicated backend). The snapshot is dropped on mastery switch (`turbo:frame-load`) — undo is scoped to the active mastery — and cleared after use (one level of history).

## Persistence
- **R8 — per-step persistence (decided in task 010).** Each individual ± stepper click calls `CharacterSkills::UpdateService` / `AddService` immediately via Turbo Stream `PATCH /characters/:id/character_skills/:skill_group_id`. There is no explicit "Save" step for individual skill changes. Bulk actions (R4–R6, task 012) snapshot the active mastery state in a `skill-editor` Stimulus controller value before executing, enabling the single-step undo in R7.
- **R9 — slider persists on release (task 011).** The mastery-level slider renders live while dragging but persists only on release (the `change` event), as a **single** `PATCH /characters/:id/character_masteries/:mastery_id` with the final level — never one request per intermediate value. The PATCH carries the absolute level (not a delta), so discarded mid-drag values are harmless, and a still-in-flight request is aborted when a newer one starts. The ± stepper and "Max mastery" (R4) persist immediately per R8.
