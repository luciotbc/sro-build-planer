# 000 — Business-rules spec (docs/specs)

## Execution order
Depends on: — (first)
Run before: all other tasks.
Status: **DONE** (via the `grill-with-docs` skill).

## Objective
Capture the planner's business rules as a *cognitive model* consumable by AI agents, under `docs/specs/`, with a `README.md` navigation map. Source of truth for domain behavior (the mockup governs visual/interaction only).

## Delivered
- `docs/specs/README.md` — navigation map (update on every spec change).
- `docs/specs/glossary.md` — canonical terms.
- `docs/specs/01-level-and-progression.md` — server cap, class level (cache), required level.
- `docs/specs/02-sp-and-summary.md` — SKILL POINTS (mastery SP + skill SP), MASTERY TOTAL, REQUIRED LEVEL.
- `docs/specs/03-prerequisites-and-cascade.md` — side-symmetric cascade, current/planned independence, specs > mockup.
- `docs/specs/04-skill-access-and-caps.md` — max_skill_level, mastery_req, unlock, server-cap gating.
- `docs/specs/05-character-lifecycle.md` — editable cap + blocking, race wipe, hard delete, ownership, auth-required.
- `docs/specs/06-edit-flow-and-bulk-actions.md` — current/planned toggle, side-parameterized editor, Max mastery/skills, Clear all, Undo.

## Acceptance criteria
- [x] README maps all specs.
- [x] Each spec is single-concern, with "How agents use this", Given/When/Then rules, cross-links.
- [x] Glossary with canonical terms.
- [x] Ambiguous rules resolved with the stakeholder.

## Best practices
Documentation as a Cognitive Model; AI-digestible; single source of truth; keep the README in sync (rule in every task's Definition of Done).

## Recommended LLM model
Opus — ambiguous rule extraction + interview.
