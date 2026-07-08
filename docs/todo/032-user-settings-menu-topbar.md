# 032 — user-settings-menu-topbar

> **How agents use this:** replace the bare "Log out" button in the authenticated topbar with a **User settings menu** (avatar/trigger → dropdown with **Account settings** + **Log out**). This is the "topbar/menu link is future work" deferred by task 022 and by spec [09](../specs/09-account-settings.md) R2 — landing it means **reconciling spec 09 R2** in the same change (GR3). Visual/interaction is governed by the `character_show.html` mockup in the SRO Labs design project `e76dd313-b147-4234-8ac9-4f3d80c3f9e0` — read it JIT via **Claude-in-Chrome** (workflow rule 14), not WebFetch (Cloudflare-gated). **Do NOT add a language/idioma item** (explicit scope decision — locale switching is out of scope here).

## Execution order
Depends on: 006 (auth-aware topbar), 022 (account-settings page + `settings_path`). Independent of 023–030 (menu links to the page shell; sections can land in any order). No blockers downstream.

## Objective
An authenticated user sees a **user settings trigger** in the topbar (where "Log out" is today). Activating it opens a dropdown menu with exactly two items — **Account settings** (navigates to `/settings`) and **Log out** (ends the session) — matching the `character_show.html` mockup. The logged-out topbar is unchanged (auth modals).

## Usage flow
1. Logged-in user sees the user menu trigger at the right of the topbar (replaces the standalone "Log out" button).
2. Click / Enter / Space opens the dropdown; it lists **Account settings** then **Log out**.
3. "Account settings" → navigates to `settings_path` (`/settings`, task 022).
4. "Log out" → `DELETE session_path`, session destroyed, redirected home (unchanged logout behavior).
5. Esc, click-outside, or selecting an item closes the menu.

## References
- **Mockup:** `character_show.html` (design project `e76dd313-b147-4234-8ac9-4f3d80c3f9e0`) — the topbar user menu. Read via Claude-in-Chrome (rule 14); the rendered mockup is a cross-origin iframe → capture via screenshots.
- **Design system:** **GAP — no dropdown/menu component exists.** Add a `menu` (dropdown) component: `.menu` / `.menu-panel` / `.menu-item` classes in `@layer components` (`app/assets/tailwind/application.css`), a `menu` Stimulus controller (toggle, Esc-close, click-outside-close, `aria-expanded`), and a shared partial `app/views/shared/_user_menu.html.erb`. Document it on `/docs/design_system` and re-run `/design-sync` (workflow rule 11). The existing `dialog` controller is for `<dialog>` overlays (modal/drawer) — an anchored topbar dropdown is a distinct pattern; do not overload `dialog`.
- **Partials:** `app/views/layouts/application.html.erb` (`:topbar_actions` block — the authenticated branch, lines ~27–36, currently renders `_chars_drawer` + the `button_to` "Log out"); `app/views/shared/_topbar.html.erb` (renders the actions slot — layout only, keep unchanged); new `app/views/shared/_user_menu.html.erb`.
- **Spec:** update [`docs/specs/09-account-settings.md`](../specs/09-account-settings.md) **R2 — Navigation** (topbar entry now exists via the user menu; was "future work") and refresh the spec README index if wording changes (GR3). No new business rule beyond navigation — auth/logout semantics are unchanged.
- **I18n:** reuse `shared.log_out`; add `shared.account_settings` (or `shared.user_menu.*`) + an accessible label for the trigger (e.g. `shared.user_menu.label` "User settings") in **all 6 locales** (en, es, ko, pt-BR, tr, zh-CN). Game jargon untouched (spec 08 R14).

## Implementation scope
### Persistence
None.

### Backend
None — reuses `settings_path` (022) and `session_path` DELETE (existing logout). No controller/route changes.

