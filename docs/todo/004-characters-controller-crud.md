# 004 — Characters controller (CRUD, scoped)

## Ordem de Execução
Depende de: 001
Executar antes de: 005, 006, 007.

## Objetivo
Rotas + `CharactersController` ligando os serviços `Characters::*` à UI, escopado ao usuário logado, com feedback via flash/Turbo. Sem telas ricas ainda (index/show mínimos; modal vem em 005).

## Fluxo de Uso
Usuário logado: lista seus personagens, cria, atualiza (nome/raça/cap), deleta. Não-logado: redirecionado ao login (auth-required).

## Referências
- Specs: [05](../specs/05-character-lifecycle.md) (R3 cap edit+bloqueio, R5 race wipe, R7 delete, R9/R10 scoping/auth).
- Design System: TopBar (auth-aware) — preparado, detalhado em 006.
- Código: `config/routes.rb`, `app/controllers/concerns/authentication.rb`, `app/services/characters/{create,update,delete}_service.rb`.

## Escopo de Implementação
- **Rotas**: `resources :characters`.
- **Controller**: `require_authentication`; `Current.user.characters` scoping; ações chamam serviços e mapeiam `ServiceResult` → flash + status (Turbo Stream onde fizer sentido).
- **Validações/erros**: erros de serviço → flash.alert / render; race change destrutivo confirmado no client (UI em 006/005).
- **Estados**: index vazio (placeholder; rico em 015); sucesso/erro com flash.

## Critérios de Aceitação
- [ ] CRUD completo escopado ao usuário (não acessa personagem de outro user → 404).
- [ ] `ServiceResult.fail` vira flash/erro sem 500.
- [ ] Auth-required em todas as ações.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; rubocop limpo.

## Estratégia de Testes (TDD)
- Controller/integração: index só do próprio user; create válido/ inválido; update cap baixando abaixo de mastery → erro; delete; acesso cross-user → 404; não-logado → redirect login.

## Boas Práticas
Controller fino, lógica no service, scoping seguro, I18n, Conventional Commits.

## Modelo LLM Recomendado
Sonnet — CRUD Rails convencional sobre serviços prontos.

## Estratégia de Commit
`feat: characters routes + controller scaffolding` · `test: characters CRUD scoped to user` · `feat: map ServiceResult to flash/turbo` · `feat: enforce auth + ownership scoping`.
