# 05 — Character lifecycle (create, edit cap, race switch, delete)

**Purpose:** define destructive/cascade behavior across a character's lifecycle.
**How agents use this:** `Characters::{Create,Update,Delete}Service` and their UIs (CreateCharacter modal, character settings, delete control) follow these rules. Cross-links: [01-level-and-progression](01-level-and-progression.md), [03-prerequisites-and-cascade](03-prerequisites-and-cascade.md).

## Create
- **R1 —** a character is created with `name`, `race`, and `server_level_cap` (90/100/110/120/130). No masteries/skills initially ⇒ class levels default 0 ([01](01-level-and-progression.md) R1).

## Class level fields are caches, not inputs
- **R2 —** `current_level` / `target_level` are **derived caches** ([01](01-level-and-progression.md) R1) and must **not** be user-editable. The current `Characters::UpdateService` accepts them as params — that is a gap to remove; they are recomputed from masteries.

## Server level cap edit
- **R3 —** `server_level_cap` is **editable** after creation.
- **R4 —** lowering `server_level_cap` below any existing mastery level (current **or** target, any mastery) is **rejected with an error** (consistent with the existing level-reduce guard). No silent clamp — the player must lower the masteries first.

## Race switch
- **R5 —** changing `race` **wipes all of the character's masteries and skills** (masteries are race-specific, so the build becomes invalid). Both sides (current + planned) are cleared.
- **R6 —** the UI must require an **explicit destructive confirmation** before a race switch.

## Delete
- **R7 —** deleting a character is a **hard delete**; dependent `character_masteries` and `character_skills` cascade away (`dependent: :destroy`). Not reversible.
- **R8 —** the UI must require confirmation before delete.

## Ownership & access
- **R9 — characters belong to a user.** `Character belongs_to :user`; **every** character/mastery/skill action is scoped to the authenticated user. _Gap: schema has no `characters.user_id` yet — migration + association is a foundational backlog item (alongside the `server_level_cap` column)._
- **R10 — auth required (MVP).** Creating, saving, and listing characters require login. There is **no guest/ephemeral planning** in the MVP (deferred to a future task). The `index.html` "Log in" state therefore shows the landing/Hero (no real build) for logged-out visitors; the planner is for authenticated users only.

## Schema gaps (foundational backlog)
- Add `characters.user_id` (+ `belongs_to :user`, `User has_many :characters`).
- Add `characters.server_level_cap` (enum-like integer: 90/100/110/120/130).
- Reconsider `characters.current_level` / `target_level` as caches (R2), not inputs.
