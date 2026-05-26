# SRO Skills XML Importer

Orginal files extrated from https://www.m3stat.com/SPCalc/

  - [skill_ch.xml](https://www.m3stat.com/data/skill_ch.xml)
  - [skill_eu.xml](https://www.m3stat.com/data/skill_eu.xml)

Documents the XML format used by `doc/import/skill_ch_small.xml` and how each field maps to the database.

## Running the Importer

```bash
bin/rails import:skills_xml                        # uses doc/import/skill_ch_small.xml
```

The importer is idempotent — existing records are skipped, nothing is overwritten.

---

## XML Structure Overview

```
<skillchinese>
  <tab>                    → Mastery
    <series>               → SkillSeries
      <skillgroup>         → SkillGroup
        <skill>            → Skill (+ SkillGroupRequirement from prv* attrs)
        ...
      </skillgroup>
    </series>
  </tab>

  <LevelData>
    <data />               → LevelDatum
  </LevelData>
</skillchinese>
```

The root element `<skillchinese>` implicitly identifies the **Chinese** race (`races.external_id = 1`).

---

## Element Reference

### `<tab>` → `masteries`

Represents a mastery (weapon style or discipline).

| XML attribute | DB column         | Notes                          |
|---------------|-------------------|--------------------------------|
| `id`          | `external_id`     | Unique key used for upsert     |
| `name`        | `name`            | e.g. `"Bicheon"`               |
| `stype`       | `mastery_type`    | e.g. `"Weapon"`, `"Force"`     |
| `pict`        | —                 | Not stored                     |
| `pictfocus`   | —                 | Not stored                     |
| `race`        | —                 | Always `0` (Chinese); race resolved from root element |
| `type`        | —                 | Not stored                     |
| `pos`         | —                 | Not stored                     |

`race_id` is set to the Chinese `Race` record (`external_id = 1`).

---

### `<series>` → `skill_series`

A thematic group of skill groups within a mastery (e.g. "Smashing Sword Series").

| XML attribute | DB column       | Notes                          |
|---------------|-----------------|--------------------------------|
| `row`         | `row_position`  | 0-based display row            |
| `title`       | `title`         | Series display name            |
| `pict`        | `icon_path`     | `.ddj` extension normalized to `.png` |
| `desc`        | —               | Not stored                     |
| `descskill`   | —               | Not stored                     |
| `study`       | —               | Not stored                     |

`mastery_id` is resolved from the parent `<tab>`.

---

### `<skillgroup>` → `skill_groups`

A single learnable skill with multiple upgrade levels.

| XML attribute | DB column             | Notes                                      |
|---------------|-----------------------|--------------------------------------------|
| `id`          | `external_id`         | Unique key used for upsert                 |
| `id`          | `external_group_code` | Stored as string (`id.to_s`)               |
| `name`        | `name`                | Skill display name                         |
| `desc`        | `description`         | Short description shown in tooltips        |
| `pict`        | `icon_path`           | `.ddj` extension normalized to `.png`      |
| `col`         | `col_position`        | 0-based column within the series grid      |
| *(skill count)* | `max_skill_level`   | Number of `<skill>` children               |

`mastery_id` and `skill_series_id` are resolved from ancestor elements.

---

### `<skill>` → `skills`

One upgrade level of a skill group.

| XML attribute | DB column            | Notes                                               |
|---------------|----------------------|-----------------------------------------------------|
| `id`          | `external_id`        | Unique key used for upsert                          |
| `id`          | `external_skill_code`| Generated as `"SK_{id}"`                           |
| `stack`       | `skill_level`        | Tier within the group (1 = base, 2 = upgrade, …)  |
| `stack`       | `stack`              | Same value as `skill_level`                        |
| `lv`          | `mastery_level_req`  | Character level required to learn this skill       |
| `sp`          | `sp_cost`            | Skill points consumed on learn                     |
| `mp`          | `mp_cost`            | Mana cost per use                                   |

`skill_group_id` is resolved from the parent `<skillgroup>`.

#### Prerequisite attributes → `skill_group_requirements`

Each `<skill>` carries up to three prerequisite slots. A slot is ignored when `prv` is `0`.

| XML attributes    | DB columns                                                     |
|-------------------|----------------------------------------------------------------|
| `prv1`, `prvrq1`  | `required_group_id` (skillgroup external_id), `required_skill_level` |
| `prv2`, `prvrq2`  | same                                                           |
| `prv3`, `prvrq3`  | same                                                           |

Requirements are read from the **first** `<skill>` in each `<skillgroup>` only (they are uniform across all levels of the same group). A `SkillGroupRequirement` record is created for each non-zero `prv` slot.

---

### `<LevelData><data>` → `level_data`

Per-level progression table (XP and SP thresholds).

| XML attribute | DB column       | Notes                                       |
|---------------|-----------------|---------------------------------------------|
| `lv`          | `level`         | Character level                             |
| `xp`          | `xp_required`   | XP needed to reach this level               |
| `sp`          | `sp_gained`     | SP granted at this level                    |
| *(computed)*  | `sp_cumulative` | Running sum of `sp_gained` up to this level |
| `recid`       | —               | Not stored                                  |
| `job`         | —               | Not stored                                  |
| `fellow`      | —               | Not stored                                  |

---

## Import Order

The importer processes entities in dependency order to satisfy foreign keys:

1. `Race` (Chinese/European, hardcoded)
2. `Mastery` (from `<tab>`)
3. `SkillSeries` (from `<series>`)
4. `SkillGroup` (from `<skillgroup>`)
5. `Skill` (from `<skill>`)
6. `SkillGroupRequirement` (from `prv*` attrs on `<skill>`)
7. `LevelDatum` (from `<LevelData><data>`)
