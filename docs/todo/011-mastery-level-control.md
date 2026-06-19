# 011 — Mastery level control

## Ordem de Execução
Depende de: 010
Executar antes de: 012.

## Objetivo
Controle de nível da mastery no editor: slider + stepper (− / +) e botão "Max mastery", operando no lado editado, com cascata de skills ao reduzir (clamp dos skills acima do novo nível) conforme regras.

## Fluxo de Uso
No editor, usuário arrasta o slider / usa ± / clica "Max mastery" → nível da mastery (lado editado) muda; subir libera skills; "Max mastery" leva ao `server_level_cap`.

## Referências
- Mockup: `skills_editor.html` (slider + Max mastery).
- Design System: MasterySection, SkillEditor, `_button`.
- Specs: [06](../specs/06-edit-flow-and-bulk-actions.md) (R4 Max mastery), [03](../specs/03-prerequisites-and-cascade.md) (**R7 mastery decrease auto-downgrades skills**), [01](../specs/01-level-and-progression.md) (R-cap), [04](../specs/04-skill-access-and-caps.md).
- Código: `app/javascript/controllers/stepper_controller.js`, `CharacterMasteries::UpdateService` (por-lado após 002).

## Escopo de Implementação
- **Frontend**: slider de mastery + stepper + "Max mastery" (= `server_level_cap`); exibe `MASTERY LV X / server_cap`.
- **Backend**: `CharacterMasteries::UpdateService` no lado editado; ao reduzir mastery abaixo do `mastery_level_req` de skills alocados → **auto-downgrade** de cada skill ao maior nível válido (spec 03 R7), com warning por downgrade; sync de class-level cache.
- **Validações/erros**: nunca acima de `server_level_cap` (erro se tentado); warnings de auto-downgrade (não bloqueia).
- **Estados**: loading; sucesso; erro (tentativa acima do cap); limites min/max no controle.

## Critérios de Aceitação
- [ ] Slider/stepper alteram a mastery no lado editado; cap = `server_level_cap`.
- [ ] "Max mastery" leva ao cap.
- [ ] Reduzir mastery faz auto-downgrade coerente dos skills (spec 03 R7, sem violar caps) + warnings; não bloqueia.
- [ ] Class-level cache atualizado.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- System/integração: Max mastery=cap; reduzir mastery clampa skills; outro lado intacto; sync de level.

## Boas Práticas
Reuso stepper, DS, SRP, a11y (slider com teclado), I18n.

## Modelo LLM Recomendado
Opus — regras de cascata ao reduzir, edge cases.

## Estratégia de Commit
`feat: mastery level slider + stepper` · `feat: max mastery action` · `feat: skill clamp on mastery decrease` · `test: mastery control cascade`.
