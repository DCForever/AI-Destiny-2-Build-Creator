# Multiplatform Dart — branch & worktree isolation

**Updated:** 2026-07-24  
**Purpose:** Keep Spec Kit + Dart/Jaspr/Flutter port work **completely separate** from product UI features (e.g. `043-default-variant-composer`).

## Topology

```
main
 └── feature/multiplatform-dart          ← long-lived integration base for this line
       ├── dart-001-…                    ← DART-001 Spec Kit feature branches
       ├── dart-002-…
       └── …

Product line (separate):
  043-default-variant-composer, etc.     ← product Spec Kit 001…; do not mix
```

| Role | Git ref | Worktree path |
| ---- | ------- | ------------- |
| Product / default | product `0NN-…` (e.g. `043-…`) | `F:\Destiny2BuildCreator` |
| Dart port **integration** | `feature/multiplatform-dart` | `F:\Destiny2BuildCreator-multiplatform-dart` |
| Active Dart **slice** | `dart-NNN-short-name` (**DART-NNN** program ID) | Prefer a dedicated worktree per slice, or checkout inside the multiplatform worktree only |

## Rules

1. **Never** implement multiplatform Dart/Jaspr/Flutter port work on product feature branches (`043-*`, equip/composer slices, etc.).
2. **Never** merge multiplatform slices into product feature branches. Land slices onto **`feature/multiplatform-dart` only**.
3. **Do not** merge `feature/multiplatform-dart` → `main` until an explicit cutover decision (see open questions in decisions doc).
4. Use **full Spec Kit lifecycle** for every slice on this line:
   - `/speckit-specify` → (optional `/speckit-clarify`) → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` → finish-spec
5. When finishing a slice, **base branch = `feature/multiplatform-dart`** (not `main`, not `feature/overhall`). Override finish-spec base if `git-config.yml` still says `main`.
6. **Parallel numbering:** this workstream uses **`DART-001`…** only — never product `044+`. Branches and specs: `dart-NNN-short-name` / `specs/dart-NNN-short-name/`.
7. Architecture freezes: [`multiplatform-dart-port-decisions.md`](./multiplatform-dart-port-decisions.md).
8. **Slice backlog (canonical):** [`multiplatform-dart-slice-roadmap.md`](./multiplatform-dart-slice-roadmap.md) — **DART-001–DART-049**; update status after every finish-spec.
9. Exploration Grok workflow (read-only): `.grok/workflows/explore-flutter-port.rhai` — maintain on this line; optional, not a product runtime dependency.
10. **Auto Spec Kit loop:** `.grok/workflows/dart-speckit-loop.rhai` — advances DART slices in order (specify→plan→tasks→implement→finish). Operator notes: [`multiplatform-dart-speckit-loop.md`](./multiplatform-dart-speckit-loop.md).
11. **Gaps analysis:** `.grok/workflows/dart-gaps-analysis.rhai` — Next vs Dart parity scan; updates [`multiplatform-dart-feature-gaps.md`](./multiplatform-dart-feature-gaps.md) so every P0–P1 gap has a planned DART-NNN.

## Creating a new Spec Kit slice (agents)

From the multiplatform worktree, with `feature/multiplatform-dart` up to date:

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
git checkout feature/multiplatform-dart
git pull --ff-only   # if remote exists
```

Then create the next **DART-NNN** branch from the integration tip (**do not** let Spec Kit auto-pick product `044+`):

```powershell
# Example: DART-001
$env:GIT_BRANCH_NAME = "dart-001-domain-foundation"
git checkout feature/multiplatform-dart
# create branch from base if needed:
git checkout -B dart-001-domain-foundation feature/multiplatform-dart
# Spec dir must match:
# specs/dart-001-domain-foundation/
```

Always set `GIT_BRANCH_NAME=dart-NNN-short-name` before `create-new-feature-branch` / specify so product sequential numbering is not used.

**Finish-spec:** merge into `feature/multiplatform-dart`, not `main`.

## Slice backlog

Do **not** invent ad-hoc mega-features. Use the master table in  
[`multiplatform-dart-slice-roadmap.md`](./multiplatform-dart-slice-roadmap.md)  
(**DART-001–DART-049** across phases P0–P5). One Spec Kit feature per **DART-NNN** row.

## Worktree hygiene

```powershell
# List
git -C F:\Destiny2BuildCreator worktree list

# Add a second worktree for an active slice (optional)
git -C F:\Destiny2BuildCreator worktree add F:\Destiny2BuildCreator-044-dart-domain 044-dart-domain-foundation

# Remove when done (branch kept)
git -C F:\Destiny2BuildCreator worktree remove F:\Destiny2BuildCreator-044-dart-domain
```

## Product worktree

`F:\Destiny2BuildCreator` remains for Next.js product features. Do not leave multiplatform-only files uncommitted there; commit them on the multiplatform line instead.
