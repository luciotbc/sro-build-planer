# Glossary — canonical domain terms

> Use these exact terms in code, UI copy, specs, and task files. If a new term appears, add it here. Game-jargon terms additionally must stay in English in every locale — see [game-jargon.md](game-jargon.md) ([08](08-i18n-conventions.md) R14).

| Term | Definition | Not to be confused with |
|---|---|---|
| Game max level | Absolute engine cap, `MAX_LEVEL = 150`. | Server level cap |
| Server level cap | Per-server max level chosen at character creation (90/100/110/120/130). `Character#server_level_cap`. | Game max level; class level |
| Class level | Character's level = `MAX` of its mastery levels. Cached as `current_level` (now) / `target_level` (planned). | Mastery level (per-mastery) |
| Current | The build as it exists now (white in UI). | Planned |
| Planned | The intended future build (brass in UI). | Current |
| Mastery | A skill tree branch (e.g. Heuksal) with a level. `CharacterMastery#{current,target}_mastery_level`. | Mastery type (Weapon/Force/...) |
| Skill series | A row/group of related skill groups within a mastery (e.g. "Pierce series"). `SkillSeries`. | Skill group |
| Skill group | One skill "slot" holding all level variants. `SkillGroup`. | Skill (single level) |
| Required level | Summary row = class level current → target. Derived, not stored. | Server level cap |
| `icon_path` | Game icon path relative to `app/assets/images`, on `Mastery`, `SkillGroup`, and `SkillSeries`. **Naming offset:** `Mastery#icon_path` → `skillmastery/<race>/…`, `SkillGroup#icon_path` → `skill/<race>/…`, `SkillSeries#icon_path` → `skillgroup/<race>/…` — the game's file prefix does not match our domain term. Populated by the XML importer from the node's `pict` attr (`.ddj`→`.png`). | The asset dir matching our term name (it does not) |
