# Game Jargon — do-not-translate glossary

> **How agents use this:** these Silkroad Online terms are game jargon and MUST stay in English in every locale (`en`, `pt-BR`, `es`, `tr`, `ko`, `zh-CN`) — UI copy, flash messages, warnings, errors, docs. When translating or adding locale strings, check this list first; inflect around the English term, never translate it (pt-BR: "level da mastery", not "nível da maestria"; tr: "mastery'sinin"). Enforced by [08-i18n-conventions.md](08-i18n-conventions.md) R14. New jargon discovered during translation goes here in the same change.

## Do not translate

| Term | Notes | Wrong (examples) |
|---|---|---|
| Mastery | Skill tree branch (see [glossary.md](glossary.md)). | maestria, maestría, ustalık, 마스터리, 精通 |
| Skill | Individual ability / skill slot. | habilidade, habilidad, técnica, beceri, 스킬, 技能 |
| Skill Tree | | árvore de skills (use "skill tree") |
| Skill Series | Row of related skill groups. | série → OK as connector ("série de skills"), but "Skill" stays |
| Skill Group | | grupo de habilidades |
| Skill Point / SP | Cost currency. | ponto de habilidade, punto de habilidad |
| Build | A planned character configuration. | construção, configuración |
| Level Cap / Cap | Server max level. | limite de nível, tope |
| Buff | If/when used in copy. | melhoria, mejora |

## Translatable (not jargon)

| Term | Rationale |
|---|---|
| Level | "Level" is preferred in English (pt-BR, tr, ko already use it), but natural inflection/translation is acceptable where English reads awkwardly (es "nivel", zh-CN "等级"). When adjacent to a jargon term, prefer English ("level da mastery"). |
| prerequisite, character, race, series (connector), current/target qualifiers | Ordinary words — translate normally. |
| Race names (Chinese / European) | Translate (zh-CN "中国系", pt-BR "chinesa/europeia"). |

## Sources
- In-game English client terminology (masteries, skills, SP).
- Existing locale files already follow this convention (e.g. pt-BR `mastery_header.decrease: "Diminuir level da mastery"`).
