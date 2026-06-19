# 007 — Planner read-only view (index.html)

## Ordem de Execução
Depende de: 003, 004
Executar antes de: 008, 009, 010, 015, 016, 017.

## Objetivo
Renderizar a tela principal do planner (read-only) do mockup `index.html`: PlannerCard com character bar, ReadOnlySkillWindow mostrando níveis current→planned, e os pontos de entrada Edit Current / Edit Planned.

## Fluxo de Uso
Logado abre um personagem → vê barra (nome, raça, LEVEL CAP), seção SKILLS com o mastery ativo e seus skills (níveis current→planned, white/brass), toggle Current↔Planned, botões Edit Current/Edit Planned, e ações Delete/Save character.

## Referências
- Mockup: `index.html` (planner completo).
- Design System: PlannerCard, ReadOnlySkillWindow, `_char_bar`, `_skill_row`, `_badge` (current/planned), `_button`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R1/R2), [01](../specs/01-level-and-progression.md), [04](../specs/04-skill-access-and-caps.md).
- Código: `app/views/shared/_char_bar.html.erb`, `_skill_row.html.erb`, `_badge.html.erb`, `CharactersController#show`, `Builds::SummaryService`.

## Escopo de Implementação
- **Frontend**: `characters/show` com PlannerCard (`shared/_planner_card`), character bar (cap em destaque), `shared/_read_only_skill_window` reusando `_skill_row` (exibe `current → planned` por skill, cores white/brass); toggle Current↔Planned (Stimulus); botões Edit Current/Edit Planned (link ao editor 010 por lado); Delete (confirm) / Save.
- **Backend**: show carrega personagem + masteries + skills do mastery ativo; níveis exibidos conforme specs.
- **Estados**: sem skills no mastery → vazio (rico em 015); loading.
- Tabs de mastery entram em 008 (aqui, mastery ativo default).

## Critérios de Aceitação
- [ ] Layout fiel ao `index.html` (tokens, espaçamento, hierarquia).
- [ ] Skills mostram current→planned com cores corretas.
- [ ] Toggle Current↔Planned funciona.
- [ ] Edit Current/Edit Planned levam ao editor do lado certo.
- [ ] Read-only (sem steppers aqui).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração/system: show renderiza barra + skills; toggle alterna ênfase; links de edição apontam ao lado correto; vazio.

## Boas Práticas
Reuso de partials, DS, separação view/serviço, a11y, I18n.

## Modelo LLM Recomendado
Opus — compõe cálculo + dados + fidelidade de layout.

## Estratégia de Commit
`feat: planner card + character bar` · `feat: read-only skill window` · `feat: current/planned toggle` · `test: planner show read-only` · `feat: edit-current/planned entry links`.
