# 013 — Prerequisite feedback (toasts)

## Ordem de Execução
Depende de: 010
Executar antes de: —. Paralelo a: 014.

## Objetivo
Surface dos `warnings` dos serviços (pré-req auto-adicionado, mastery escalada, class level ajustado, downgrade) como toasts não-bloqueantes no editor.

## Fluxo de Uso
Ao ajustar um skill que dispara cascata, o usuário vê toasts informando o que mudou automaticamente (ex: "Pierce I adicionado como pré-requisito").

## Referências
- Mockup: `skills_editor.html` (feedback de ações).
- Design System: **Toast — novo componente canônico criado aqui**: partial `app/views/shared/_toast.html.erb` + Stimulus `toast_controller.js`. Reusa tokens (`--color-card`, semânticos `--color-green`/`--color-red`/`--color-blue`) e `_button`/`icon-btn` para dismiss. Não existe ainda no SROLabDS; é registrado na doc viva e republicado via design-sync em 017.
- Specs: [03](../specs/03-prerequisites-and-cascade.md) (warnings em R3/R4/R5).
- Código: `ServiceResult#warnings`, serviços `CharacterSkills::*`, I18n `warnings.*` (já existentes).

## Escopo de Implementação
- **Frontend**: criar `app/views/shared/_toast.html.erb` + `app/javascript/controllers/toast_controller.js` renderizando `result.warnings`; auto-dismiss; stack; variante de erro.
- **Backend**: já retorna warnings; controller/Turbo Stream entrega ao toast.
- **Validações/erros**: erros (fail) também exibíveis como toast de erro (variante).
- **Estados**: múltiplos warnings empilham; dismiss manual e automático.

## Critérios de Aceitação
- [ ] Warnings de cascata aparecem como toasts (I18n).
- [ ] Erros aparecem como toast de erro.
- [ ] Auto-dismiss + dismiss manual; acessível (aria-live).
- [ ] Aderente ao DS (após 017 registrar o componente).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` verde; console limpo.

## Estratégia de Testes (TDD)
- System/integração: ação com pré-req → toast com texto I18n; erro → toast de erro; aria-live presente.

## Boas Práticas
Reuso de warnings existentes, DS, a11y (live region), I18n, DRY.

## Modelo LLM Recomendado
Sonnet — fiação de feedback sobre warnings prontos.

## Estratégia de Commit
`feat: toast component` · `feat: surface service warnings as toasts` · `test: prerequisite feedback toasts`.
