# 016 — Responsive / mobile

## Ordem de Execução
Depende de: 007, 010
Executar antes de: —. Paralelo a: 015, 017.

## Objetivo
Adaptar planner e editor a viewports estreitos: drawer→sheet onde fizer sentido, tabs de mastery roláveis, editor utilizável no mobile, respeitando `--spacing-tap` (44px).

## Fluxo de Uso
Em tela pequena, usuário navega masteries, edita skills (steppers com alvo de toque adequado), abre drawer/sheet de personagens e info panels sem quebra de layout.

## Referências
- Mockup: `index.html`, `skills_editor.html` (referência desktop; derivar mobile).
- Design System: `_drawer`/`_sheet`, tokens (`--spacing-tap`), tabs.
- Specs: —.
- Código: `app/assets/tailwind/application.css`, partials de 006–014.

## Escopo de Implementação
- **Frontend**: breakpoints Tailwind; converter overlays para `_sheet` no mobile; tabs com scroll horizontal; targets de toque ≥44px; tabelas/stat rows empilháveis.
- **Estados**: idem desktop, validados em mobile.

## Critérios de Aceitação
- [ ] Planner e editor usáveis em ~380px sem overflow horizontal.
- [ ] Alvos de toque ≥44px; tabs acessíveis no mobile.
- [ ] Overlays apropriados (sheet) no mobile.
- [ ] Validado no Chrome (emulação mobile); console limpo.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde.

## Estratégia de Testes (TDD)
- System (viewport mobile): navegação de tabs, edição de skill, abertura de drawer/sheet sem quebra.

## Boas Práticas
Mobile-first onde possível, tokens do DS, a11y de toque, sem CSS forkado.

## Modelo LLM Recomendado
Sonnet — CSS/responsivo.

## Estratégia de Commit
`feat: responsive planner` · `feat: responsive editor + sheet overlays` · `test: mobile viewport flows`.
