# SRO Build Planner — Domain Specs

> **Audience: AI agents (and humans).** These documents are written as a *cognitive model* of the domain — single-concern files, explicit Given/When/Then rules, a shared glossary, and cross-links. Agents read this README **first** to navigate. Prefer tables and rule lists over prose. Assume no implied context.

## How agents use this
- Before implementing any `docs/todo/NNN-*.md` task, read the spec(s) it references here.
- Treat these rules as the source of truth for domain behavior. If code contradicts a rule, surface the conflict — do not silently follow the code.
- **Maintenance rule:** whenever any file in `docs/specs/` is added, changed, or removed, update this README in the same change.

## Navigation map

| Doc | Covers | Status |
|---|---|---|
| [01-level-and-progression.md](01-level-and-progression.md) | Server level cap, class level (current/target), required-level summary, level caches | draft |
| [02-sp-and-summary.md](02-sp-and-summary.md) | SKILL POINTS (mastery SP + skill SP), MASTERY TOTAL, REQUIRED LEVEL formulas | draft |
| [03-prerequisites-and-cascade.md](03-prerequisites-and-cascade.md) | Prereq auto-add, mastery escalation, class-level sync, skill-decrease blocking vs mastery-decrease auto-downgrade, current/planned independence, specs-over-mockup | draft |
| [04-skill-access-and-caps.md](04-skill-access-and-caps.md) | Skill ceiling (max_skill_level), mastery requirement, group unlock, server-cap gating | draft |
| [05-character-lifecycle.md](05-character-lifecycle.md) | Create, server-cap edit, race switch (wipe), hard delete, user ownership, auth-required | draft |
| [06-edit-flow-and-bulk-actions.md](06-edit-flow-and-bulk-actions.md) | current/planned toggle, Edit Current/Planned, editor scope, Max mastery/skills, Clear all, Undo | draft |
| [07-mastery-navigation.md](07-mastery-navigation.md) | Mastery group pills, mastery sub-tabs, content panel, state rules, invariants | draft |
| [glossary.md](glossary.md) | Canonical domain terms | draft |

> **Authority:** mockups govern layout/visual/interaction only; **these specs govern business rules** (see [03](03-prerequisites-and-cascade.md) M1).

_(Skill-vs-mastery level cap, edit-flow scoping, and race-switch/delete cascade specs to be added as the interview resolves them.)_
