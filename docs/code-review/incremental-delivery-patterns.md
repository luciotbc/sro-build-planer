# Incremental delivery patterns

**Purpose:** catalog of strategies (beyond stacked PRs) for keeping changes small, reviewable, and safely integrable.
**How agents use this:** when a task is too big for one small PR, pick the pattern(s) that fit and state the choice in the task file / PR body. Companion to [pr-sizing-and-stacking.md](pr-sizing-and-stacking.md) (the hard limits) and [the-rails-way.md](the-rails-way.md) (review rubric). Context: solo dev + AI generation → low conflict risk, review is the bottleneck.

## Delivery patterns

| Pattern | Idea | Use when | Fit (solo+AI) |
|---|---|---|---|
| **Stacked PRs** | Chain of small dependent PRs | Feature decomposes into layers | Default |
| **Feature flags / toggles** | Merge inert incomplete code to main behind a flag | Long feature you want integrated early | Strong combo |
| **Branch by abstraction** | Introduce an abstraction layer, swap implementation underneath, remove the old | Large refactor without breaking trunk | For refactors (e.g. resolver by side) |
| **Expand / Contract (parallel change)** | 3 steps: add new → migrate reads/writes → remove old | Schema/API change without breakage | For task 001 (add columns/assoc) |
| **Vertical slice / tracer bullet** | Thin end-to-end slice (one real use case) instead of a horizontal layer | Deliver value early, validate architecture | Alt to layer-stacking |
| **Keystone** | Build the feature, wire the UI entry point **last** | Feature ready behind the scenes | Yes |
| **Preparatory refactoring** (Fowler) | "Make the change easy, then make the easy change" — refactor first, separately | Always, before a feature in tight code | Yes (already policy) |
| **Strangler fig** | Replace legacy incrementally, route over gradually | Subsystem rewrite | Partial |
| **Spike & stabilize** | Throwaway prototype to learn, then rewrite clean | High design uncertainty | Yes (`prototype` skill) |

## Review patterns (orthogonal to the above)
- **Commit-by-commit review** — larger PR but reviewable commit by commit; requires atomic, clean commits.
- **Draft PR, incremental** — open early as draft, review in pieces as it grows.
- **CI size gate** — automated check failing/warning when a PR exceeds the limits (see `bin/pr-size` + the `reviewability` CI job).
- **PR template** — forces "one-sentence summary + stack position + shortstat" in the body (`.github/PULL_REQUEST_TEMPLATE.md`).

## Recommended combination for this project
1. **Stacked PRs** as the base structure.
2. **Vertical slice** when a task delivers one end-to-end use case (e.g. create character) instead of horizontal layers.
3. **Expand/Contract** on **001** (add `user_id`/`server_level_cap` + caches without breaking existing data).
4. **Branch by abstraction** on **002** (resolver parameterized by side without breaking the current side).
5. **Feature flag** if a feature grows past ~3 sub-PRs and you want to integrate to main early.
6. **Preparatory refactoring** as a habit — refactors always in their own PR (already in the policy).
7. **CI size gate + PR template** to automate the sizing rule.

## How to choose (quick heuristic)
- One responsibility, fits the size caps → single small PR.
- Multiple layers, each small → **stacked PRs**.
- One end-to-end behavior touching several layers thinly → **vertical slice**.
- Risky data/contract change → **expand/contract**.
- Big in-place refactor → **branch by abstraction** + preparatory refactoring.
- Can't hide in a branch / want early integration → **feature flag**.
