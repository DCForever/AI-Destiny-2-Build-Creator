# Feature Specification: DART-009 Static Sandbox Data

**Feature Branch**: `dart-009-static-sandbox-data`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Port static tables (stat benefits, synergy verbs, exotic ability requirements, etc.). Constants package; update process documented for sandbox patches."

**Program ID**: DART-009  
**Phase**: P0  
**Depends**: DART-001 (domain foundation / monorepo)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:** a pure Dart **constants package** (`packages/sandbox_data`, pub name `destiny2_sandbox_data`) that ports product static sandbox tables from `src/data/` and pure lookup/render helpers that do not require IO:

- Stat benefits curves + `computeBenefitsAt` (`src/data/rules/statBenefits.ts`)
- Armor archetypes + lookup (`src/data/rules/armorArchetypes.ts`)
- Champion counters (base frames, overrides, verb counters, damage buffs) (`src/data/rules/championCounters.ts`)
- Activity artifact rules (`src/data/rules/activityRules.ts` — artifact-allowed subset)
- Ability timing fallbacks + pure parse/format (`src/data/rules/abilityTimings.ts`)
- Synergy elements + verbs + resolve/implied-element helpers (`src/data/synergyElements.ts`, `synergyVerbs.ts`)
- Exotic ability requirements table + lookup (`src/data/exoticAbilityRequirements.ts`)
- Known weapon types vocabulary (`src/data/weaponTypes.ts`)
- Concept tags vocabulary (`src/data/conceptTags.ts`)
- Subclasses-by-class lists (`src/data/subclasses.ts` list only; not full `subclasses.meta` source citations)
- Documented **sandbox patch update process** for future Destiny updates

**Out of scope (later slices):**

- Full `subclasses.meta.ts` source-cited verb packs and meta pack renderers (`src/data/meta/*`)
- Armor tier resolution that needs inventory/API (`armorTiers.ts` full pipeline — pure bands may be noted but not required)
- Ability enrichment overrides requiring manifest
- Domain evaluator rewiring to import this package (callers can adopt later)
- Flutter/Jaspr UI, Drift, manifest extractors, Node sidecar

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Constants package with core sandbox tables (Priority: P1)

As a multiplatform domain engineer, I can depend on a pure Dart sandbox/constants package that exposes Armor 3.0 stat benefits, synergy verbs/elements, and exotic ability requirement tables so UI and evaluators share one curated source of truth without Node or IO.

**Why this priority**: Roadmap exit criterion — constants package with the named tables.

**Independent Test**: Package resolves with zero IO/UI runtime deps; unit tests cover `computeBenefitsAt`, verb resolve, and exotic lookup APIs.

**Acceptance Scenarios**:

1. **Given** a bootstrapped workspace, **When** I resolve `packages/sandbox_data`, **Then** runtime dependencies are SDK-only (no Flutter/Jaspr/Drift/http/path_provider).
2. **Given** Melee at 200, **When** `computeBenefitsAt` runs, **Then** lines include `+30% melee ability damage`.
3. **Given** Grenade at 150, **When** `computeBenefitsAt` runs, **Then** lines include `+33% grenade ability damage`.
4. **Given** Super at ≤100, **When** `computeBenefitsAt` runs, **Then** enhanced Super ability damage lines are omitted.
5. **Given** free-text `"Stasis Shards"` / `"Suppress"` / `"Arc Ionic Traces"`, **When** verb resolve runs, **Then** canonical names/elements match TS.
6. **Given** an unknown exotic name, **When** ability requirement lookup runs, **Then** null is returned; `hasAbilityRequirements` is false for empty maps.

---

### User Story 2 - Supporting rule tables (Priority: P1)

As an engineer, I can use champion frame counters, armor archetypes, weapon-type vocabulary, concept tags, subclasses-by-class, activity artifact gates, and ability timing fallbacks from the same package so sandbox guidance stays consistent.

**Why this priority**: Roadmap “etc.” covers the rest of curated `src/data` static tables used by product guidance.

**Independent Test**: Golden unit tests ported from `rules.test.ts`, `weaponTypes`, `conceptTags`, and ability timing cases.

**Acceptance Scenarios**:

