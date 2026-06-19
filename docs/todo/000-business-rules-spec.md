# 000 — Business-rules spec (docs/specs)

## Ordem de Execução
Depende de: — (primeiro)
Executar antes de: todas as demais tasks.
Status: **CONCLUÍDO** (via skill `grill-with-docs`).

## Objetivo
Capturar as regras de negócio do planner como *cognitive model* consumível por agentes de IA, em `docs/specs/`, com `README.md` de navegação. Fonte de verdade para comportamento de domínio (mockup só governa visual/interação).

## Entregue
- `docs/specs/README.md` — mapa de navegação (atualizar a cada mudança em specs).
- `docs/specs/glossary.md` — termos canônicos.
- `docs/specs/01-level-and-progression.md` — server cap, class level (cache), required level.
- `docs/specs/02-sp-and-summary.md` — SKILL POINTS (mastery SP + skill SP), MASTERY TOTAL, REQUIRED LEVEL.
- `docs/specs/03-prerequisites-and-cascade.md` — cascata simétrica por lado, current/planned independentes, specs>mockup.
- `docs/specs/04-skill-access-and-caps.md` — max_skill_level, mastery_req, unlock, server-cap gating.
- `docs/specs/05-character-lifecycle.md` — cap editável+bloqueio, race wipe, hard delete, ownership, auth-required.
- `docs/specs/06-edit-flow-and-bulk-actions.md` — toggle current/planned, editor por-lado, Max mastery/skills, Clear all, Undo.

## Critérios de Aceitação
- [x] README mapeia todas as specs.
- [x] Cada spec single-concern, com "How agents use this", regras Given/When/Then, cross-links.
- [x] Glossário com termos canônicos.
- [x] Regras dúbias resolvidas com o stakeholder.

## Boas Práticas
Documentation as a Cognitive Model; AI-digestible; single source of truth; manter README sincronizado (regra na DoC de toda task).

## Modelo LLM Recomendado
Opus — extração de regras ambíguas + entrevista.
