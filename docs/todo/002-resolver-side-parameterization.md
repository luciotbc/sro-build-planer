# 002 — Resolver side-parameterization (current/planned cascade)

## Ordem de Execução
Depende de: 001
Executar antes de: 003, 010, 011, 012.

## Objetivo
Generalizar `PrerequisiteResolver` e os serviços de skill/mastery para operar por **lado** (`:current` | `:target`), habilitando cascata simétrica e independente no build planejado (hoje só o current cascateia). Consolida duplicações e itens restantes do `dev2.todo`.

## Fluxo de Uso
Backend — sem UI direta. Ao subir um skill planejado: auto-add de pré-reqs planejados, escala mastery planejada, sobe target class level; ao baixar: bloqueio por dependentes planejados.

## Referências
- Specs: [03](../specs/03-prerequisites-and-cascade.md) (R1 independência, R2 simetria, R3–R6), [04](../specs/04-skill-access-and-caps.md).
- Design System: —.
- Código: `app/services/character_skills/prerequisite_resolver.rb`, `add_service.rb`, `update_service.rb`, `clear_service.rb`, `app/services/character_masteries/*`.

## Escopo de Implementação
- **Resolver**: parametrizar por `side`; usar `#{side}_skill_level` / `#{side}_mastery_level` / class-level cache do lado; `sync_character_level` e `update_mastery` por lado.
- **Services**: `Add/Update/Clear` aceitam/derivam o lado; aplicar R3–R6 ao lado correto; `find_blocking_dependents` por lado.
- **DRY (dev2.todo #5)**: extrair `resolve_prerequisites` duplicado entre Add/Update para o mixin único.
- **dev2.todo restantes**: I18n em quaisquer strings de warning soltas (#8), `ApplicationRecord.transaction` consistente (#6/#10), rescue de `RecordInvalid` consistente (#7), N+1 em `find_blocking_dependents` (#3).
- **Validações/erros**: bloqueio de decremento com lista de dependentes (por lado); warnings via I18n.

## Critérios de Aceitação
- [ ] Subir skill planejado cascateia só no lado target (current intacto) e vice-versa.
- [ ] current e planned permanecem independentes (planned pode ser < current).
- [ ] Decremento bloqueado por dependentes do mesmo lado.
- [ ] Sem duplicação de `resolve_prerequisites`.
- [ ] N+1 de blocking dependents resolvido.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; rubocop limpo.

## Estratégia de Testes (TDD)
- Unit: resolver com side=:target adiciona pré-reqs no target; side=:current não afeta target.
- Integração: subir Pierce planejado auto-adiciona pré-req planejado + escala mastery planejada + sobe target_level; baixar com dependente planejado → erro.
- Regressão: comportamento current existente preservado (testes atuais verdes).

## Boas Práticas
DRY, SRP, baixo acoplamento, I18n, sem regressão de current.

## Modelo LLM Recomendado
Opus — lógica de cascata recursiva, edge cases, correctness.

## Estratégia de Commit
`refactor: parameterize prerequisite resolver by side` · `feat: planned-side cascade for skills/masteries` · `test: planned cascade + independence` · `fix: dedupe resolver and N+1 in blocking dependents`.
