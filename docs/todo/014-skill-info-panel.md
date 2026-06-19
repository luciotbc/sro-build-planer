# 014 — Skill & series info panel

## Ordem de Execução
Depende de: 010
Executar antes de: —. Paralelo a: 013.

## Objetivo
Painéis de detalhe SkillInfoPanel (por skill: sp_cost, mp_cost, mastery_level_req, pré-reqs) e SeriesInfoPanel (por série), acessíveis no editor/planner.

## Fluxo de Uso
Usuário clica/hover num skill (ou cabeçalho de série) → painel mostra detalhes (custos, requisito de mastery, pré-requisitos, descrição se houver).

## Referências
- Mockup: `skills_editor.html` (linhas de skill / séries).
- Design System: SkillInfoPanel, SeriesInfoPanel, `_sheet`/`_drawer` (overlay).
- Specs: [04](../specs/04-skill-access-and-caps.md) (mastery_req, unlock), [02](../specs/02-sp-and-summary.md) (sp_cost).
- Código: `app/models/skill.rb`, `skill_group_requirement.rb`, `skill_series.rb`, `_sheet.html.erb`.

## Escopo de Implementação
- **Frontend**: `shared/_skill_info_panel` e `shared/_series_info_panel` (overlay via `_sheet` ou popover); dados do skill/série.
- **Backend**: carregar skill por nível (`skill_at_level`) + requirements.
- **Estados**: skill sem requisitos (básico); loading; vazio.

## Critérios de Aceitação
- [ ] Painel de skill mostra sp/mp cost, mastery_level_req, pré-reqs corretos.
- [ ] Painel de série mostra resumo da série.
- [ ] Abre/fecha acessível (Esc/backdrop); aderente a DS.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração/system: painel mostra custos/reqs do skill selecionado; série lista grupos; grupo básico sem reqs.

## Boas Práticas
Reuso `_sheet`, DS, a11y, I18n, apresentação separada de dados.

## Modelo LLM Recomendado
Sonnet — apresentacional sobre dados existentes.

## Estratégia de Commit
`feat: skill info panel` · `feat: series info panel` · `test: info panels content`.
