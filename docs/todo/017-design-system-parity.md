# 017 — Design system parity (+ design-sync)

## Execution order
Depends on: 007, 009, 010
Run before: — (second to last, before the final audit).

## Objective
Ensure all created composite components (PlannerCard, ReadOnlySkillWindow, MasterySection, StatsSummary, SkillEditor, SeriesInfoPanel, SkillInfoPanel, CreateCharacter, CharsDrawer, toast) are: (a) in the living docs at `/docs/design_system`, (b) without style duplication/fork, (c) synced to the published DS via `/design-sync`.

## Usage flow
A dev/designer opens `/docs/design_system` and sees every component rendered live; the published DS (`89e0df02`) reflects the code.

## References
- Published DS: `89e0df02` (SROLabDS, 19 components) — contracts `*.prompt.md`/`.d.ts`/`.html`.
- Local Design System: `app/views/docs/design_system.html.erb`, `app/views/shared/*`, `app/assets/tailwind/application.css`.
- Skill/tool: `/design-sync` (`DesignSync`).

## Implementation scope
- **Frontend**: add each new partial to `docs/design_system.html.erb` (live render + snippet via DocsController); audit tokens/classes vs the DS (no hardcoded colors outside tokens); remove duplicated components.
- **Sync**: run `/design-sync` to republish the DS from the code; record commit notes.
- **States**: each component with its variants/states in the docs.

## Acceptance criteria
- [ ] All new components appear in `/docs/design_system` (live render).
- [ ] No colors/sizes hardcoded outside tokens; no duplicated partial.
- [ ] `/design-sync` run; published DS updated.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration: `/docs/design_system` renders each new partial without error; smoke that the classes used exist in `@layer components`.

## Best practices
DS as the single source, tokens-first, no fork, living docs (do not diverge from the app), DRY.

## Recommended LLM model
Sonnet — audit/docs + running design-sync.

## Commit strategy
`feat: add composite components to living design system` · `refactor: dedupe + tokenize styles` · `chore: design-sync republish`.
