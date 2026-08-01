# Domain rules gap scan — code vs DBR/BR

**Date**: 2026-07-29  
**Scope**: Specs re-sync (Obsidian Domains + Destiny Objects → `domain-business-rules.md`, `domain-acceptance-criteria.md`, `business-rules.md`) vs `src/`.  
**Method**: Static search + targeted file reads (not full test suite run).

**Legend**

| Status | Meaning |
| --- | --- |
| **OK** | Code aligns with rule intent (may miss polish) |
| **Partial** | Core path exists; missing pieces vs product |
| **Gap** | Not implemented or contradicts product |
| **N/A** | Spec-only / data-only / deferred UI polish |

---

## Executive summary

| Priority | Theme | Status | Notes |
| --- | --- | --- | --- |
| P0 | Set save minimums (Weapon/Armor ≥2, Mod multi-piece) | **Done (Phase A)** | Attach + attached soft-remove; empty scaffold OK for finish |
| P0 | Per-variant subclass kit (aspects/fragments/abilities) | **Done (Phase E)** | `build_variants.subclass_kit`; effective kit per variant |
| P0 | Default kit bar (aspects + fragments at capacity + Super/melee/grenade) | **Done (Phase B)** | `defaultLoadoutCompleteness` + `assertFullCombatLoadout` |
| P0 | Artifact filled on default | **Done (Phase B)** | Hash + non-empty config required on default save |
| P0 | Required-link hard gate on default (pins only) | **Done (Phase C)** | `required` column + `assertRequiredLinksSatisfied` on default save |
| P1 | Expanded synergy link kinds | **Done (Phase D)** | 12 kinds in schema + pickers + coverage |
| P1 | Ammo / weapon_slot designation types | **Done (Phase D)** | Creatable `ammo` + `weapon_slot`; legacy weapon types readable |
| P1 | Armor Set bonus package constraint | **Done (Phase F)** | `set_bonus_constraint` + attach/fill/update gates |
| P1 | Tree change wipe + identity confirm | **Done (Phase E)** | `subclassTree` identity + wipe all variant kits |
| P1 | Class immutable after create | **Done (Phase 2)** | `CLASS_IMMUTABLE` on update; General tab locked live |
| P2 | armor_set_bonus link tier match | **OK** | `bonusPieces` + coverage count ≥ tier |
| P2 | weapon_perk family (base/enhanced) match | **Done (Phase G)** | `perkFamily.ts` name-based base↔enhanced |
| P2 | Exotic class-item Synergy = perk config | **Done (Phase G)** | ClassItem shell ignored; `perkHash` on class_item |
| P2 | Artifact filled on default | **Done (Phase B)** | Hash + non-empty config on default save |
| P2 | Four areas UI | **Done (Phase 2)** | Four area tabs + Finish as chrome (`isArea`) |
| P2 | Mini kit strip | **Done (Phase 2)** | `MiniKitStrip` — five abilities always + aspects/fragments |
| P2 | Can-roll / craft on weapon detail | **Done (Phase H)** | `weaponRollDetail` + Catalog/Set detail panels |
| P2 | No bare hashes primary UI | **Done (Phase H)** | `displayName` primary + hash footer discipline |
| P3 | Soft coverage / exotic limits / mod energy / kit capacity hard caps | **OK** | Core evaluators present |

---

## 1. Synergy library & designations

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| DBR-SYN-003 ≥1 Type to save | **OK** | `evaluateSynergyRequirement`, `NO_SYNERGY` in `buildService` | — |
| DBR-SYN-005 no personal types v1 | **OK** | `CREATABLE_SYNERGY_TYPES` fixed enum | Align product vocabulary (ammo/slot) |
| DBR-SYN-012 immutable type/subtype | **OK** | Service rejects type/subtype change | — |
| DBR-SYN-004a one library row per designation | **Partial** | Merge API exists; create may still allow dups depending on service | Enforce unique (type, subType) per user on create |
| DBR-SYN-015 link kinds (12) | **Done Phase D** | Full enum + pickers + kit/mod matchers | — |
| DBR-SYN-014 exotic trait as weapon_perk | **OK** | Kind + labeling (BR-SYN-012 path) | — |
| DBR-SYN-014a perk family match | **Done Phase G** | `perkFamily.ts` + `matchEvidenceLink` / required gate | Name-normalize when family known |
| DBR-SYN-014b armor_set_bonus tier on link | **OK** | `bonusPieces` 2\|4; coverage `count >= needed` | Ensure UI always sets tier on create |
| DBR-SYN-017 ammo vs weapon_slot | **Done Phase D** | Creatable `ammo`/`weapon_slot`; old types legacy | — |
| DBR-SYN-007–010 required links | **Done Phase C** | `synergy_links.required` + zod `required?: boolean` | Soft evidence unchanged |
| DBR-SYN-010a pins satisfy required | **Done Phase C** | Wishlist match → fail; pin match → pass | Artifact_perk uses applied config |
| BR-SYN-019a no class/movement links | **OK** | Not in schema | Keep excluded |

