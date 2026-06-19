# 004 — Characters controller (CRUD, scoped)

## Execution order
Depends on: 001
Run before: 005, 006, 007.

## Objective
Routes + `CharactersController` wiring the `Characters::*` services to the UI, scoped to the logged-in user, with feedback via flash/Turbo. No rich screens yet (minimal index/show; modal comes in 005).

## Usage flow
Logged-in user: lists their characters, creates, updates (name/race/cap), deletes. Logged-out: redirected to login (auth-required).

## References
- Specs: [05](../specs/05-character-lifecycle.md) (R3 cap edit + blocking, R5 race wipe, R7 delete, R9/R10 scoping/auth).
- Design System: TopBar (auth-aware) — prepared, detailed in 006.
- Code: `config/routes.rb`, `app/controllers/concerns/authentication.rb`, `app/services/characters/{create,update,delete}_service.rb`.

## Implementation scope
- **Routes**: `resources :characters`.
- **Controller**: `require_authentication`; scope via `Current.user.characters`; actions call services and map `ServiceResult` → flash + status (Turbo Stream where it fits).
- **Validations/errors**: service errors → flash.alert / render; destructive race change confirmed client-side (UI in 006/005).
- **States**: empty index (placeholder; rich in 015); success/error via flash.

## Acceptance criteria
- [ ] Full CRUD scoped to the user (cannot access another user's character → 404).
- [ ] `ServiceResult.fail` becomes flash/error without a 500.
- [ ] Auth-required on all actions.
- [ ] `PARALLEL_WORKERS=1 bin/rails test` green; rubocop clean.

## Testing strategy (TDD)
- Controller/integration: index only of the current user; valid/invalid create; update cap below an existing mastery → error; delete; cross-user access → 404; logged-out → login redirect.

## Best practices
Thin controller, logic in the service, safe scoping, I18n, Conventional Commits.

## Recommended LLM model
Sonnet — conventional Rails CRUD over ready-made services.

## Commit strategy
`feat: characters routes + controller scaffolding` · `test: characters CRUD scoped to user` · `feat: map ServiceResult to flash/turbo` · `feat: enforce auth + ownership scoping`.
