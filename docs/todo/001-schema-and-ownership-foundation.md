# 001 — Schema & ownership foundation

## Execution order
Depends on: 000
Run before: 002, 003, 004 (and transitively all).

## Objective
Close the schema/model gaps found during the interview so the whole feature layer can stand: per-user ownership, server level cap, class-level caches, and mastery bounded by the cap. Includes the still-pending hardening items from `dev2.todo`.

## Usage flow
Infrastructure/model — no UI flow. Enables per-user scoping and character creation with a server cap.

## References
- Specs: [05](../specs/05-character-lifecycle.md) (R9 ownership, R10 auth, schema gaps), [01](../specs/01-level-and-progression.md) (R-cap, caches R1/R2).
- Design System: — (no UI).
- Code: `app/models/character.rb`, `app/models/user.rb`, `app/services/characters/*`, `db/schema.rb`, `dev2.todo`.

## Implementation scope
- **Migrations**: add `characters.user_id` (FK, not null, index); add `characters.server_level_cap` (integer, not null); unique indexes on `character_masteries (character_id, mastery_id)` and `character_skills (character_id, skill_group_id)` (race conditions, dev2.todo #2).
- **Models**: `Character belongs_to :user`; `User has_many :characters, dependent: :destroy`; validate `server_level_cap` ∈ {90,100,110,120,130}; validate `current_/target_mastery_level ≤ character.server_level_cap` (replaces the `MAX_LEVEL`-only bound on `CharacterMastery`).
- **Caches**: recompute `current_level`/`target_level` from `MAX(mastery levels)` (callback/service); stop accepting them as editable input.
- **Hardening (remaining dev2.todo)**: verify/apply `inverse_of` (already on Character — confirm the rest), `ApplicationRecord.transaction` (already applied in some — sweep), remove redundant cascade in Delete/Update services.
- **Validations/errors**: messages via I18n.
- **Persistence**: SQLite; commit `db/schema.rb` + migrations together.

## Acceptance criteria
- [ ] `characters.user_id` and `server_level_cap` exist, with FK/indexes.
- [ ] Unique indexes on character_masteries and character_skills.
- [ ] `User has_many :characters`; character actions scopable per user.
- [ ] Mastery level validated against `server_level_cap`.
- [ ] `current_level`/`target_level` recomputed (cache), not accepted as input.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; rubocop/brakeman clean.
- [ ] Specs README unchanged, or updated if a rule changed.

## Testing strategy (TDD)
- Unit: `server_level_cap` validation, mastery ≤ cap, uniqueness (indexes), cache recomputation on mastery change.
- Integration: create character with user + cap; try to create a mastery above the cap (fails); duplicate mastery (fails on index).
- Regression: existing service suite stays green.

## Best practices
SOLID, reversible migrations, validation in the model (do not duplicate in the service — dev2.todo #4), I18n, low coupling.

## Recommended LLM model
Opus — cross-cutting structural change, correctness-critical.

## Commit strategy
`feat: add user ownership and server_level_cap to characters` · `test: character ownership + cap validations` · `refactor: bound mastery level by server cap` · `feat: recompute class-level caches from masteries` · `chore: unique indexes + dev2 hardening`.
