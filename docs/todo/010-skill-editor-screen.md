# 010 — Skill editor screen (skills_editor.html)

## Ordem de Execução
Depende de: 002, 007, 008
Executar antes de: 011, 012, 013, 014, 015, 016, 017.

## Objetivo
Tela de edição de skills (SkillEditor) do `skills_editor.html`, parametrizada por **lado** (current ou planned): séries colapsáveis (SkillSeries), linhas de skill (SkillRow) com steppers ± mostrando `nível / cap`, e cabeçalho da mastery. Edição respeita as regras de cascata.

## Fluxo de Uso
Do planner, "Edit Current"/"Edit Planned" abre o editor naquele lado para o mastery ativo. Usuário expande uma série, usa ± para ajustar skills; cascata aplica pré-reqs/mastery; ao salvar, persiste; volta ao planner.

## Referências
- Mockup: `skills_editor.html`.
- Design System: SkillEditor, SkillRow, SeriesInfoPanel, `_skill_row`, `_button`, `_tabs`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R2/R3), [03](../specs/03-prerequisites-and-cascade.md), [04](../specs/04-skill-access-and-caps.md).
- Código: `app/views/shared/_skill_row.html.erb`, `app/javascript/controllers/stepper_controller.js`, `CharacterSkills::{Add,Update,Clear}Service` (já por-lado após 002).

## Escopo de Implementação
- **Frontend**: `shared/_skill_editor` + `shared/_series_group` (colapsável, contador `X/Y`); `_skill_row` com ± (Stimulus stepper) exibindo `nível / cap_efetivo`; lado vindo do param; hint de hold +/−.
- **Working-state / undo substrate (fundação p/ 012)**: definir e entregar o mecanismo de estado de edição não-salvo que habilita o **undo de 1 passo** (spec 06 R7/R8) — snapshot do estado anterior do mastery ativo antes de cada ação em massa. Decidir e documentar a abordagem (working copy no client via Stimulus values vs round-trip por ação com snapshot no server). 012 consome esse substrato.
- **Backend**: ações ± chamam serviços por lado; `cap_efetivo = min(max_skill_level, alcançável pelo server cap)`; cascata via resolver (002).
- **Validações/erros**: bloqueio de decremento por dependentes → erro/toast (toast detalhado em 013); cap respeitado.
- **Estados**: série vazia/0 alocados; loading por ação; sucesso; erro.

## Critérios de Aceitação
- [ ] Editor abre no lado correto (current/planned) conforme entrada.
- [ ] Substrato de working-state (snapshot do mastery ativo) entregue e documentado — habilita undo de 1 passo (consumido por 012).
- [ ] ± respeita cap efetivo e aplica cascata (pré-reqs/mastery) no lado certo.
- [ ] Séries colapsam/expandem; contadores corretos.
- [ ] Decremento bloqueado por dependente → feedback (sem corromper estado).
- [ ] Aderente a mockup + DS; current intacto ao editar planned.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- System/integração: subir skill planejado → pré-req planejado aparece; cap efetivo limita; current inalterado; decremento bloqueado mostra erro; colapso de série.

## Boas Práticas
Reuso `_skill_row`/`stepper`, DS, SRP, baixo acoplamento, a11y, I18n; regra de negócio nas specs (não no mockup).

## Modelo LLM Recomendado
Opus — interação mais complexa, cascata por lado, muitos edge cases.

## Estratégia de Commit
`feat: series group collapsible partial` · `feat: skill editor screen (side-parameterized)` · `feat: stepper ± wired to side services` · `test: editor cascade + cap + independence`.