### Frontend
- New `shared/_user_menu.html.erb`: trigger button (avatar/label per mockup) + dropdown panel containing a `link_to settings_path` "Account settings" item and the existing `button_to session_path, method: :delete` "Log out" item styled as a menu item. Logout **must** stay a `button_to` DELETE (CSRF + non-GET) — do not convert it to a plain link.
- New `menu` Stimulus controller: `toggle`, `close`, close on Esc, close on outside click (document listener added on connect / removed on disconnect), toggle `aria-expanded` on the trigger.
- Swap the layout's authenticated branch to render `_user_menu` instead of the inline `button_to`; keep `_chars_drawer` as-is; logged-out branch (`sessions/auth_modals`) unchanged.
- `.menu` / `.menu-panel` / `.menu-item` component classes; run `bin/rails tailwindcss:build` after CSS edits (watcher dies in the sandbox).

### Accessibility
Trigger: `aria-haspopup="menu"`, `aria-expanded` reflecting state, accessible name from I18n. Items keyboard-focusable; Esc returns focus to the trigger. Follows the mockup's visual treatment.

### States
- **Success:** authenticated → menu renders and opens/closes; both items work.
- **Error:** n/a (no server round-trip to open the menu).
- **Empty/Loading:** n/a (server-rendered).
- **Logged-out:** menu absent; auth modals shown (unchanged).

## Acceptance criteria
- [ ] Authenticated topbar shows the user menu trigger; the standalone "Log out" `button_to` is gone from the layout.
- [ ] Menu contains exactly **Account settings** and **Log out** — **no language item**.
- [ ] "Account settings" links to `settings_path`; "Log out" issues `DELETE session_path` and logs the user out (behavior unchanged).
- [ ] Logged-out topbar unchanged; `_topbar.html.erb` (layout partial) unchanged.
- [ ] Menu opens/closes via click, Esc, outside-click; `aria-expanded` toggles; keyboard accessible.
- [ ] `.menu` component + `menu` controller exist, are used, and appear on `/docs/design_system` (`/design-sync` re-run).
- [ ] Spec 09 R2 reconciled (topbar entry now exists); spec README index in sync (GR3).
- [ ] All 6 locales updated; `bin/i18n-check` passes.
- [ ] Faithful to the `character_show.html` mockup + DS.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; browser-validated (Chrome); no console errors.

## Testing strategy (TDD — tests first)
1. **Integration** (`ActionDispatch::IntegrationTest`): authenticated GET of a page using the layout → response contains the menu trigger + a link to `settings_path` + a DELETE form to `session_path`, and does **not** contain the old standalone log-out button markup; assert **no** language/locale item is rendered. Unauthenticated → auth modals, no menu.
2. **Logout still works**: DELETE `session_path` from the menu's form destroys the session (reuse/keep existing session-destroy coverage green).
3. **System/JS** (if the suite runs JS system tests): trigger opens the panel, Esc/outside-click closes it, `aria-expanded` flips. If JS system tests aren't part of `bin/ci`, cover open/close via the Stimulus controller contract and rely on browser validation for interaction.

## Best practices
Reuse `shared.log_out`; keep logout a `button_to` DELETE (never a GET link); DS-first (component class + controller + partial + design-system page); a11y (roles, `aria-expanded`, focus return); I18n across 6 locales; DRY; keep `_topbar` a pure layout slot. Rebuild Tailwind after CSS edits.

## Recommended LLM model
**Sonnet** — one shared partial + one small Stimulus controller + CSS component over an existing auth-aware topbar; no persistence or business logic.

## Commit strategy
Branch `feat/032-user-settings-menu-topbar` (or the assigned working branch). Commits:
1. `test: authenticated topbar renders user menu (account settings + log out)`
2. `feat: menu design-system component (.menu + menu Stimulus controller)`
3. `feat: user-settings menu partial; replace topbar log-out button`
4. `docs: reconcile spec 09 R2 (topbar entry) + i18n keys (6 locales) + design-system page`
