# 006 — Chars drawer + auth-aware topbar

## Ordem de Execução
Depende de: 004
Executar antes de: 007. Paralelo a: 005.

## Objetivo
Listagem/troca de personagens (CharsDrawer) acionada pelo pill "Characters N" na topbar, e topbar ciente de autenticação (Log in vs Characters pill + Log out).

## Fluxo de Uso
Logado vê "Characters N" na topbar → clica → drawer lista personagens (nome, raça, cap) → seleciona um → vai ao planner dele; ou cria novo (abre modal 005). Deslogado vê "Log in".

## Referências
- Mockup: `index.html` (topbar "Log in"), `skills_editor.html` (topbar "Characters 3" + "Log out").
- Design System: CharsDrawer, CharsIcon, TopBar, `_drawer`, `_chars_pill`, `_topbar`.
- Specs: [05](../specs/05-character-lifecycle.md) (R9/R10).
- Código: `app/views/shared/_topbar.html.erb`, `_drawer.html.erb`, `_chars_pill.html.erb`, `app/javascript/controllers/dialog_controller.js`.

## Escopo de Implementação
- **Frontend**: variante autenticada do `_topbar` (pill + Log out) vs deslogada (Log in); `shared/_chars_drawer` (lista + item selecionável + ação "New character"); `_chars_icon` se necessário.
- **Backend**: drawer lê `Current.user.characters`; seleção navega a `character_path`.
- **Estados**: vazio (sem personagens → CTA criar; rico em 015); loading; ativo destacado.

## Critérios de Aceitação
- [ ] Topbar mostra estado correto por auth.
- [ ] Pill mostra contagem real; drawer lista personagens do user.
- [ ] Selecionar navega ao planner; "New character" abre modal 005.
- [ ] Aderente a mockup + DS (CharsDrawer/TopBar).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração/system: topbar autenticada vs não; drawer lista só do user; seleção navega; contagem no pill.

## Boas Práticas
Reuso `_drawer`/`_topbar`/`_chars_pill`, DS, a11y, I18n, DRY.

## Modelo LLM Recomendado
Sonnet — view + Stimulus drawer sobre componentes existentes.

## Estratégia de Commit
`feat: auth-aware topbar variants` · `feat: chars drawer partial` · `test: chars drawer + topbar states` · `feat: wire character selection navigation`.
