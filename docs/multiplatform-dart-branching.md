# Multiplatform Dart — branch & worktree isolation

**Updated:** 2026-08-06 (D-LANES: Spec Kit = system/non-UI; UI/UX = area-ux)  
**Purpose:** Keep Spec Kit + Dart system work **separate** from product Spec Kit `0NN` **and** from Flutter **UI/UX** redesign work.

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

## RC-BRANCH / production merge (after PRODUCTION_CUTOVER GO)

**Marker:** `PRODUCTION_CUTOVER_GO` / **RC-BRANCH**  
**Canonical verdict:** [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md)  
**Offline re-gate:** `dart run tool/production_cutover_regate.dart`

| Condition | Merge `feature/multiplatform-dart` → production / `main` |
| --------- | -------------------------------------------------------- |
| `PRODUCTION_CUTOVER: NO-GO` | **Forbidden** |
| `PRODUCTION_CUTOVER: GO` (DART-061, 2026-07-25) | **Allowed** as a human/release step (not automatic) |

Rules for this policy:

1. **RC-BRANCH:** Merge of `feature/multiplatform-dart` toward production/`main` is allowed **only after** `PRODUCTION_CUTOVER: GO`.
2. DART Spec Kit **finish-spec** still merges each slice onto **`feature/multiplatform-dart` only** (never auto-merge to `main` in agent finish).
3. After GO, a release engineer may merge the multiplatform integration tip toward `main` / production branch and schedule Next domain-route retirement.
4. Re-run `dart run tool/production_cutover_regate.dart` (and secret/fidelity/dual-run gates as needed) before the production merge.
5. Soft never auto-applies; no `CLIENT_SECRET` / `SESSION_SECRET` in Flutter/Jaspr clients.

## Rules

1. **Never** implement multiplatform Dart/Jaspr/Flutter port work on product feature branches (`043-*`, equip/composer slices, etc.).
2. **Never** merge multiplatform slices into product feature branches. Land slices onto **`feature/multiplatform-dart` only**.
3. **Do not** merge `feature/multiplatform-dart` → `main` until **`PRODUCTION_CUTOVER: GO`** (see **RC-BRANCH** section above; GO set by DART-061). Before GO this merge was forbidden; after GO it is policy-allowed as a human/release step.
4. Use **full Spec Kit lifecycle** for every **system** slice on this line:
   - `/speckit-specify` → (optional `/speckit-clarify`) → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` → finish-spec
5. **Spec Kit scope (D-LANES):** only **non-UI / system** work (pure packages, models/resolvers, IO, auth, sync). Do **not** open DART Spec Kit for mockup-driven chrome, Widgetbook-only, or dual-truth Capture — use [`docs/ux-redesign/`](./ux-redesign/README.md) (`area-ux-redesign` / `area-ux-component` / `area-implement`).
6. When finishing a slice, **base branch = `feature/multiplatform-dart`** (not `main`, not `feature/overhall`). Override finish-spec base if `git-config.yml` still says `main`.
7. **Parallel numbering:** this workstream uses **`DART-001`…** only — never product `044+`. Branches and specs: `dart-NNN-short-name` / `specs/dart-NNN-short-name/`.
8. Architecture freezes: [`multiplatform-dart-port-decisions.md`](./multiplatform-dart-port-decisions.md) (includes **D-LANES**).
9. **Slice backlog (canonical):** [`multiplatform-dart-slice-roadmap.md`](./multiplatform-dart-slice-roadmap.md) — system DART rows; update status after every finish-spec.
10. Exploration Grok workflow (read-only): `.grok/workflows/explore-flutter-port.rhai` — maintain on this line; optional, not a product runtime dependency.
11. **Auto Spec Kit loop:** `.grok/workflows/dart-speckit-loop.rhai` — advances **system** DART slices in order. Operator notes: [`multiplatform-dart-speckit-loop.md`](./multiplatform-dart-speckit-loop.md). Do not point the loop at pure UI polish.
12. **Gaps analysis:** `.grok/workflows/dart-gaps-analysis.rhai` — Next vs Dart parity scan; updates [`multiplatform-dart-feature-gaps.md`](./multiplatform-dart-feature-gaps.md) so system P0–P1 residuals have DART-NNN and presentation residuals can map to UX tracks.

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
