# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.1 application for planning character builds in **Silkroad Online (SRO)**, an MMORPG. It models the game's skill system — races, masteries, skill groups, and individual skills — so players can plan their character's skill allocations.

## Commands

```bash
# Setup
bundle install
bin/rails db:setup          # creates DB, loads schema, runs seeds

# Development (runs Rails server + Tailwind CSS watcher)
bin/dev

# Tests
bin/rails test                                  # all tests
bin/rails test test/models/skill_test.rb        # single file
bin/rails test test/models/skill_test.rb:42     # single test by line

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

### Infrastructure

- **SQLite** for all stores: main DB, job queue (Solid Queue), cache (Solid Cache), WebSocket (Solid Cable)
- **Solid Queue** for background jobs (configured in `config/queue.yml`)
- Deployment via **Kamal** (`config/deploy.yml`)

### Code Style

RuboCop is configured to inherit `syntax_tree` formatting rules plus `rubocop-rails-omakase`. The formatter is `syntax_tree` (not standard RuboCop auto-correct). Run `bin/rubocop -A` to auto-fix.

The pre-commit hook (`.githooks/pre-commit`) automatically runs `stree write` on staged `.rb`/`.rake` files and then `bin/rubocop` — commits will fail if rubocop finds violations. Make sure hooks are installed: `git config core.hooksPath .githooks`.

**stree rejects non-ASCII characters.** Never use box-drawing characters (─, U+2500) or any non-ASCII in Ruby files — they break `stree write` in a US-ASCII locale. Use plain ASCII separators (`# -----`) instead.

## Rails Way Patterns

Established conventions from the PR #4 audit. Apply these consistently.

### Models & Associations

- **`dependent: :destroy` is the correct cascade.** Never manually `delete_all` before `destroy!` — it bypasses AR callbacks and is redundant when the association declares `dependent: :destroy`.
- **Uniqueness requires both a DB index and a model validation.** `validates :uniqueness` alone has a TOCTOU race window. Always add a unique index in a migration alongside the validation.
- **Declare `inverse_of` on both sides** of every association to enable AR in-memory caching and avoid redundant queries.
- **Don't duplicate model validations in services.** Use `model.assign_attributes(params)` + `model.valid?` and return `model.errors.full_messages`. The service stays correct if model rules change.

### Service Objects

- **Use `ApplicationRecord.transaction`**, not `ActiveRecord::Base.transaction`.
- **Rescue `RecordInvalid` specifically.** Always have `rescue ActiveRecord::RecordInvalid => e` returning `e.record.errors.full_messages`. A broad `rescue => e` with `[e.message]` gives a single concatenated blob instead of structured errors.
- **Extract shared algorithms into modules.** Copy-pasted logic across services should become a module (`include`d in both). Example: `CharacterSkills::PrerequisiteResolver`.
- **Fix N+1s in filter loops.** `find_by` inside `filter_map` over a relation is O(n) queries. Pre-load with `.where(ids).index_by(&:skill_group_id)` and do hash lookups.
- **Wrap every multi-step write in a transaction.** Any service that updates more than one record must use `ApplicationRecord.transaction`.

### I18n

- **All user-facing strings go through I18n.** `@warnings <<` calls, error messages, everything — use `I18n.t("warnings.key", interpolations)`. Keys live under `en.warnings.*` in `config/locales/en.yml`. Never hardcode English strings in service objects.

### Testing

- **Minitest::Spec DSL** is enabled via `require "minitest/spec"` + `extend Minitest::Spec::DSL` in `ActiveSupport::TestCase`. Use `it`, `before`, `let` throughout.
- **FactoryBot over fixtures.** All tests use FactoryBot factories (`test/factories/`). No fixture accessors (`races(:chinese)` etc.). Set up data in `before` blocks with instance variables; use `let` for simple lazy objects.
- **`let` is lazy** — blocks run only when first referenced. Reference a `let` name explicitly before calling something that queries it.
- **One commit per logical issue** when applying a batch of fixes for review.

### Ruby Idioms

- **`field.in?(%i[current both])`** over `field == :current || field == :both` for set-membership checks.
