# 005 — Create character modal

## Ordem de Execução
Depende de: 004
Executar antes de: 007. Paralelo a: 006.

## Objetivo
Modal "New character" (componente CreateCharacter) com nome, tipo (Chinese/European) e server level cap (90/100/110/120/130), ligado ao `Characters::CreateService`.

## Fluxo de Uso
Logado clica "New character" → modal abre → preenche nome, escolhe raça (glyph Chinese/European), escolhe cap → "Start Build" → cria e navega ao planner do novo personagem.

## Referências
- Mockup: `index.html` (modal New character).
- Design System: CreateCharacter, ChineseGlyph, EuropeanGlyph, `_modal`, `_button`.
- Specs: [05](../specs/05-character-lifecycle.md) (R1 create), [01](../specs/01-level-and-progression.md) (cap enum).
- Código: `app/views/shared/_modal.html.erb`, `app/javascript/controllers/dialog_controller.js`, `Characters::CreateService`.

## Escopo de Implementação
- **Frontend**: partial `shared/_create_character` usando `_modal`; seletor de raça (dois cards com glyphs); seletor de cap (5 opções, default 110/Standard); usa Stimulus `dialog`.
- **Glyphs**: criar partials `_chinese_glyph` / `_european_glyph` (ícones DS).
- **Backend**: submit → CreateService (já existe); definir `race_id` + `server_level_cap` + `name`.
- **Validações/erros**: nome obrigatório, cap obrigatório; erros renderizados no modal (preservar estado).
- **Estados**: loading no submit; sucesso → redirect planner; erro → mensagens inline.

## Critérios de Aceitação
- [ ] Modal abre/fecha (Esc/backdrop) via Stimulus.
- [ ] Cria personagem com raça e cap corretos; navega ao planner.
- [ ] Erros de validação exibidos sem perder dados digitados.
- [ ] Aderente ao mockup (layout/tokens) e DS (CreateCharacter, glyphs).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; sem erros no console.

## Estratégia de Testes (TDD)
- System/integração: abrir modal, criar válido → planner; submit inválido → erro inline; cap default correto.
- Unit: partial renderiza opções de cap/raça.

## Boas Práticas
Reuso de `_modal`/`_button`, DS, DRY, a11y (focus trap, labels), I18n.

## Modelo LLM Recomendado
Sonnet — form + modal sobre componentes existentes.

## Estratégia de Commit
`feat: chinese/european glyph partials` · `feat: create character modal partial` · `test: create character flow` · `feat: wire modal to CreateService`.
