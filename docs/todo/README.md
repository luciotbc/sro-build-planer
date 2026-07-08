# Backlog — docs/todo

> AI-agent-consumable backlog (cognitive-model style). Each `NNN-*.md` is one independently-shippable task. Small tasks use one PR; large tasks are split into stacked review PRs under `feature/NNN-slug/NN-slice`. Read [docs/specs](../specs/README.md) for the business rules a task references. Mockups govern visual/interaction; **specs govern business rules**.

## Definition of Done (every task)
Tests green (`PARALLEL_WORKERS=1 bin/rails test`) · rubocop/format clean · browser-validated (Chrome) · mockup + DS conformance · no console errors · code review applies [the-rails-way](../code-review/the-rails-way.md) · PRs respect [pr-sizing-and-stacking](../code-review/pr-sizing-and-stacking.md) (≤400 LOC / ≤15 files / 1 responsibility; split into stacked sub-PRs if exceeded; integration PRs require `integration-pr` + justification) · PR with evidence · **docs/specs/README + this README kept in sync if docs change**.

## Stacked-PR note
A task is delivered as ordered small PRs `feature/NNN-slug/NN-slice` (refactor → schema → service → UI → cleanup), each within the size limits. Default to stacked PRs retargeted into `main` as each slice merges. Use a feature integration branch `feature/NNN-slug` only when the whole feature must be tested together before `main`; the final integration PR must carry the `integration-pr` label, include `Reviewability: justified`, and link all reviewed child PRs. Tasks **001** and **010** are large → must be stacked.

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
| 018 | [landing-page](018-landing-page.md) | 004 | Sonnet |
| 019 | [single-step-undo](019-single-step-undo.md) | 012 | Haiku |
| 020 | [edit-character-modal](020-edit-character-modal.md) | 005,007 | Sonnet |
| 021 | [share-character-link](021-share-character-link.md) | 020 | Sonnet |
| 022 | [account-settings-page](022-account-settings-page.md) | — | Sonnet |
| 023 | [update-email-section](023-update-email-section.md) | 022 | Sonnet |
| 024 | [update-password-section](024-update-password-section.md) | 022 | Sonnet |
| 025 | [password-recovery-reuse](025-password-recovery-reuse.md) | 024 | Haiku |
| 026 | [registration-rules-reuse](026-registration-rules-reuse.md) | 024 | Haiku |
| 027 | [email-opt-in-toggle](027-email-opt-in-toggle.md) | 022 | Haiku |
| 028 | [my-data-summary](028-my-data-summary.md) | 022 | Haiku |
| 029 | [export-my-data](029-export-my-data.md) | 028 | Opus |
| 030 | [delete-account](030-delete-account.md) | 022 | Sonnet |
| 031 | [transactional-email](031-transactional-email.md) | — | Sonnet |
| 032 | [user-settings-menu-topbar](032-user-settings-menu-topbar.md) | 006,022 | Sonnet |

## Dependency DAG / parallel lanes
- Foundation (serial): 000 → 001 → 002 → 003.
- After 001: **004** (then **005 ∥ 006** ∥ **018**).
- After 003+004: **007** → **008**, **009** (∥).
- After 002+007+008: **010** → **011** → **012**; **013 ∥ 014** (after 010).
- Final polish (∥): **015 ∥ 016 ∥ 017** (after 007+010; 017 also needs 009).
- **018** (landing page) ships independently after 004, can run in parallel with 005-006 or as final polish after 017.
- **020** (edit-character modal) independent after 005+007; can run any time.
- **021** (share-character link) after 020; public read-only page + share token.
- **Account settings** (mockup `account_settings.html`; topbar untouched): **022** (page shell + spec 09) → then **023 ∥ 024 ∥ 027 ∥ 028 ∥ 030** (one section per task); **025 ∥ 026** after 024 (password-fields/rules reuse); **029** after 028 (export button lives in the My data card).
- **031** (transactional-email) — standalone infra/config; no dependency; enables reliable delivery for the mailers above (Mailpit in dev, encrypted-credentials SMTP elsewhere).
- **032** (user-settings menu in the topbar; mockup `character_show.html`) after **006 + 022** — replaces the standalone "Log out" button with a dropdown (Account settings + Log out); reconciles spec 09 R2.

Each lane = a separate branch/session. One PR per task, approve, then next.
