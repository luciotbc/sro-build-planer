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
bin/rails import:skills                         # import from doc/import/SRO_Skills_Complete.csv
bin/rails import:skills[/path/to/other.csv]    # import from a specific CSV
```

## Architecture

### Domain Model

The skill hierarchy maps directly to the SRO game data:

```
Race (Chinese / European)
  └── Mastery (e.g. "Sword", "Cold Force") [mastery_type: Weapon/Force/Physical/Magical/Support]
        └── SkillGroup (a thematic cluster of related skills)
              └── Skill (a single skill at a specific level)
```

All domain records carry an `external_id` (from the game's data) used as the stable upsert key. Skills also carry `external_skill_code` as a secondary unique key.

### Data Import Pipeline

`lib/sro/skills_importer.rb` (`SRO::SkillsImporter`) reads a game-exported CSV (`doc/import/SRO_Skills_Complete.csv`) and populates the DB in dependency order: Races → Masteries → SkillGroups → Skills. The importer is idempotent: it compares incoming rows against existing records using `COMPARISON_FIELDS` and skips matches, logs conflicts, and creates new records. Triggered via `bin/rails import:skills`.

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
