# 017 — Design system parity (+ design-sync)

## Ordem de Execução
Depende de: 007, 009, 010
Executar antes de: — (penúltima, antes da auditoria final).

## Objetivo
Garantir que todos os componentes compostos criados (PlannerCard, ReadOnlySkillWindow, MasterySection, StatsSummary, SkillEditor, SeriesInfoPanel, SkillInfoPanel, CreateCharacter, CharsDrawer, toast) estejam: (a) na doc viva `/docs/design_system`, (b) sem duplicação/fork de estilo, (c) sincronizados com o DS publicado via `/design-sync`.

## Fluxo de Uso
Dev/designer abre `/docs/design_system` e vê todos os componentes reais renderizados; DS publicado (`89e0df02`) reflete o código.

## Referências
- DS publicado: `89e0df02` (SROLabDS, 19 componentes) — contratos `*.prompt.md`/`.d.ts`/`.html`.
- Design System local: `app/views/docs/design_system.html.erb`, `app/views/shared/*`, `app/assets/tailwind/application.css`.
- Skill/tool: `/design-sync` (`DesignSync`).

## Escopo de Implementação
- **Frontend**: adicionar cada novo partial à `docs/design_system.html.erb` (render vivo + snippet via DocsController); auditar tokens/classes vs DS (sem cores hardcoded fora dos tokens); remover componentes duplicados.
- **Sync**: rodar `/design-sync` para republicar o DS a partir do código; registrar notas de commit.
- **Estados**: cada componente com suas variantes/estados na doc.

## Critérios de Aceitação
- [ ] Todos os novos componentes aparecem em `/docs/design_system` (render vivo).
- [ ] Sem cores/medidas hardcoded fora dos tokens; sem partial duplicado.
- [ ] `/design-sync` executado; DS publicado atualizado.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração: `/docs/design_system` renderiza cada novo partial sem erro; smoke de que classes usadas existem no `@layer components`.

## Boas Práticas
DS como fonte única, tokens-first, sem fork, doc viva (não diverge do app), DRY.

## Modelo LLM Recomendado
Sonnet — auditoria/doc + execução de design-sync.

## Estratégia de Commit
`feat: add composite components to living design system` · `refactor: dedupe + tokenize styles` · `chore: design-sync republish`.
