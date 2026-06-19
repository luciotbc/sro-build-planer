# Backlog — docs/todo

> AI-agent-consumable backlog (cognitive-model style). Each `NNN-*.md` is one independently-shippable task (1 branch `feature/NNN-slug`, 1 PR). Read [docs/specs](../specs/README.md) for the business rules a task references. Mockups govern visual/interaction; **specs govern business rules**.

## Definition of Done (every task)
Tests green (`PARALLEL_WORKERS=1 bin/rails test`) · rubocop/format clean · browser-validated (Chrome) · mockup + DS conformance · no console errors · code review applies [the-rails-way](../code-review/the-rails-way.md) · PRs respect [pr-sizing-and-stacking](../code-review/pr-sizing-and-stacking.md) (≤400 LOC / ≤15 files / 1 responsibility; split into stacked sub-PRs if exceeded) · PR with evidence · **docs/specs/README + this README kept in sync if docs change**.

## Stacked-PR note
A task = a feature integration branch `feature/NNN-slug`; deliver as ordered small sub-PRs `feature/NNN-slug/NN-fatia` (refactor → schema → service → UI → cleanup), each within the size limits. Tasks **001** and **010** are large → must be stacked.

## Task index

| # | Task | Depends on | LLM model |
|---|---|---|---|
| 000 | [business-rules-spec](000-business-rules-spec.md) ✅ | — | Opus |
| 001 | [schema-and-ownership-foundation](001-schema-and-ownership-foundation.md) | 000 | Opus |
| 002 | [resolver-side-parameterization](002-resolver-side-parameterization.md) | 001 | Opus |
| 003 | [build-summary-service](003-build-summary-service.md) | 001,002 | Opus |
| 004 | [characters-controller-crud](004-characters-controller-crud.md) | 001 | Sonnet |
| 005 | [create-character-modal](005-create-character-modal.md) | 004 | Sonnet |
| 006 | [chars-drawer-and-topbar](006-chars-drawer-and-topbar.md) | 004 | Sonnet |
| 007 | [planner-show-readonly](007-planner-show-readonly.md) | 003,004 | Opus |
| 008 | [mastery-section-tabs](008-mastery-section-tabs.md) | 007 | Sonnet |
| 009 | [stats-summary](009-stats-summary.md) | 003,007 | Sonnet |
| 010 | [skill-editor-screen](010-skill-editor-screen.md) | 002,007,008 | Opus |
| 011 | [mastery-level-control](011-mastery-level-control.md) | 010 | Opus |
| 012 | [bulk-skill-actions](012-bulk-skill-actions.md) | 010,011 | Opus |
| 013 | [prerequisite-feedback](013-prerequisite-feedback.md) | 010 | Sonnet |
| 014 | [skill-info-panel](014-skill-info-panel.md) | 010 | Sonnet |
| 015 | [empty-loading-error-states](015-empty-loading-error-states.md) | 007,010 | Sonnet |
| 016 | [responsive-mobile](016-responsive-mobile.md) | 007,010 | Sonnet |
| 017 | [design-system-parity](017-design-system-parity.md) | 007,009,010 | Sonnet |

## Dependency DAG / parallel lanes
- Foundation (serial): 000 → 001 → 002 → 003.
- After 001: **004** (then **005 ∥ 006**).
- After 003+004: **007** → **008**, **009** (∥).
- After 002+007+008: **010** → **011** → **012**; **013 ∥ 014** (after 010).
- Final polish (∥): **015 ∥ 016 ∥ 017** (after 007+010; 017 also needs 009).

Each lane = a separate branch/session. One PR per task, approve, then next.
