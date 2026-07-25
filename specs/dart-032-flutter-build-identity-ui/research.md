# Research: DART-032 Flutter Build Identity UI

**Date**: 2026-07-24

## Decisions

### R1 — Mirror DART-030/031 dual-pane + local-library user

**Decision**: Reuse Sets/Synergies library patterns: `kFlapLibraryRailWidth`, ChangeNotifier controller, `kLocalLibraryMembershipId` / `resolveLibraryUserId` shape, memory-DB widget tests.

**Rationale**: Same library UX contract; DART-029 already defines `kFlapColumnsBuilds`.

### R2 — Use existing `createUserBuild` hard gates

**Decision**: UI does not re-implement hard evaluators. Empty synergy list is prevented in UI and still enforced by `assertBuildIdentityHardGates` → `NO_SYNERGY`. Surface `UseCaseException.message` in status banner.

**Rationale**: DART-028 already owns pipeline parity; this slice is shell only.

### R3 — Synergy types as multi-chip draft

**Decision**: Create form holds a draft `List<SynergyTypeDesignation>`; user picks type (+ optional subtype) and taps “Add type”; create sends full list. Detail may replace the full list on identity save.

**Rationale**: Builds can designate multiple synergy types (product 015 / DART-028); single dropdown is insufficient.

### R4 — Exotic/super pins as text fields

**Decision**: Optional integer hash + display name for exotic armor/weapon; free-text pinned Super. No catalog picker this slice.

**Rationale**: Exit criteria focus on create with synergy types + identity display; catalog pick is polish / later compose work.

### R5 — In-place identity update only (no confirm/fork)

**Decision**: `updateUserBuild` applies identity changes in-place. Confirm/fork dialog deferred (product 015 US3 / future UI).

**Rationale**: Scope is list + identity create; fork flow is multi-variant concern (after DART-033).

### R6 — Nav order

**Decision**: Catalog → Sets → Synergies → **Builds** → Settings.

**Rationale**: Library surfaces grouped before Settings; Builds after Synergies because identity references synergy *types* (not library synergy rows yet).
