# 001 — Schema & ownership foundation

## Ordem de Execução
Depende de: 000
Executar antes de: 002, 003, 004 (e transitivamente todas).

## Objetivo
Fechar os gaps de schema/modelo descobertos na entrevista para sustentar todo o feature layer: propriedade por usuário, server level cap, caches de class level, e bound de mastery pelo cap. Inclui os itens de hardening do `dev2.todo` ainda pendentes.

## Fluxo de Uso
Infra/modelo — sem fluxo de UI. Habilita scoping por usuário e criação de personagem com cap de servidor.

## Referências
- Specs: [05](../specs/05-character-lifecycle.md) (R9 ownership, R10 auth, schema gaps), [01](../specs/01-level-and-progression.md) (R-cap, caches R1/R2).
- Design System: — (sem UI).
- Código: `app/models/character.rb`, `app/models/user.rb`, `app/services/characters/*`, `db/schema.rb`, `dev2.todo`.

## Escopo de Implementação
- **Migrations**: add `characters.user_id` (FK, not null, index); add `characters.server_level_cap` (integer, not null); unique indexes em `character_masteries (character_id, mastery_id)` e `character_skills (character_id, skill_group_id)` (race conditions, dev2.todo #2).
- **Models**: `Character belongs_to :user`; `User has_many :characters, dependent: :destroy`; validar `server_level_cap` ∈ {90,100,110,120,130}; validar `current_/target_mastery_level ≤ character.server_level_cap` (substitui bound `MAX_LEVEL` em `CharacterMastery`).
- **Caches**: `current_level`/`target_level` recomputados de `MAX(mastery levels)` (callback/serviço); deixar de ser input editável.
- **Hardening (dev2.todo restante)**: verificar/aplicar `inverse_of` (já presente em Character — confirmar nos demais), `ApplicationRecord.transaction` (já aplicado em alguns — varrer), remover cascade redundante em Delete/Update services.
- **Validações/erros**: mensagens via I18n.
- **Persistência**: SQLite; `db/schema.rb` + migrations commitados juntos.

## Critérios de Aceitação
- [ ] `characters.user_id` e `server_level_cap` existem, com FK/índices.
- [ ] Índices únicos em character_masteries e character_skills.
- [ ] `User has_many :characters`; ações de character escopáveis por usuário.
- [ ] Mastery level validado contra `server_level_cap`.
- [ ] `current_level`/`target_level` recomputados (cache), não aceitos como input.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; rubocop/brakeman limpos.
- [ ] README de specs inalterado ou atualizado se regra mudar.

## Estratégia de Testes (TDD)
- Unit: validações de `server_level_cap`, mastery ≤ cap, unicidade (índices), recomputo de caches ao alterar mastery.
- Integração: criar character com user + cap; tentar criar mastery acima do cap (falha); duplicar mastery (falha por índice).
- Regressão: suite existente de services continua verde.

## Boas Práticas
SOLID, migrations reversíveis, validação no model (não duplicar em service — dev2.todo #4), I18n, baixo acoplamento.

## Modelo LLM Recomendado
Opus — mudança estrutural transversal, correctness-critical.

## Estratégia de Commit
`feat: add user ownership and server_level_cap to characters` · `test: character ownership + cap validations` · `refactor: bound mastery level by server cap` · `feat: recompute class-level caches from masteries` · `chore: unique indexes + dev2 hardening`.
