# 012 — Bulk skill actions (Max skills / Clear all / Undo)

## Ordem de Execução
Depende de: 010 (substrato de working-state/undo), 011
Executar antes de: —.

## Objetivo
Ações em massa do editor, escopadas ao **mastery ativo** e ao **lado editado**: Max skills, Clear all, e Undo de 1 passo.

## Fluxo de Uso
No editor: "Max skills" sobe todos os skills do mastery ao cap efetivo (respeitando pré-reqs); "Clear all" zera o lado editado só do mastery atual; "Undo" recupera o estado imediatamente anterior (ex: após Clear all acidental).

## Referências
- Mockup: `skills_editor.html` (Max skills, Undo, Clear all).
- Design System: SkillEditor, `_button` (incl. variante destrutiva).
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R3 escopo, R5 Max skills, R6 Clear all, R7 Undo), [04](../specs/04-skill-access-and-caps.md).
- Código: `CharacterSkills::{Update,Clear}Service` (por-lado), resolver (002).

## Escopo de Implementação
- **Frontend**: botões Max skills / Clear all (destrutivo) / Undo (habilitado só quando há estado anterior); todos escopados ao mastery ativo. Usa o **substrato de working-state/snapshot entregue em 010**.
- **Backend**: Max skills → para cada skill do mastery, set ao `min(max_skill_level, alcançável pelo server cap)` respeitando pré-reqs; Clear all → zera skills + nível da mastery do lado editado, só nesse mastery; Undo → restaura o snapshot imediatamente anterior (1 passo, spec 06 R7).
- **Clear all sem diálogo de confirmação**: a recuperação é feita exclusivamente pelo **Undo** (decisão: sem modal de confirmação no Clear all; Undo cobre o erro acidental — spec 06 R7).
- **Validações/erros**: Undo indisponível quando não há estado anterior (botão desabilitado).
- **Estados**: loading; sucesso; Undo desabilitado (sem snapshot).

## Critérios de Aceitação
- [ ] Max skills sobe ao cap efetivo respeitando pré-reqs, só no mastery ativo/lado.
- [ ] Clear all zera só o mastery ativo (outras intactas) no lado editado.
- [ ] Undo restaura estado imediatamente anterior (1 passo); Clear all não tem modal (Undo cobre).
- [ ] Outro lado nunca afetado.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- System/integração: Max skills→caps; Clear all não afeta outra mastery nem outro lado; Undo após Clear all recupera; Undo desabilitado inicialmente.

## Boas Práticas
SRP, reuso de serviços, DS, a11y, I18n, idempotência onde aplicável.

## Modelo LLM Recomendado
Opus — integridade de cascata + estado de Undo.

## Estratégia de Commit
`feat: max skills action` · `feat: clear all (mastery-scoped)` · `feat: single-step undo` · `test: bulk actions scope + undo`.
