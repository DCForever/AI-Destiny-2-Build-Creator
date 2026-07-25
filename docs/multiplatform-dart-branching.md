# Multiplatform Dart — branch & worktree isolation

**Updated:** 2026-07-24  
**Purpose:** Keep Spec Kit + Dart/Jaspr/Flutter port work **completely separate** from product UI features (e.g. `043-default-variant-composer`).

## Topology

```
main
 └── feature/multiplatform-dart          ← long-lived integration base for this line
       ├── 044-…                         ← Spec Kit feature branches
       ├── 045-…
       └── …

Product line (separate):
  043-default-variant-composer, etc.     ← do not mix commits or worktrees
```

| Role | Git ref | Worktree path |
| ---- | ------- | ------------- |
| Product / default | whatever feature you are on (e.g. `043-…`) | `F:\Destiny2BuildCreator` |
| Dart port **integration** | `feature/multiplatform-dart` | `F:\Destiny2BuildCreator-multiplatform-dart` |
| Active Dart **slice** | `NNN-short-name` (Spec Kit) | Prefer a **dedicated** worktree per active slice, or checkout the feature branch *inside* the multiplatform worktree only |

## Rules

1. **Never** implement multiplatform Dart/Jaspr/Flutter port work on product feature branches (`043-*`, equip/composer slices, etc.).
2. **Never** merge multiplatform slices into product feature branches. Land slices onto **`feature/multiplatform-dart` only**.
3. **Do not** merge `feature/multiplatform-dart` → `main` until an explicit cutover decision (see open questions in decisions doc).
4. Use **full Spec Kit lifecycle** for every slice on this line:
   - `/speckit-specify` → (optional `/speckit-clarify`) → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` → finish-spec
5. When finishing a slice, **base branch = `feature/multiplatform-dart`** (not `main`, not `feature/overhall`). Override finish-spec base if `git-config.yml` still says `main`.
6. Spec directories live under `specs/NNN-short-name/` as usual; keep short names clearly multiplatform-scoped (e.g. `dart-domain-foundation`, `dart-data-manifest`, `flutter-windows-shell`).
7. Architecture freezes: [`multiplatform-dart-port-decisions.md`](./multiplatform-dart-port-decisions.md).
8. Exploration Grok workflow (read-only): `.grok/workflows/explore-flutter-port.rhai` — maintain on this line; optional, not a product runtime dependency.

## Creating a new Spec Kit slice (agents)

From the multiplatform worktree, with `feature/multiplatform-dart` up to date:

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
git checkout feature/multiplatform-dart
git pull --ff-only   # if remote exists
```

Then run Spec Kit **specify** so `before_specify` creates `NNN-…` **from the integration tip**:

- Prefer starting the feature command **while checked out on** `feature/multiplatform-dart` so the new branch’s parent is that tip (if the git extension branches from `HEAD` when base is unset, or from `base_branch`).
- If the extension always uses `base_branch: main` from `.specify/extensions/git/git-config.yml`, create the branch explicitly:

```powershell
# After Spec Kit assigns NNN and short-name:
git branch 044-dart-domain-foundation feature/multiplatform-dart
git checkout 044-dart-domain-foundation
# Write specs under specs/044-dart-domain-foundation/ via Spec Kit as usual
```

Or set for one shot:

```powershell
$env:GIT_BRANCH_NAME = "044-dart-domain-foundation"
# then run create-new-feature-branch / specify — still ensure parent is feature/multiplatform-dart
```

**Finish-spec override:** merge into `feature/multiplatform-dart`, not `main`.

## Suggested first slices (from exploration)

| Order | Short name (example) | Goal |
| ----- | -------------------- | ---- |
| 1 | `dart-domain-foundation` | Melos monorepo skeleton + pure domain parity harness (Phase 0) |
| 2 | `dart-data-manifest` | Drift + storage root + entity stores (Phase 1) |
| 3 | `dart-bungie-auth-sync` | Public+PKCE + inventory sync (Phase 2) |
| 4 | `flutter-windows-compose` | Build/Sets/Synergy spine on Windows Flutter (Phase 3) |
| 5 | `flutter-equip-mobile` | Optimizer/equip + mobile shell (Phase 4) |
| 6 | `jaspr-web-shell` | Jaspr OPFS single-writer + cutover gates (Phase 5) |

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