**Key files**: `src/lib/synergies/schemas.ts`, `src/lib/builds/coverage.ts`, `src/lib/db/schema.ts` (`synergy_links`), debug Synergies UI.

---

## 2. Build identity & lifecycle

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| DBR-ID-001–004 Types + optional classic exotic | **OK** | `identityFieldsChanged`, exotic armor mode | — |
| DBR-ID-005 class item intent-lock | **Partial** | Mode from armor slot; soft intent not fully productized | Soft “fits synergies” guidance |
| DBR-ID-006–006b exotic weapon promote/demote | **Partial** | Build vs variant exotic weapon fields | Explicit promote/demote UX + identity flags |
| DBR-ID-007 Super pin | **OK** | `pinnedSuper` identity | — |
| DBR-ID-008 confirm/fork | **OK** | `IDENTITY_CONFIRM_REQUIRED` | — |
| DBR-ID-008a tree change as identity | **Done Phase E** | Tree in identityFieldsChanged + wipe path | — |
| DBR-BLD-007 class fixed after create | **Done Phase 2** | `CLASS_IMMUTABLE`; class never written on update | UI lock in General tab |
| DBR-BLD-008–009 tree change wipe kit | **Done Phase E** | `wipeAllVariantKits` on tree change | — |
| DBR-BLD-010 mini kit strip | **Done Phase 2** | `MiniKitStrip` on BuildIdentity + VariantCard | Empty ability placeholders |

**Key files**: `src/lib/builds/buildService.ts`, `src/lib/db/schema.ts` (`builds.subclass`), `VariantCard` / `BuildIdentity`.

---

## 3. Subclass kit

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| DBR-SUB-001 tree shared | **OK** | Tree name on build.subclass | — |
| DBR-SUB-003 kit per variant | **Done Phase E** | `subclass_kit` column + effective merge | Legacy fall back to build kit fields |
| DBR-SUB-004 capacity hard | **OK** | `assertSubclassKitLegal`, max 2 aspects, fragment capacity sum | — |
| DBR-SUB-005 exotic ability pins | **OK** | `assertExoticAbilityPins`, evaluators | — |
| DBR-SUB-006 default complete kit bar | **Done Phase B** | `collectSubclassKitCompleteGaps` | Class/movement still optional |
| DBR-SUB-007 class/movement optional | **OK** (default) | Not required in loadout assert | Keep optional |
| DBR-SUB-008–009 capacity trim | **Partial** | UI shows capacity; no auto-trim on aspect shrink | Auto-trim on save/edit |
| Scope clear on class/tree change | **Done Phase E** (tree wipe) | Tree change wipes kits to empty baseline | Class-change still open |

**Key files**: `assertSubclassKit.ts`, `destinyBuildConstraints.ts`, `resolveVariant.ts` (`assertFullCombatLoadout`), `VariantEditPanel` / `SubclassTab`.

---

## 4. Completeness & gates

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| DBR-CMPL-001 weapons + armor + mods | **Partial** | Default: 3 weapon + 5 armor + mods attachment flag | Kit + artifact fill missing |
| DBR-CMPL-001a artifact config filled | **Done Phase B** | Default save requires hash + non-empty config | Tree shape still data-driven later |
| DBR-CMPL-001b fashion optional | **OK** | Not required | — |
| DBR-CMPL-001d three gates | **Partial** | Gate 1 partial; gate 2 missing; gate 3 equip-ready for equip/export | Implement gate 2 |
| DBR-CMPL-002 non-default may gap | **OK** | Full loadout only if `isDefault` | — |
| DBR-CMPL-005 four areas | **Done Phase 2** | Four `isArea` tabs; Finish dashed chrome | Labels match product |

**Key files**: `buildService` validate path ~709–711, `DefaultVariantComposer`, `equipReady.ts`.

---

## 5. Sets

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| DBR-CMP-007 dual exotic loadout | **OK** | `evaluateExoticLimits` / assert on resolve | — |
| DBR-CMP-008 Weapon/Armor ≥2 on save | **Partial → Done Phase A** | `setMinimumOccupancy.ts`; attach + remove-while-attached | Empty scaffold still attachable (finish) |
| DBR-CMP-009 Mod ≥2 pieces on save | **Partial → Done Phase A** | Same; `MOD_SET_MIN_SLOTS` | Same empty exception |
| DBR-CMP-010 Pair/Fashion exempt | **OK** | Fashion always ok; Pair both slots (`PAIR_INCOMPLETE`) | — |
| Set exotic exclusivity | **OK** | `assertSetExoticExclusivity` | — |
| Slot legality | **OK** | `assertSetItemAllowed` | — |
| DBR-SETB-003–006 Armor Set bonus **constraint** | **Done Phase F** | `armorSetBonusConstraint.ts`; `sets.set_bonus_constraint`; fill mismatch + attach/update tier | Soft EXOTIC_BLOCKS_SET_BONUS on incomplete |
| BR-SET-030 Synergy Types on Sets | **Gap** | No set-level designation storage found | Optional later; product-locked |
| DBR-MOD energy 10/11 | **OK** | `evaluateModEnergy` path | — |
| DBR-STAT-008 base roll board | **Partial** | Armor set detail / BR-SET-011 paths | Verify board never uses live modded totals |

