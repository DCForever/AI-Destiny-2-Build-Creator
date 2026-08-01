# Research: 043-default-variant-composer

## 1. Composer shell vs VariantEditPanel rewrite

- **Decision**: Introduce `DefaultVariantComposer` as the canonical edit shell for all variants (default and non-default). `VariantEditPanel` becomes a thin re-export/wrapper or is replaced at `BuildPage` call sites. Tab model matches spec (not legacy general/sets/artifact/mods/abilities/aspects/fragments).
- **Rationale**: Spec FR-001/018 require a new IA; patching seven old tabs in place fights the board.
- **Alternatives considered**: Incremental restyle of existing tabs only — rejected (wrong information architecture). Keep CreateBuildPanel + Finish walkthrough — rejected by clarify (New build → composer; Finish always visible).

## 2. New build without CreateBuildPanel

- **Decision**: **Draft mode** in the composer until the first successful **create build** API call. General collects name, class, subclass, synergies, exotic, super, artifact. Create runs when the user saves General with domain-valid payload (synergies required). Until a `buildId` exists, Subclass kit persistence and set attach APIs are unavailable even if class is set—UI still applies FR-022 locks; attach/create controls stay disabled with “save General to continue” when class is set but build not yet persisted.
- **Rationale**: Domain rejects `NO_SYNERGY` on save; attach endpoints need real IDs. Client-only draft avoids illegal empty server builds.
- **Alternatives considered**: Server “draft build” with zero synergies — rejected (domain/API churn). Auto-create on New build with dummy synergies — rejected (pollutes library, violates intent).

## 3. Tab gating (FR-022)

- **Decision**: Pure helper `composerTabAccess({ className, subclassName, buildId, tab })` returns `{ allowed, reason }`. Rules: General + Finish always allowed; Subclass/Armor/Weapon require class; Subclass additionally requires subclass; Armor/Weapon attach/create require `buildId` (persisted).
- **Rationale**: Spec clarify Q5; testable without React.
- **Alternatives considered**: Soft empty states only — rejected by clarify B-style hard block for open.

## 4. Finish completeness vs equip-ready

- **Decision**: Reuse `evaluateFinishGapsFromVariant` / `finishGaps` for **completeness** (enable equip/export affordances only when `gapsResult.complete` for default). Reuse `computeEquipReady` for pin readiness. Finish tab always mounted; buttons disabled with `finishMissingReasons(gaps)` + pin status copy.
- **Rationale**: Spec SC-008; avoid duplicating gap logic already in Finish walkthrough.
- **Alternatives considered**: Hide Finish until complete — rejected by clarify Q1.

## 5. Armor Reuse + optional Improve

- **Decision**: Reuse `SetAttachPicker` (type-filtered) for Reuse lists; after live attach, show **Improve kit** entry that mounts `FinishArmorOptimizeWorkspace` (or equivalent) in suggest-then-confirm mode. Skip does nothing.
- **Rationale**: Clarify Q3; 031 optimizer already exists on finish path.
- **Alternatives considered**: Optimize only under Create — weaker than clarify B. Forced improve step — rejected.

## 6. Armor Create name + concept tags (FR-010)

- **Decision**: On `create-set-attach` (and materialize-from-optimize confirm), server (or shared helper used by route) sets `name` via existing default naming patterns + disambiguator when omitted; sets `conceptTags` from build designated synergy designations (map type/subType → known concept tag ids where possible; skip unknowns). Document mapping in contract.
- **Rationale**: Spec US5; tags are filter metadata not identity.
- **Alternatives considered**: Client-only tags after create — racey; pure free-text tags without vocabulary — weaker library filter.

## 7. Weapon synergy-first catalog (FR-015)

- **Decision**: Client helper ranks catalog search hits: weapons linked as evidence on designated/bridged synergies first, then others; visual chip/indicator on matches. Fetch strategy: existing catalog/manifest search + synergy evidence context already used by suggestions (`mergeSynergyContext` / suggest paths) where available; degrade to unordered if context missing.
- **Rationale**: Spec FR-015; soft enhancement.
- **Alternatives considered**: Server-only sort on manifest search — broader API change; filter-only matching weapons — rejected (must keep others reachable).

## 8. Subclass tab grouping

- **Decision**: Collate existing abilities/aspects/fragments pickers from VariantEditPanel into one Subclass tab with visual groups (class/melee/grenade/movement | aspects/fragments). Preserve capacity and exotic-ability checks.
- **Rationale**: Board + FR-006; logic already exists.
- **Alternatives considered**: Keep three tabs — rejected by board.

## 9. Non-default variants

- **Decision**: Same `DefaultVariantComposer` for all variants; no reduced tab strip. Lighter edits = user simply skips tabs; no forced armor create.
- **Rationale**: Clarify Q4.
- **Alternatives considered**: Weapon-only subset chrome — rejected.

## 10. Deprecations

- **Decision**: Remove `creating` → `CreateBuildPanel` primary path from `BuildPage`. Keep `FinishBuildWalkthrough` code temporarily for gap/optimize helpers until FinishTab/Armor paths absorb call sites; then delete or debug-only.
- **Rationale**: Spec FR-020/017.
- **Alternatives considered**: Dual paths forever — rejected (UX split).

## 11. HTML mock

- **Decision**: Optional `docs/ui-mocks/default-variant-composer.html` for tab chrome review during implement; Excalidraw remains canonical structure.
- **Rationale**: Project UI plan rule; board already exists.
