# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.1 application for planning character builds in **Silkroad Online (SRO)**, an MMORPG. It models the game's skill system — races, masteries, skill groups, and individual skills — so players can plan their character's skill allocations.

## Commands

```bash
# Setup
bundle install
git config core.hooksPath .githooks   # enable pre-commit hooks
bin/rails db:setup                    # creates DB, loads schema, runs seeds

# Development (runs Rails server + Tailwind CSS watcher)
bin/dev

# Tests — MUST use PARALLEL_WORKERS=1 (Minitest::Spec describe blocks create anonymous
# classes that crash DRb/Marshal when parallelized)
PARALLEL_WORKERS=1 bin/rails test                                  # all tests
PARALLEL_WORKERS=1 bin/rails test test/models/skill_test.rb        # single file
PARALLEL_WORKERS=1 bin/rails test test/models/skill_test.rb:42     # single test by line

# Linting & formatting
bin/rubocop                 # RuboCop (inherits syntax_tree + rubocop-rails-omakase)
bin/brakeman                # security static analysis
bin/bundler-audit           # gem vulnerability audit

# CI (runs all checks)
bin/ci

# Data import
bin/rails import:skills                         # import from docs/import/SRO_Skills_Complete.csv (CSV)
bin/rails import:skills[/path/to/other.csv]    # import from a specific CSV
bin/rails import:skills_xml                    # import from docs/import/skill_ch.xml + skill_eu.xml (XML, preferred)

# Documentation
bin/rails docs:erd          # regenerate docs/diagrams/db-erd.svg after schema changes
```

## Architecture

### Domain Model

The static game-data hierarchy:

```
Race (Chinese / European)
  └── Mastery (e.g. "Sword", "Cold Force") [mastery_type: Weapon/Force/Physical/Magical/Support]
        ├── SkillSeries (a row of related skill groups within the mastery UI grid)
        │     └── SkillGroup (one skill "slot"; holds all level variants) [col_position, max_skill_level]
        │           ├── Skill (one level of the skill: skill_level, sp_cost, mp_cost, mastery_level_req)
        │           └── SkillGroupRequirement → required_group (prerequisite unlock edges)
        └── LevelDatum (per-level XP/SP table; sp_cumulative = SP cost to raise one mastery to a given level — see docs/specs/02)
```

The character build planning layer sits on top:

```
Character [race, current_level, target_level]
  ├── CharacterMastery → Mastery
  └── CharacterSkill → SkillGroup [current_skill_level, target_skill_level]
```

`CharacterSkill.current_skill_level` / `target_skill_level` record where the player is now and where they want to reach — these are the core "build plan" state. `LevelDatum.sp_cumulative` is the SP cost to raise one mastery to a given level (a cost input, not a budget — see docs/specs/02).

