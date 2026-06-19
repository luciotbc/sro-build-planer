# 015 — Empty / loading / error states

## Ordem de Execução
Depende de: 007, 010
Executar antes de: —. Paralelo a: 016, 017.

## Objetivo
States consistentes em todas as telas do feature: sem personagens, sem skills no mastery, carregando, e erros de salvar — com cópia em inglês e a11y.

## Fluxo de Uso
Usuário novo sem personagens vê CTA criar; mastery sem skills mostra vazio; ações mostram loading; falhas mostram erro recuperável.

## Referências
- Mockup: `index.html`, `skills_editor.html` (estados implícitos).
- Design System: Hero/CharsDrawer/PlannerCard/SkillEditor (variantes vazias), `_button`.
- Specs: [05](../specs/05-character-lifecycle.md) (R10 auth/landing).
- Código: telas de 006/007/010, controllers.

## Escopo de Implementação
- **Frontend**: empty states (sem personagens → CTA; mastery vazio; drawer vazio); skeleton/spinner de loading; erro inline/toast.
- **Backend**: garantir que controllers retornam dados/erros consumíveis por esses states.
- **Estados**: vazio, loading, sucesso, erro — cobertos por tela.

## Critérios de Aceitação
- [ ] Cada tela tem vazio/loading/erro definidos e estilizados (DS).
- [ ] Cópia em inglês (regra do projeto), a11y (aria-live em erros).
- [ ] Sem telas "quebradas" quando faltam dados.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- Integração/system: user sem personagens → CTA; mastery sem skills → vazio; erro de save → mensagem.

## Boas Práticas
Consistência, DS, a11y, English-only, DRY (partial de empty state reutilizável).

## Modelo LLM Recomendado
Sonnet — estados/UX sobre telas existentes.

## Estratégia de Commit
`feat: empty states (characters/skills)` · `feat: loading + error states` · `test: state coverage`.
