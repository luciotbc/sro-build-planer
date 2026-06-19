# PR sizing & stacking — reviewability policy

**Purpose:** keep every PR small enough for a single human to review with confidence, even when an AI generates the code quickly.
**How agents use this:** before opening ANY PR, self-check against these limits; if exceeded, split into stacked PRs **before** asking for review. This is a hard gate alongside the per-task Definition of Done ([docs/todo/README.md](../todo/README.md)) and the review checklist ([the-rails-way.md](the-rails-way.md)). Context: solo developer → conflict risk is low, so prefer many small stacked PRs over few large branches.

## Why
AI raised code-generation throughput by orders of magnitude; human review capacity did not. The bottleneck is now review. Optimize for *"how much can a human review with confidence,"* not *"how much code was produced."* (SmartBear: defect-finding drops sharply >400 LOC; reviews >500 LOC go superficial. Google/GitHub: small, single-idea PRs reviewable in one short session.)

## Hard limits (per PR)

| Metric | Target | Hard cap |
|---|---|---|
| **Responsibilities** | **1** (must fit in one sentence) | 1 |
| LOC delta (`insertions + deletions`) | ≤ 400 | 600 |
| Files changed | ≤ 15 | 20 |
| Reviewer time to understand | ≤ 30 min | 30 min |

**Reviewability Score** = `LOC_delta + files×20 + responsibilities×100`.
- ≤ **800** → green (open it).
- **800–1200** → acceptable only with an explicit justification in the PR body.
- > **1200** → must be split before review.

**The one-sentence test (most important):** if you cannot summarize the PR in a single sentence without "and", it has >1 responsibility → split. Separate **pure refactors** from **behavior changes** (Fowler): never mix them in one PR.

## Self-check before opening a PR
```bash
git diff --shortstat <base>...HEAD   # e.g. main...HEAD or the integration branch
git diff --name-only <base>...HEAD | wc -l
```
Compute the score; if any hard cap is exceeded or score > 1200, split.

## Stacked PRs (the default for any non-trivial task)

A backlog task (`docs/todo/NNN-slug.md`) maps to a **feature integration branch**; its work is delivered as an ordered stack of small sub-PRs.

- **Integration branch:** `feature/NNN-slug` (off `main`).
- **Stacked sub-branches:** `feature/NNN-slug/NN-fatia` — each branches off the previous in the stack (or off the integration branch for independent slices) and its PR **targets the previous branch / the integration branch**, not `main`.
- **Layered order** (each layer = its own PR, within the limits above):
  1. **Refactor** — structural change, no behavior change.
  2. **Schema / infra** — migrations, contracts, interfaces.
  3. **Service / implementation** — behavior (test-first, TDD: the slice ships with its tests).
  4. **UI** — views/partials/Stimulus.
  5. **Cleanup** — remove legacy/dead code.
- **Merge order:** sub-PRs merge in stack order into the integration branch; when the task is complete and green, the integration branch merges to `main`. Solo dev → rebase the stack freely; low conflict risk.
- Each sub-PR is independently reviewable, independently revertible, and keeps `git bisect` useful.

## PR body must state
- **One-sentence summary** (the single responsibility).
- **Stack position**: which branch it targets and what precedes/follows it.
- **Size line**: `git diff --shortstat` output + computed Reviewability Score.
- Evidence (tests output, screenshots) per the Definition of Done.

## Applying to the current backlog
- Most `docs/todo/` tasks already scope to ~1 PR. Tasks likely to exceed the caps and therefore **must** be stacked: **001** (schema + ownership + caches + hardening) and **010** (editor screen). Split these along the layer order above; note the split plan in the task file when starting it (JIT).
