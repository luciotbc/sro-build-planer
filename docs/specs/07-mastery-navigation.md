# 07 — Mastery Navigation

> **How agents use this:** Read before implementing any UI that lets a user switch between mastery groups or individual masteries. Rules here apply to `characters/show` (read-only planner) and `010-skill-editor-screen` (interactive editor). Client-side state management only — no session persistence between page loads.

## Overview

The mastery navigation is a two-row control composed of:

- **Row 1 — Mastery Group Pills** (`ro-tabs`): filter by mastery type (e.g. Weapon, Force, Recovery).
- **Row 2 — Mastery Sub-tabs** (`ro-subtabs`): masteries belonging to the active group.
- **Content Panel** (`skill-window` Turbo Frame): displays data for the active mastery.

---

## Invariants (must always hold)

| ID | Rule |
|---|---|
| INV-1 | Exactly one mastery group is active. |
| INV-2 | Exactly one mastery is active when masteries are available. |
| INV-3 | The content panel always reflects the active mastery. |
| INV-4 | Sub-tabs shown always belong to the active group. |

---

## Initial Render

**Given** a character page is loaded (full page load or reload):

- **When** the character has masteries:
  - The first mastery group (alphabetically) is active.
  - The first mastery of that group is active.
  - The content panel displays that mastery's content.
- **When** the character has no masteries:
  - No group pills, no sub-tabs, no content panel.
  - Empty state message is shown.

> **Note:** Prior navigation state is NOT restored on reload. Every full page load starts fresh.

---

## Group Switching Rules

**Given** the user clicks a group pill:

| Condition | Result |
|---|---|
| Clicked group is already active | No change. |
| Clicked group has a previous selection | Restore last selected mastery for that group → update content panel. |
| Clicked group has no previous selection | Select first mastery of that group → update content panel. |

Side effects (always):
- Clicked pill gains `on`. All other pills lose `on`.
- Sub-tabs row shows only masteries from the clicked group.
- Content panel updates to the resolved mastery.

---

## Mastery Switching Rules

**Given** the user clicks a mastery sub-tab:

- The clicked sub-tab gains `on`. All other sub-tabs in the same group lose `on`.
- The content panel updates to display the clicked mastery's content.
- The selection is stored as the last selection for this group (in-page memory, not persisted across reloads).

---

## Empty Groups

**Given** a mastery group has no masteries:

- The group pill is NOT rendered.
- The user cannot select an empty group.

> Groups with masteries are determined server-side at render time.

---

## State Persistence Rules

| Scope | Behavior |
|---|---|
| Within-page (Stimulus) | Last selected mastery per group is remembered until page reload. |
| Between reloads | State is NOT restored. First group + first mastery always shown. |
| URL param `mastery_id` | Used only for Turbo Frame content requests. Does not affect pill/sub-tab server-rendered state on full page loads. |

---

## Implementation Notes

- **Client-side controller:** `mastery_tabs_controller.js` — domain-specific, not a generic tabs controller.
- **Server-side:** Renders correct initial active group, panel, and sub-tab based on `@active_mastery` (first mastery of first group on initial load).
- **Turbo Frame:** `skill-window` frame is updated programmatically when navigating via pills; updated by default Turbo link behavior when clicking sub-tabs.
- **No persistence:** No `localStorage`, `sessionStorage`, or cookie — state is in-memory per Stimulus controller instance.

---

## Cross-references

- [06-edit-flow-and-bulk-actions.md](06-edit-flow-and-bulk-actions.md) — skill editor screen shares this navigation component.
- [glossary.md](glossary.md) — mastery, mastery type, mastery group.
- `docs/todo/008-mastery-section-tabs.md` — implementation task.
- `docs/todo/010-skill-editor-screen.md` — reuses this nav on the editor.