**Key files**: `src/lib/sets/*`, `destinySetConstraints.ts`, `setService` / `setItemService`.

---

## 6. Rolls, equip, artifact, fashion

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| Wishlist save without pins | **OK** | Equip gate separate | — |
| DBR-EQP equip-ready | **OK** | `equipReady.ts`, `NOT_EQUIP_READY` | — |
| Stale pins | **OK** | Tests in equipReady | — |
| DBR-ART 6 artifacts + config | **Partial** | `artifactSelection.ts`; count is store-driven (good vs hardcode 6) | Default fill gate |
| DBR-FASH omit leave as-is | **Partial** | Fashion layer exists (018) | Confirm omit semantics on equip path |
| Catalyst/deepsight soft | **OK** | Display-only rules | — |

---

## 7. Presentation (DIM North Star)

| Rule | Status | Evidence | Gap action |
| --- | --- | --- | --- |
| DBR-UI-001–005 icon-first | **Partial** | Catalog/build use icons widely | Audit dense text tables |
| DBR-UI-006 no bare hash labels | **Done Phase H** | `entityLabelParts` / primary never bare hash; hash footer on detail | — |
| DBR-UI-007 can-roll + craft on detail | **Done Phase H** | `buildWeaponRollDetail` + UniversalHit / Sets / InstancePerkGrid | Craft only when known |
| DBR-UI-008 acquire when data exists | **Partial** | Some source fields elsewhere | Detail surfaces when data loaded |

---

## 8. Architectural mismatches (high leverage)

1. **Subclass ownership** — Product: kit per **variant**, tree on **Build**. Code: entire subclass blob on **Build**. Unblocks: per-variant kit, tree wipe, mini strip per focused variant, DBR-SUB-003.  
2. **Default completeness** — Equipment-centric only; product combat loadout includes **kit + artifact fill**.  
3. **Required links** — Product three-gate model; code has compose (partial) + equip-ready, **no required-link gate**.  
4. **Set package quality floors** — Documented mins not enforced in `src/`.

---

## Suggested implementation order

| Phase | Work | Rules |
| --- | --- | --- |
| **A** | Set save mins (Weapon/Armor ≥2, Mod multi-piece) + error codes | **Shipped 2026-07-29** — attach/remove gates; see `setMinimumOccupancy.ts` |
| **B** | Default complete: kit bar + artifact filled (even before per-variant kit split) | **Shipped 2026-07-29** — `defaultLoadoutCompleteness.ts` |
| **C** | Synergy: `required` flag + default save gate using equip-ready / kit claims | **Shipped 2026-07-29** — `assertRequiredLinks.ts` |
| **D** | Expand link kinds + coverage matchers; ammo/weapon_slot types | **Shipped 2026-07-30** |
| **E** | Data model: variant-owned kit; tree change confirm + wipe | **Shipped 2026-07-30** — `subclassKit.ts` |
| **F** | Armor Set bonus constraint | **Shipped 2026-07-30** — `armorSetBonusConstraint.ts` |
| **G** | Perk family match; class-item exotic_armor config links | **Shipped 2026-07-30** — `perkFamily.ts`, DBR-ID-011 match |
| **H** | Presentation: can-roll/craft detail; hash footer discipline | **Shipped 2026-07-30** — `presentation/*`, Catalog/Set detail |
| **2** | Class lock + mini kit strip + four areas chrome | **Shipped 2026-07-30** — `CLASS_IMMUTABLE`, `MiniKitStrip` |

---

## What is already solid

- Dual exotic hard blocks (set + loadout)
- Fragment/aspect **capacity** hard save
- Mod energy hard save
- ≥1 synergy type
- Designation immutability
- Armor set bonus **link** with 2/4 piece threshold in coverage
- Equip-ready / stale pin / DIM export gates
- Exotic ability pin mismatch path
- Soft coverage tiers (supported/weak/missing)
- Catalog universal search kinds (including artifact_perk, armor_set_bonus tiers)

---

## Out of scope for this scan

- Full product-map surface `rules:` attachment audit  
- Flutter parity  
- Running full `npm test` / gate (static scan only)  
- Every DO-* presentation micro-rule  

---

## Traceability

| Spec | Code hotspot |
| --- | --- |
| `specs/domain-business-rules.md` | (this scan) |
| `specs/domain-acceptance-criteria.md` | DAC-P1-003, DAC-DST-*, DAC-VAR-* |
| `specs/business-rules.md` | BR-SLOT-011+, BR-SYN-*, BR-VAR-050+ |

Re-run after Phase A–C to shrink P0 rows.
