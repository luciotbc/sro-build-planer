# 003 — Build summary service

## Ordem de Execução
Depende de: 001, 002
Executar antes de: 007, 009.

## Objetivo
`Builds::SummaryService` que calcula os três números do StatsSummary (SKILL POINTS, MASTERY TOTAL, REQUIRED LEVEL) para um personagem, current e planned, conforme [spec 02](../specs/02-sp-and-summary.md).

## Fluxo de Uso
Dado um `Character`, retorna `ServiceResult` com estrutura `{ skill_points: {current,planned,delta}, mastery_total: {…}, required_level: {…} }` pronta para a view.

## Referências
- Specs: [02](../specs/02-sp-and-summary.md) (R1–R5, atenção R1a), [01](../specs/01-level-and-progression.md).
- Design System: StatsSummary, Stat (consumidores em 009).
- Código: `app/models/level_datum.rb`, `skill.rb`, `character_mastery.rb`, `character_skill.rb`, `app/services/service_result.rb`.

## Escopo de Implementação
- **Backend**: serviço `self.call(character)`; mastery SP = `Σ_m sp_cumulative(level)` **por mastery** (JOIN, nunca `IN` — R1a); skill SP = `Σ_s Σ_{1..level} sp_cost`; mastery total = `Σ` níveis; required level = `MAX` níveis (current→target).
- **Performance**: evitar N+1 (preload masteries/skills/level_data; somatórios em memória ou SQL agregado correto).
- **Validações/erros**: personagem sem masteries/skills → zeros; níveis ausentes em `level_data` → tratar como 0 com warning.
- **Estados**: retorno determinístico; sem dependência de UI.

## Critérios de Aceitação
- [ ] Fórmulas batem com spec 02 (incluindo soma por-mastery, não IN).
- [ ] current/planned/delta corretos; delta pode ser negativo.
- [ ] Personagem vazio → todos zeros.
- [ ] Sem N+1 (verificável em teste com `assert_queries`/contagem).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde.

## Estratégia de Testes (TDD)
- Unit: cenário com 2 masteries no mesmo nível (prova R1a — não deduplica); skill cumulativo 1..N; delta negativo; vazio→zeros.
- Integração: fixture realista → números esperados.

## Boas Práticas
SRP, ServiceResult, cálculo puro/testável, sem efeitos colaterais, performance consciente.

## Modelo LLM Recomendado
Opus — lógica numérica com armadilha de deduplicação (R1a), TDD pesado.

## Estratégia de Commit
`feat: Builds::SummaryService skeleton + result shape` · `test: skill points / mastery total / required level` · `feat: implement per-mastery SP sum (avoid IN dedup)` · `perf: preload to avoid N+1`.
