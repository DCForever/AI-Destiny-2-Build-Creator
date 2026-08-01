# Sandbox data update process

**Package:** `packages/sandbox_data` (`destiny2_sandbox_data`)  
**Workstream:** DART (multiplatform port)  
**Integration base:** `feature/multiplatform-dart`  
**Related slice:** DART-009 `static-sandbox-data`  
**Updated:** 2026-07-24

Curated Destiny sandbox tables (stat curves, synergy verbs, champion frames, etc.) live as **pure Dart constants**. When Bungie ships a sandbox / Armor / Anti-Champion patch, update this package — do not invent a second copy under Flutter/Jaspr apps.

## Principles

1. **Single source for multiplatform shells** — Flutter and Jaspr import `destiny2_sandbox_data`; do not re-embed tables in UI packages.
2. **Soft display ≠ hard gates** — Stat benefit lines, activity notes, and champion guidance are soft/display. Hard blocks (exotic limits, mod energy, exotic ability match evaluators) stay in `destiny2_domain`. Only rows that are true hard requirements belong in `exoticAbilityRequirements`.
3. **Parity with product TS while Next remains production** — Until cutover, mirror `src/data/**` in the same monorepo so product and Dart stay aligned.
4. **No IO** — No network fetches of patch notes at runtime. Transcribe into constants; cite sources in comments or `src/data/meta/sources/` on the product side.

## Source map (TypeScript → Dart)

| Product (TS) | Dart module |
| ------------ | ----------- |
| `src/data/rules/statBenefits.ts` | `lib/src/stat_benefits.dart` |
| `src/data/rules/armorArchetypes.ts` | `lib/src/armor_archetypes.dart` |
| `src/data/rules/championCounters.ts` | `lib/src/champion_counters.dart` |
| `src/data/rules/activityRules.ts` | `lib/src/activity_rules.dart` |
| `src/data/rules/abilityTimings.ts` | `lib/src/ability_timings.dart` |
| `src/data/synergyElements.ts` | `lib/src/synergy_elements.dart` |
| `src/data/synergyVerbs.ts` | `lib/src/synergy_verbs.dart` |
| `src/data/exoticAbilityRequirements.ts` | `lib/src/exotic_ability_requirements.dart` |
| `src/data/weaponTypes.ts` | `lib/src/weapon_types.dart` |
| `src/data/conceptTags.ts` | `lib/src/concept_tags.dart` |
| `src/data/subclasses.ts` (`SUBCLASSES_BY_CLASS`) | `lib/src/subclasses.dart` |

Product source notes (patch text) often live under `src/data/meta/sources/`. Prefer updating TS first (or in the same change), then port values into Dart.

## Step-by-step (sandbox patch)

1. **Identify deltas** from patch notes / Dev Insights (Armor 3.0 stats, Anti-Champion frames, ability economy, new verbs, subclass renames).
2. **Update product TS tables** under `src/data/` when the Next line still owns production truth (keeps vitest goldens as reference).
3. **Port the same numbers/strings** into the matching Dart module(s) in `packages/sandbox_data/lib/src/`.
4. **Extend golden tests** in `packages/sandbox_data/test/sandbox_data_test.dart` (and TS vitest) for any changed curve, counter, or vocabulary entry.
5. **Run**:
   ```powershell
   cd F:\Destiny2BuildCreator-multiplatform-dart
   dart pub get
   dart test packages/sandbox_data
   dart analyze packages/sandbox_data
   ```
6. **Land on the multiplatform line**:
   - Branch from `feature/multiplatform-dart` (e.g. `dart-NNN-…` for a Spec Kit slice, or a small fix branch merged to the same base).
   - **Do not** merge multiplatform sandbox work only to product `main` without integrating `feature/multiplatform-dart`.
7. **Bump comments** with the sandbox version (e.g. `9.7.0`) in module headers when curves change.
8. If hard exotic ability gates are added/removed, update `exotic_ability_requirements.dart` **and** ensure domain hard evaluators (DART-003) still treat soft-only rows correctly (empty table is fine).

## Example: Melee enhanced max changes

1. Patch notes: Melee ability damage at 200 changes from +30% to +X%.
2. Edit `statBenefits.ts` `Melee.enhancedScaling` max and TS test expectations.
3. Edit `stat_benefits.dart` `ArmorStatName.melee` enhanced `ScalingBenefit.max`.
4. Update `computeBenefitsAt(ArmorStatName.melee, 200)` expectation in `sandbox_data_test.dart`.
5. `dart test packages/sandbox_data` → green → commit on multiplatform branch.

## What not to put here

- Manifest entity JSON / extracted perk text (DART-017+)
- Inventory-derived gear tiers that need API `gearTier` (keep resolution in inventory/domain adapters)
- Full LLM meta packs / skill digests (`src/data/meta/renderMetaPack.ts`)
- Secrets, OAuth, or any IO

## Package purity checklist

- [ ] `packages/sandbox_data/pubspec.yaml` has empty `dependencies:` (SDK only)
- [ ] No Flutter / Jaspr / Drift / http imports
- [ ] Soft tables have no “auto-apply” or save-blocking APIs
- [ ] Tests cover changed behaviors
