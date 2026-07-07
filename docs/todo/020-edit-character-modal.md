# 020 — edit-character-modal

> **How agents use this:** implement the "Edit character" modal (name + server level cap only — no race) triggered by a hover pencil on the character identity bar. Backend already exists (`Characters::UpdateService`, `CharactersController#update`); this task is mostly frontend + error-path fix. Specs govern business rules (spec 05); mockup/DS govern visuals.

## Execution order
After 005 (create-character-modal) and 007 (planner-show-readonly) — both merged. No open dependencies; ready to start.

## Objective
Let the player rename a character and change its server level cap from the planner view, via a modal identical to the "New character" modal minus the race selector.

## Usage flow
1. On `characters#show`, the user hovers the character name **or** avatar in the char bar → a pencil (edit) icon appears next to the name.
2. Clicking the pencil opens the "Edit character" modal (same `dialog` Stimulus controller / `.modal` DS component as create).
3. Modal contains: name input (prefilled with current name), server-level-cap picker (current cap pre-selected), submit button labeled **"Save"**. **No race selector** (race switch is destructive — spec 05 R5 — and out of scope here).
4. Submit PATCHes `character_path(@character)` → `CharactersController#update` → `Characters::UpdateService`.
5. Success: redirect to `characters#show` with notice; char bar shows new name/cap.
6. Failure (e.g. cap lowered below an existing mastery level — spec 05 R4): error surfaced to the user on the show screen; no silent clamp.

## References
- **Mockup:** "Novo personagem" modal (same layout, minus race cards; title "Edit character", button "Save").
- **Design system:** `.modal` / `overlay-head` / `overlay-body`, `.cap-btn`, `.char-bar` (`/docs/design_system`).
- **Partials:** `app/views/shared/_create_character.html.erb` (source layout), `app/views/shared/_char_bar.html.erb` (trigger site), `app/views/characters/show.html.erb`.
- **Spec:** [05-character-lifecycle](../specs/05-character-lifecycle.md) R3 (cap editable), R4 (lowering below existing mastery level rejected with error), R5 (race switch destructive — excluded from this modal).
- **Service:** `app/services/characters/update_service.rb` (already enforces R4); `CharactersController#update`.

## Implementation scope
### Frontend
- New partial `app/views/shared/_edit_character.html.erb`: modal cloned from `_create_character`, race section removed, `form_with model:`-style PATCH to `character_path(character)`, fields prefilled. Title key `.title` = "Edit character", submit `.submit` = "Save".
- `_char_bar` gains an optional `editable`/`character` local: when present, render a pencil `icon-btn` next to the name, hidden by default, revealed on hover of the `.char-bar-id` block (name + avatar), via CSS `group-hover` or a `:hover` rule in `@layer components`. Pencil `data-action="dialog#open"` — the modal + trigger share one `data-controller="dialog"` scope (wrap or restructure as needed; keep other `char_bar` call sites unaffected).
- Wire into `app/views/characters/show.html.erb` only (edit screen keeps the plain bar).
- I18n: new `shared.edit_character.*` keys in **all 6 locales**; game jargon (Level Cap) stays English (spec 08 R14).

### Backend
- Fix `CharactersController#update` failure path: it currently `render :edit` — but `:edit` is the skill-editor screen, wrong for modal failures. Change to `redirect_to @character, alert: result.errors.join(", "), status: :see_other` (mirrors `#create`'s failure handling).
- No service changes expected (`UpdateService` already handles name/cap and the R4 guard). Ensure `character_params` permits only what the modal sends.

### Persistence
None — no schema changes.

### States
- **Success:** redirect to show + notice toast, updated char bar.
- **Error:** redirect to show + alert (R4 cap violation, blank name).
- **Empty/loading:** n/a (modal is server-rendered; native `dialog`).

## Acceptance criteria
- [ ] Hovering name or avatar on `characters#show` reveals a pencil icon beside the name; not shown otherwise; absent on other `char_bar` call sites.
- [ ] Pencil opens modal titled "Edit character" with name prefilled and current cap pre-selected; **no race selector**.
- [ ] Submit button reads "Save".
- [ ] Saving a new name and/or cap updates the character and the char bar reflects it after redirect.
- [ ] Lowering the cap below an existing mastery current/target level shows the R4 error and persists nothing (per spec 05 R4).
- [ ] Failure path no longer renders the skill-editor `:edit` template.
- [ ] All 6 locales have the new keys; `bin/i18n-check` passes; jargon untranslated.
- [ ] No console errors; DS conformance (modal, cap-btn, icon-btn).

## Testing strategy (TDD — tests first)
1. **Integration (`ActionDispatch::IntegrationTest`)**: PATCH update success (name, cap) → redirect + persisted; PATCH cap below mastery level → redirect to show with alert, value unchanged; follow redirects before HTML assertions.
2. **View/partial test or integration on show**: pencil trigger + modal markup present on `characters#show`; race selector absent inside edit modal; prefilled values.
3. Run `PARALLEL_WORKERS=1 bin/rails test` — green before done.

## Best practices
- Reuse DS classes; do not fork new CSS unless the hover-reveal needs one small `@layer components` rule.
- Keep controller thin; logic stays in `UpdateService` (Rails Way checklist applies at review).
- ERB: no `<%= %>` inside `<%# %>`; conditional attrs via `<% if %>`.
- Run `bin/rails tailwindcss:build` after CSS/template edits (sandbox watch quirk).

## Recommended LLM model
**Sonnet** — UI-clone task with existing backend; low ambiguity, moderate surface.

## Commit strategy
One branch `feat/020-edit-character-modal`, one PR (well under size caps). Commits:
1. `test: edit character modal + update failure path`
2. `fix: redirect on character update failure instead of rendering skill editor`
3. `feat: edit character modal with hover pencil trigger`
4. `feat: i18n keys for edit character modal (6 locales)`