All static records carry an `external_id` (from the game's data) used as the stable upsert key. Skills also carry `external_skill_code` as a secondary unique key.

### Data Import Pipeline

Two importers, both idempotent (skip existing records):

- **CSV** — `lib/sro/skills_importer.rb` (`SRO::SkillsImporter`): reads `docs/import/SRO_Skills_Complete.csv`. Run via `bin/rails import:skills`.
- **XML** — `lib/sro/xml_skills_importer.rb` (`SRO::XmlSkillsImporter`): reads `docs/import/skill_ch.xml` and `skill_eu.xml` (raw game exports). Imports in dependency order: Masteries → SkillSeries → SkillGroups → Skills → SkillGroupRequirements → LevelData. Run via `bin/rails import:skills_xml`.

The XML importer is more complete — it populates `SkillSeries`, `SkillGroupRequirement`, and `LevelDatum` which the CSV importer does not.

### Frontend Stack

- **Hotwire** (Turbo + Stimulus) for interactivity — no separate JS build step
- **Tailwind CSS** — compiled via `bin/rails tailwindcss:watch` (included in `bin/dev`)
- **importmap-rails** for JS module loading (no Node/webpack)
- Assets served via **Propshaft**
- **Design system** — living reference rendered by the app at `/docs/design_system` (`DocsController#design_system`, view `app/views/docs/design_system.html.erb`). Development-only route. Every component is a real `app/views/shared` partial styled by `@layer components` classes in `app/assets/tailwind/application.css`; interactive ones use the `dialog`, `stepper` and `tabs` Stimulus controllers. Docs render the live partials so they cannot drift from production.

### Infrastructure

- **SQLite** for all stores: main DB, job queue (Solid Queue), cache (Solid Cache), WebSocket (Solid Cable)
- **Solid Queue** for background jobs (configured in `config/queue.yml`)
- Deployment via **Kamal** (`config/deploy.yml`)

### Service Layer

Business logic lives in `app/services/` under domain namespaces: `Characters::CreateService`, `CharacterSkills::AddService`, etc. Every service exposes a single `self.call(params)` entry point and returns a `ServiceResult`:

```ruby
result = Characters::CreateService.call(params)
result.success?   # => true / false
result.data       # payload on success
result.errors     # array of strings on failure
result.warnings   # non-fatal notices (present on both success and failure)
```

### Test Stack

Tests use **Minitest** with **Minitest::Spec DSL** (`describe`/`it` blocks) and **FactoryBot** for fixtures. All factories live in `test/factories/`. Use `build`, `create`, `build_list`, etc. directly in tests (FactoryBot methods are mixed into `ActiveSupport::TestCase`).

### Code Style

RuboCop is configured to inherit `syntax_tree` formatting rules plus `rubocop-rails-omakase`. The formatter is `syntax_tree` (not standard RuboCop auto-correct). Run `bin/rubocop -A` to auto-fix.

The pre-commit hook (`.githooks/pre-commit`) automatically runs `stree write` on staged `.rb`/`.rake` files and then `bin/rubocop` — commits will fail if rubocop finds violations. Make sure hooks are installed: `git config core.hooksPath .githooks`.

## Development Workflow

The flow used in this repo (e.g. the `feat/register-user` registration feature):

1. **Feature branch off `main`** — one branch per feature (`feat/...`, `fix/...`), PR back to `main`.
2. **TDD, test-first** — tests are written and committed *before* the implementation. A task is only "done" once `PARALLEL_WORKERS=1 bin/rails test` is green; never declare done before that.
3. **Conventional Commits, one concern per commit** — `feat:`, `fix:`, `refactor:`, `test:`. Small, focused commits that tell a story.
4. **Feature-then-harden ordering** — land the happy path first, then close gaps in follow-up commits (e.g. single-use tokens, rate-limiting, abuse/enumeration guards). Security hardening is incremental and visible in the commit log.
5. **Business logic in services** — anything beyond trivial CRUD goes in an `app/services/` domain service returning a `ServiceResult`; controllers stay thin.
6. **Migrations + `db/schema.rb` committed together.**
7. **English-only** — all user-facing text (warnings, errors, messages) in English (`en` is the source locale; see docs/specs/08). **Game jargon is never translated in any locale** — Mastery, Skill, SP, Build, Level Cap, etc. stay in English; the canonical do-not-translate list is docs/specs/game-jargon.md (spec 08 R14).
8. **Pre-commit gate** — `stree write` + `bin/rubocop` run automatically; fix violations before the commit lands.
9. **Open the PR** with a summary, a per-area change list, and the test command used.

## Golden Rules (AI agents — mandatory)

Hard constraints for any AI agent in this repo. They override convenience.

- **GR1 — Cite the rule you used.** Whenever a decision is driven by a Golden Rule or a `docs/specs` rule, you MUST state which rule (e.g. "per GR3", "per spec 03 R7"). No silent rule-based decisions.
- **GR2 — `/docs` is the source of truth.** Everything under `docs/` (specs, backlog, glossary, ADRs) is authoritative. `docs/specs/` governs **business rules**; mockups and the design system govern **visual/interaction only**. On any conflict between mockup/code and a spec, the spec wins — surface the conflict, never silently follow the code. **All `docs/` content is written in English** (specs, backlog, code-review, ADRs) — translate any non-English doc before committing.
- **GR3 — Keep specs in sync with code.** Whenever you edit anything under `/app` or `/db`, you MUST check whether any `docs/specs/*` rule became stale and update it (plus the spec README index) in the same change. A code change that contradicts a spec is not done until the spec is reconciled.
- **GR4 — Review long planning sessions before concluding.** Any long planning/spec session ends with a short retrospective: review what was produced, capture what worked and what to improve, and persist durable learnings (memory + `docs/`) so the process improves session over session.
- **GR5 — `.dev/` is off-limits to agents.** Never access, read, edit, grep, glob, or otherwise open any file under the top-level `.dev/` directory. It holds the developer's personal notes and scratch — versioned for the human, but **invisible to AI agents** because reading it can contaminate an agent's interpretation of the project. Exclude `.dev/` from every search and traversal. (This is intentionally kept *outside* `docs/` so GR2 stays absolute: everything under `docs/` is authoritative, with no exceptions.)

## AI-Driven Development Workflow (specs → backlog → incremental execution)

For any substantial feature or multi-step effort, follow this flow (it produced `docs/specs/` + `docs/todo/`).

### Documentation
1. **Specs are the source of truth for business rules** (see GR2); mockups/design system govern only visual/interaction.
2. **Write specs as a cognitive model** (AI-digestible): one concern per file, a top "How agents use this" note, explicit Given/When/Then rules, a glossary of canonical terms, cross-links, tables over prose. Live in `docs/specs/`.
3. **Index files stay in sync.** `docs/specs/README.md` and `docs/todo/README.md` are navigation maps; update them in the same change whenever a doc is added/changed/removed (see GR3).
4. **Every task references** the spec rule(s), the design-system component, and the Rails partial — by path.

### Planning / backlog
5. **Large work → a backlog** of `docs/todo/NNN-slug.md` files, each with the mandatory structure: Execution order, Objective, Usage flow, References (Mockup/DS/Spec), Implementation scope (FE/BE/persistence/validations/empty·loading·success·error states), Acceptance criteria, Testing strategy (**TDD**), Best practices, Recommended LLM model + rationale, Commit strategy.
6. **Order by dependency DAG**, mark parallel lanes; **one branch + one PR per task**, with approval between PRs.
7. **Interview before locking the backlog.** Run a `grill-with-docs`-style interview: one question at a time, **verify the code before asking**, recommend an answer, capture resolved rules into `docs/specs/` inline.
8. **Refine in batch + score + recheck JIT.** Three passes over all task files (clarity / consistency-DAG / technical quality), then a reviewer-agent scores each against the 9 rejection criteria (clear objective, complete scope, sufficient acceptance, correct deps, requires TDD, references DS, faithful to spec, incremental size, incrementally deliverable) and rewrites until all pass; re-read mockup + code just-in-time before implementing each task.

### Execution / quality
9. **Definition of Done per task**: tests green (`PARALLEL_WORKERS=1 bin/rails test`), lint/format clean, **browser-validated** (Chrome), mockup + design-system conformance, no console errors, PR with evidence (screenshots + test output), explicit approval to merge.
10. **Global stop**: all tasks merged + a final audit (target ≥95% mockup parity, 0 critical bugs, DS conformance); divergences become new `docs/todo/` tasks; loop until none relevant.
11. **Keep the design system honest**: when you add a new composite partial, re-run `/design-sync` so the published DS does not diverge from the code.

### Code review
12. **Every code review applies The Rails Way checklist.** Any agent or skill performing a code review (manual, `/code-review`, PR-review subagents) MUST apply [docs/code-review/the-rails-way.md](docs/code-review/the-rails-way.md) **in addition** to its normal correctness/security pass, flagging each violation with the relevant section. It is a hard gate alongside the per-task Definition of Done.
13. **Keep PRs small and reviewable (stacked PRs).** Before opening any review PR, self-check against [docs/code-review/pr-sizing-and-stacking.md](docs/code-review/pr-sizing-and-stacking.md): one responsibility (one-sentence summary, refactor separate from behavior), ≤400 LOC (cap 600), ≤15 files (cap 20), Reviewability Score `LOC + files×20 + responsibilities×100` ≤ 800. If exceeded, split using a pattern from [docs/code-review/incremental-delivery-patterns.md](docs/code-review/incremental-delivery-patterns.md) (stacked PRs to `main`, vertical slice, expand/contract, branch-by-abstraction, feature flag, integration branch) **before** requesting review. Prefer stacked PRs retargeted to `main` as each slice merges. Use a feature integration branch only when the whole feature must be tested together before `main`; the final integration PR must have the `integration-pr` label, `Reviewability: justified`, and links to all reviewed child PRs. Run `bin/pr-size <base>` to check; CI enforces it via the `reviewability` job and bypasses only labeled integration PRs. PR body states the one-sentence summary, stack position, and `git diff --shortstat` size (use the PR template).

### Operational
14. **Reading the SRO Labs mockups** (Cloudflare-gated `claude.ai/design`): use the **Claude-in-Chrome** MCP (real logged-in profile passes Cloudflare), not chrome-devtools (gets stuck in the turnstile). The rendered mockup is a cross-origin iframe → read via screenshots.
15. **Signed commits** require the 1Password app open; its signing socket is blocked by the command sandbox — run the commit with the sandbox disabled when signing fails with "Could not connect to socket".
