# 009 — Stats summary panel

## Ordem de Execução
Depende de: 003, 007
Executar antes de: 017. Paralelo a: 008/010 (após deps).

## Objetivo
Painel SUMMARY do `index.html` (StatsSummary): SKILL POINTS, MASTERY TOTAL, REQUIRED LEVEL, cada um no formato `current + delta = planned`, ligado ao `Builds::SummaryService`.

## Fluxo de Uso
No planner, abaixo do skill window, o usuário vê os três totais agregados do build (current vs planejado).

## Referências
- Mockup: `index.html` (seção SUMMARY).
- Design System: StatsSummary, Stat, `_stat_row`.
- Specs: [02](../specs/02-sp-and-summary.md) (R3/R4/R5, formato `current+delta=planned`).
- Código: `app/views/shared/_stat_row.html.erb`, `Builds::SummaryService`.

## Escopo de Implementação
- **Frontend**: `shared/_stats_summary` reusando `_stat_row` (label, current, delta, planned) com `.tnum`; três linhas.
- **Backend**: consome `Builds::SummaryService.call(character).data`.
- **Estados**: build vazio → zeros; delta negativo formatado (sinal); loading.

## Critérios de Aceitação
- [ ] Três linhas com números do SummaryService (batendo spec 02).
- [ ] Formato `current + delta = planned`, tabular (`.tnum`), delta negativo correto.
- [ ] Atualiza ao mudar mastery/edições (Turbo).
- [ ] Aderente a mockup + DS (StatsSummary/Stat).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração: valores renderizados = SummaryService; vazio→zeros; delta negativo.

## Boas Práticas
Reuso `_stat_row`, DS, formatação localizada de números, DRY.

## Modelo LLM Recomendado
Sonnet — binding + formatação sobre serviço pronto.

## Estratégia de Commit
`feat: stats summary partial` · `test: stats summary rendering` · `feat: bind summary service + tnum formatting`.