1. **Given** Adaptive Frame + Scout Rifle, **When** champion counter resolves, **Then** Barrier.
2. **Given** Wave Frame + Grenade Launcher, **When** champion counter resolves, **Then** Unstoppable (override).
3. **Given** archetype name `"powerhouse"`, **When** find by name runs, **Then** primary Weapons; 12 archetypes with 6 addedIn970.
4. **Given** activity `"Trials of Osiris"`, **When** `isArtifactAllowed` runs, **Then** false; raid/GM true.
5. **Given** ability description without timing + name `"Stormtrance"`, **When** parse runs, **Then** fallback includes 300s cooldown.

---

### User Story 3 - Sandbox patch update process (Priority: P1)

As a maintainer after a Destiny sandbox patch (e.g. 9.7.x → next), I can follow a documented process to update the constants package tables, run tests, and record sources without inventing a new layout.

**Why this priority**: Roadmap exit criterion — update process documented for sandbox patches.

**Independent Test**: Doc exists under `docs/` and is referenced from package README / quickstart; lists source paths and verification steps.

**Acceptance Scenarios**:

1. **Given** the multiplatform worktree, **When** I open the sandbox update process doc, **Then** it lists TS source mirrors, Dart package paths, test commands, and how to land changes on a DART feature branch.
2. **Given** a hypothetical patch that changes Melee enhanced max, **When** I follow the doc steps, **Then** I know which file and tests to update.

---

### Edge Cases

- Soft guidance tables (stat benefits display, activity notes) must not be treated as hard DBR blocks by this package (no save-gate APIs).
- Exotic ability requirements table may be empty of product rows; lookup/helpers still work.
- Verb resolution accepts aliases, simple plurals, and element-prefixed suffixes; unknown free text → null.
- Domain package remains independent (sandbox_data does not need to import domain for this slice).
- Package stays pure Dart / zero IO/UI.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Repository MUST include pure package `packages/sandbox_data` (`destiny2_sandbox_data`) with zero IO/UI runtime dependencies.
- **FR-002**: Package MUST export stat benefit definitions and `computeBenefitsAt` with Armor 3.0 0–200 linear interpolation parity to TS.
- **FR-003**: Package MUST export synergy elements, curated verbs, aliases, `resolveVerbSubType`, `impliedElementForVerb`, and related helpers.
- **FR-004**: Package MUST export exotic ability requirement table, `lookupExoticAbilityRequirements`, and `hasAbilityRequirements`.
- **FR-005**: Package MUST export armor archetypes + find helpers; champion counter tables + `getChampionCounterForFrame`; artifact activity gate; weapon types; concept tags; subclasses-by-class; ability timing fallbacks/parse/format.
- **FR-006**: Golden unit tests MUST cover FR-002–FR-005 scenarios above.
- **FR-007**: Workspace root MUST list the new package in the Dart workspace and Melos discovery.
- **FR-008**: Repository MUST document sandbox patch update process (sources, files, tests, branch rules).

### Key Entities

- **StatBenefitDefinition / ScalingBenefit**: Armor 3.0 benefit curves per stat.
- **SynergyVerbEntry**: Curated verb name, description, optional element.
- **ExoticAbilityRequirement**: Curated exotic → required ability pins.
- **ArmorArchetype**: Fixed primary/secondary Armor 3.0 pair.
- **ChampionType / FrameOverrideRule**: Anti-Champion 2.0 tables.
- **ConceptTag**: Faceted tag vocabulary for filters.
- **AbilityTiming**: Cooldown/duration/charges hints.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/sandbox_data` is green with benefit, verb, exotic, champion, archetype, activity, timing, weapon, concept, subclass coverage.
- **SC-002**: `packages/sandbox_data/pubspec.yaml` runtime dependencies are empty (SDK only).
- **SC-003**: Sandbox update process doc is present and linked from package layout docs.
- **SC-004**: Workspace `dart pub get` resolves both `domain` and `sandbox_data`.

## Assumptions

- Separate constants package (not only a domain submodule) satisfies “Constants package” exit criteria and keeps DART-001-style purity rules for non-evaluator tables.
- Local `ArmorStatName` wire names in sandbox_data may duplicate domain enum values for package independence in this slice; DART-011 may later enforce a single shared type.
- Acquisition routes / feat grade tables from `activityRules.ts` beyond artifact-allowed are optional extras if time allows; artifact gate is required.
- Full `subclasses.meta` and `meta/renderMetaPack` deferred; subclass name lists per class are sufficient for vocabulary.
- No NEEDS CLARIFICATION retained: soft-only semantics for display tables; hard exotic ability match evaluators already live in domain (DART-003) and may consume this table later.
