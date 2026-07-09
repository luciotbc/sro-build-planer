# 05 — Character lifecycle (create, edit cap, race switch, delete)

**Purpose:** define destructive/cascade behavior across a character's lifecycle.
**How agents use this:** `Characters::{Create,Update,Delete}Service` and their UIs (CreateCharacter modal, character settings, delete control) follow these rules. Cross-links: [01-level-and-progression](01-level-and-progression.md), [03-prerequisites-and-cascade](03-prerequisites-and-cascade.md).

## Create
- **R1 —** a character is created with `name`, `race`, and `server_level_cap` (90/100/110/120/130). No masteries/skills initially ⇒ class levels default 0 ([01](01-level-and-progression.md) R1).

## Class level fields are caches, not inputs
- **R2 —** `current_level` / `target_level` are **derived caches** ([01](01-level-and-progression.md) R1) and must **not** be user-editable. The current `Characters::UpdateService` accepts them as params — that is a gap to remove; they are recomputed from masteries.

## Name & server level cap edit
- **R3 —** `server_level_cap` is **editable** after creation. `name` is also editable. Both are edited via the "Edit character" modal on the planner (hover pencil on the char bar — `shared/edit_character`, task 020). Race is **not** editable from this modal (see R5/R6).
- **R4 —** lowering `server_level_cap` below any existing mastery level (current **or** target, any mastery) is **rejected with an error** (consistent with the existing level-reduce guard). No silent clamp — the player must lower the masteries first. The error surfaces as a flash toast on redirect back to the planner.

## Race switch
- **R5 —** changing `race` **wipes all of the character's masteries and skills** (masteries are race-specific, so the build becomes invalid). Both sides (current + planned) are cleared.
- **R6 —** the UI must require an **explicit destructive confirmation** before a race switch.

## Delete
- **R7 —** deleting a character is a **hard delete**; dependent `character_masteries` and `character_skills` cascade away (`dependent: :destroy`). Not reversible.
- **R8 —** the UI must require confirmation before delete.

## Ownership & access
- **R9 — characters belong to a user.** `Character belongs_to :user`; **every** character/mastery/skill action is scoped to the authenticated user. _Gap: schema has no `characters.user_id` yet — migration + association is a foundational backlog item (alongside the `server_level_cap` column)._
- **R10 — auth required (MVP).** Creating, saving, and listing characters require login. There is **no guest/ephemeral planning** in the MVP (deferred to a future task). The `index.html` "Log in" state therefore shows the landing/Hero (no real build) for logged-out visitors; the planner is for authenticated users only.

## Build sharing (public read-only link)
- **R11 — permanent share token.** Every character carries a `share_token` (`has_secure_token`, **base58 × 10 ≈ 58 bits**), auto-generated on create and unique, for a **short** share URL. It is **not** regenerable or revocable, and it survives edits/renames. Its unguessability relies on the rate limit in R12, not on length alone.
- **R11a — visibility flag (opt-in sharing).** Every character carries a `public` boolean (`characters.public`, default **`false`**). A build is **private until the owner opts in**; the `share_token` always exists but the shared page is only reachable while `public` is true. Toggling `public` is owner-only (`PATCH /characters/:id/visibility`, `characters#visibility`) and is reversible — turning it off makes the existing link 404 again without changing the token.
- **R12 — public read-only page.** `GET /shared/:share_token` renders the build (identity bar, skills view, summary) **without authentication**, always reflecting the live build state (no snapshot) — **but only when the character is `public` (R11a)**. The page has **no edit affordances** and its mastery navigation stays on the shared route. A token that is unknown **or belongs to a private character** returns **404** (the two are indistinguishable, so visibility never leaks). The action is **rate-limited (20/min)** so the short token cannot be brute-forced; over the limit returns **429**. Mutating character routes remain owner-scoped per R9/R10.
- **R13 — share entry point.** The owner's planner (`characters#show`) exposes a **Sharing** card with a public/private toggle (`shared/toggle`, autosubmit). While public, the card reveals the share URL with a copy control (`clipboard`); the char-bar share button and the shared page's own re-share URL only appear while the build is public.
- **R14 — link previews.** The shared page carries OG meta tags: title = character name, image = race crest, description = one line per chosen mastery (`<Mastery> <current> → <target>`).

## Schema gaps (foundational backlog)
- Add `characters.user_id` (+ `belongs_to :user`, `User has_many :characters`).
- Add `characters.server_level_cap` (enum-like integer: 90/100/110/120/130).
- Reconsider `characters.current_level` / `target_level` as caches (R2), not inputs.
