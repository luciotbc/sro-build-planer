# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
bin/rails import:skills                         # import from doc/import/SRO_Skills_Complete.csv (CSV)
bin/rails import:skills[/path/to/other.csv]    # import from a specific CSV
bin/rails import:skills_xml                    # import from doc/import/skill_ch.xml + skill_eu.xml (XML, preferred)

# Documentation
bin/rails docs:erd          # regenerate doc/diagrams/db-erd.svg after schema changes
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
        └── LevelDatum (XP/SP table per character level, used for SP budget calculations)
```

The character build planning layer sits on top:

```
Character [race, current_level, target_level]
  ├── CharacterMastery → Mastery
  └── CharacterSkill → SkillGroup [current_skill_level, target_skill_level]
```

`CharacterSkill.current_skill_level` / `target_skill_level` record where the player is now and where they want to reach — these are the core "build plan" state. `LevelDatum.sp_cumulative` gives total SP available at any level.

All static records carry an `external_id` (from the game's data) used as the stable upsert key. Skills also carry `external_skill_code` as a secondary unique key.

### Data Import Pipeline

Two importers, both idempotent (skip existing records):

- **CSV** — `lib/sro/skills_importer.rb` (`SRO::SkillsImporter`): reads `doc/import/SRO_Skills_Complete.csv`. Run via `bin/rails import:skills`.
- **XML** — `lib/sro/xml_skills_importer.rb` (`SRO::XmlSkillsImporter`): reads `doc/import/skill_ch.xml` and `skill_eu.xml` (raw game exports). Imports in dependency order: Masteries → SkillSeries → SkillGroups → Skills → SkillGroupRequirements → LevelData. Run via `bin/rails import:skills_xml`.

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
7. **English-only** — all user-facing text (warnings, errors, messages) in English.
8. **Pre-commit gate** — `stree write` + `bin/rubocop` run automatically; fix violations before the commit lands.
9. **Open the PR** with a summary, a per-area change list, and the test command used.
