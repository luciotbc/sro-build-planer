# 006 — Chars drawer + auth-aware topbar

## Execution order
Depends on: 004
Run before: 007. Parallel with: 005.

## Objective
Character listing/switching (CharsDrawer) triggered by the "Characters N" pill in the topbar, and an auth-aware topbar (Log in vs Characters pill + Log out).

## Usage flow
Logged-in user sees "Characters N" in the topbar → clicks → drawer lists characters (name, race, cap) → selects one → goes to its planner; or creates a new one (opens modal 005). Logged-out sees "Log in".

## References
- Mockup: `index.html` (topbar "Log in"), `skills_editor.html` (topbar "Characters 3" + "Log out").
- Design System: CharsDrawer, CharsIcon, TopBar, `_drawer`, `_chars_pill`, `_topbar`.
- Specs: [05](../specs/05-character-lifecycle.md) (R9/R10).
- Code: `app/views/shared/_topbar.html.erb`, `_drawer.html.erb`, `_chars_pill.html.erb`, `app/javascript/controllers/dialog_controller.js`.

## Implementation scope
- **Frontend**: authenticated variant of `_topbar` (pill + Log out) vs logged-out (Log in); `shared/_chars_drawer` (list + selectable item + "New character" action); `_chars_icon` if needed.
- **Backend**: drawer reads `Current.user.characters`; selection navigates to `character_path`.
- **States**: empty (no characters → create CTA; rich in 015); loading; active highlighted.

## Acceptance criteria
- [ ] Topbar shows the correct state by auth.
- [ ] Pill shows the real count; drawer lists the user's characters.
- [ ] Selecting navigates to the planner; "New character" opens modal 005.
- [ ] Faithful to mockup + DS (CharsDrawer/TopBar).
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; console clean.

## Testing strategy (TDD)
- Integration/system: authenticated vs logged-out topbar; drawer lists only the user's; selection navigates; count in the pill.

## Best practices
Reuse `_drawer`/`_topbar`/`_chars_pill`, DS, a11y, I18n, DRY.

## Recommended LLM model
Sonnet — view + Stimulus drawer over existing components.

## Commit strategy
`feat: auth-aware topbar variants` · `feat: chars drawer partial` · `test: chars drawer + topbar states` · `feat: wire character selection navigation`.
