# 008 — Mastery section tabs

## Ordem de Execução
Depende de: 007
Executar antes de: 010.

## Objetivo
Navegação de masteries do mockup: tabs de tipo (Weapon/Force/Recovery) + sub-tabs de mastery (ex Bicheon/Heuksal/Pacheon), trocando o conteúdo do skill window sem reload (Turbo frame / Stimulus).

## Fluxo de Uso
No planner, usuário troca tipo de mastery (linha 1) e mastery específica (linha 2) → skill window atualiza para a mastery escolhida.

## Referências
- Mockup: `index.html` e `skills_editor.html` (duas linhas de tabs).
- Design System: MasterySection, `_tabs` (default + underline), TopBar.
- Specs: [glossary](../specs/glossary.md) (mastery vs mastery type).
- Código: `app/views/shared/_tabs.html.erb`, `app/javascript/controllers/tabs_controller.js`, `app/models/mastery.rb` (mastery_type enum).

## Escopo de Implementação
- **Frontend**: `shared/_mastery_section` com tabs de `mastery_type` (linha 1, variante pill) + sub-tabs de masteries daquele tipo/raça (linha 2, variante underline); troca via Turbo Frame (recarrega skill window) ou Stimulus + Turbo.
- **Backend**: endpoint/param `mastery_id` no show; lista masteries por raça agrupadas por tipo.
- **Estados**: tipo sem masteries → tab desabilitada/oculta; mastery ativa destacada.

## Critérios de Aceitação
- [ ] Tabs de tipo e sub-tabs renderizadas conforme raça do personagem.
- [ ] Trocar tab atualiza o skill window sem full reload.
- [ ] Mastery ativa persistida na navegação (param/estado).
- [ ] Aderente a mockup + DS (MasterySection, `_tabs`).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração/system: tabs refletem masteries da raça; trocar tab muda skills exibidos; estado ativo correto.

## Boas Práticas
Reuso `_tabs`, DS, Turbo, DRY, a11y (roles/aria-selected), I18n.

## Modelo LLM Recomendado
Sonnet — wiring de tabs sobre componente existente.

## Estratégia de Commit
`feat: mastery section type + sub tabs` · `feat: turbo frame skill window swap` · `test: mastery tab navigation`.
