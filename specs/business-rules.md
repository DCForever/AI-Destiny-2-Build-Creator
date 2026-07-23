# Business Rules

**Updated**: 2026-07-23 (BR-BLD-008 Finish slot-first chrome on 029)

Consolidated business rules derived from feature specs, contracts, data model, and tasks. Each rule has a stable **BR-** ID and links to the functional requirements (**FR-**) that justify it.

**Domain layer (canonical when conflicting)**:
- [`domain-business-rules.md`](./domain-business-rules.md) (`DBR-*`)
- [`domain-acceptance-criteria.md`](./domain-acceptance-criteria.md) (`DAC-*`)

**Canonical tag vocabulary**: [`src/data/conceptTags.ts`](../src/data/conceptTags.ts)

**Related contracts**:
- [set-attachment-contract.md](001-build-sets-synergies/contracts/set-attachment-contract.md)
- [build-variant-contract.md](001-build-sets-synergies/contracts/build-variant-contract.md)
- [synergy-contract.md](001-build-sets-synergies/contracts/synergy-contract.md)

---

## How to read this document

| Column | Meaning |
|--------|---------|
| **ID** | Stable business rule identifier (`BR-*`). Referenced from contracts and implementation. |
| **Rule** | Plain-language behavior the system must enforce. |
| **FR** | Traceability link(s) to [001 spec FRs](001-build-sets-synergies/spec.md#functional-requirements) or [002 spec FRs](002-exotic-loadouts-by-type/spec.md#functional-requirements). |

---

## 1. Concept Tags

| ID | Rule | FR |
|----|------|-----|
| BR-TAG-001 | Sets and Builds carry **zero or more concept tags** from a system-defined vocabulary — not user-typed strings. | [FR-004](001-build-sets-synergies/spec.md#functional-requirements), [FR-029](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-002 | Set **name** is user-defined and independent of tags (e.g. name `Ferropotent`, tags `[Melee, PVE, Solar]`). | [001 clarifications](001-build-sets-synergies/spec.md#clarifications) (Session 2026-06-28) |
| BR-TAG-003 | Invalid or unknown tag values are rejected at API boundary with `INVALID_TAG`. | [FR-029](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-004 | Set names are **unique per user per set type** (not scoped by tags). | [FR-005](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-005 | Tag assignment is **multi-select** on create/edit via `ConceptTagPicker`. | [FR-004](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-006 | Builds use the **same concept tag vocabulary** as Sets. | [FR-030](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-007 | Multi-tag filter uses **AND semantics**: `Solar` + `Melee` returns only entities with **both** tags. | [FR-031](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-008 | Tag filter is available in **SetAttachPicker**, **Sets list**, and **Builds list**; empty state when no matches. | [FR-032](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-TAG-009 | UI notation like `Solar · Melee` is a **filter shorthand** for two tags — not a single compound tag. | [001 clarifications](001-build-sets-synergies/spec.md#clarifications) (Session 2026-06-28) |
| BR-TAG-010 | Suggestions score by tag overlap; explicit attach-flow filter is separate from automatic suggestions. | [FR-010](001-build-sets-synergies/spec.md#functional-requirements), [FR-016](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 2. Sets — General

| ID | Rule | FR |
|----|------|-----|
| BR-SET-001 | Users can create, name, tag, edit, view, and delete Sets. | [FR-001](001-build-sets-synergies/spec.md#functional-requirements), [FR-002](001-build-sets-synergies/spec.md#functional-requirements), [FR-003](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SET-002 | Set types are distinct: **Weapon**, **Armor**, **Mod**, **Pair**, **Fashion**. | [FR-003](001-build-sets-synergies/spec.md#functional-requirements), [FR-020](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SET-003 | Sets are **private per user**; no sharing in initial scope. | [001 assumptions](001-build-sets-synergies/spec.md#assumptions) |
| BR-SET-004 | Sets store **manifest item references**, not full copies. | [001 assumptions](001-build-sets-synergies/spec.md#assumptions) |
| BR-SET-010 | **Armor** set detail shows EoF six-stat **totals** and **per-piece** stats when owned instances are pinned (wishlist has no rolls). Item rows show catalog identity (element, type/frame, **tier**, **origin trait**), **selected trait perks** (not barrel/magazine/stock), **available trait names**, and **linked library synergies**. | [DBR-STAT-001](./domain-business-rules.md), [DBR-CMP-001](./domain-business-rules.md) |
| BR-SET-011 | **Armor** set per-piece stats and set totals use the piece’s **base roll** only: sum of equipped `armor_stats` plug investments (DIM white base). Equipped armor mods, masterwork, and tuning are excluded. Catalog instance cards and inventory sort continue to use live ItemStats. Distinct from full-loadout soft-target coverage ([DBR-STAT-005](./domain-business-rules.md)). | [DBR-STAT-001](./domain-business-rules.md), [DBR-CMP-001](./domain-business-rules.md), [DBR-STAT-008](./domain-business-rules.md) |

---

## 3. Sets — Slot Cardinality

| ID | Rule | FR |
|----|------|-----|
| BR-SLOT-001 | **Weapon Sets**: at most 0 or 1 item per primary, special, heavy. | [FR-020](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-002 | **Armor Sets**: at most 0 or 1 item per helmet, arms, chest, legs, class item. | [FR-020](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-003 | **Pair Sets**: at most 0 or 1 exotic weapon and 0 or 1 exotic armor. | [FR-020](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-008 | **Weapon Sets**: at most **one exotic weapon** across all slots (kit must stay attachable without dual-exotic). Replacing the slot that holds the exotic is allowed. | [DBR-CMP-007](./domain-business-rules.md), [DAC-DST-009](./domain-acceptance-criteria.md) |
| BR-SLOT-009 | **Armor Sets**: at most **one exotic armor** (including exotic class item) across all slots. Replacing the exotic piece’s slot is allowed. | [DBR-CMP-007](./domain-business-rules.md), [DAC-DST-009](./domain-acceptance-criteria.md) |
| BR-SLOT-004 | **Mod Sets**: mods optional but encouraged; not required for valid set. | [FR-021](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-010 | **Mod Sets** are organized **per armor piece** (helmet, arms, chest, legs, class item). Multiple plugs per piece are allowed within **energy capacity** (10 default; 11 when tier 5 known). Slot-scoped mods must match the piece; **general** / **tuning** mods may sit on any piece. Storage key: `{armorSlot}:{itemHash}`. | [DBR-MOD-001](./domain-business-rules.md)–002, [FR-021](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-005 | Any slot within a set's domain **may be left empty**. | [FR-020](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-006 | Adding to an **occupied slot** requires confirmation, then replaces the item. | [FR-027](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SLOT-007 | Mod Sets and armor sets with empty mod slots MUST show UI encouragement to add mods; mods remain optional for save. | [FR-021](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 4. Fashion Sets

| ID | Rule | FR |
|----|------|-----|
| BR-FASH-001 | Fashion Sets are cosmetic/organizational (not identity). | [FR-018](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-FASH-002 | Fashion Sets must not participate in synergies, suggestions, or stats. | [FR-018](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-FASH-003 | Fashion is resolved on the variant fashion layer for equip/export; still excluded from combat synergy/stat resolution. **See** [DBR-FASH-*](./domain-business-rules.md). | [FR-018](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 5. Set Items and Weapon Rolls

| ID | Rule | FR |
|----|------|-----|
| BR-ROLL-001 | Weapon SetItems store **full roll data** (perks, barrels, traits, masterwork, etc.). | [FR-019](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ROLL-002 | Removed SetItems retain roll history for display (soft-remove). | [FR-019](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ROLL-003 | After removal, system should offer alternative weapons with similar perks. | [FR-019](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ROLL-004 | Weapon perks validated against manifest sockets on save. | [FR-019](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ROLL-005 | At most one active SetItem per `(setId, slot)`. | [FR-020](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 6. Set Deletion

| ID | Rule | FR |
|----|------|-----|
| BR-DEL-001 | Deleting a Set attached to any Build variant is **blocked**. | [FR-017](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-DEL-002 | Blocked deletion shows affected builds/variants. | [FR-017](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-DEL-003 | User must detach Set from all references before deletion. | [FR-017](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-DEL-004 | Error code: `SET_IN_USE` with `{ buildIds, variantIds }`. | [FR-017](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 7. Builds — Structure

| ID | Rule | FR |
|----|------|-----|
| BR-BLD-001 | Build contains one default variant and optional additional variants. | [FR-014](001-build-sets-synergies/spec.md#functional-requirements), [FR-022](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-BLD-002 | Shared across variants: subclass **tree/element**, designated synergies; aspects/fragments/abilities may vary per variant except build-pinned Super / exotic-required pins. Concept tags are filter metadata, not identity. **Superseded in part by** [DBR-ID-*](./domain-business-rules.md), [DBR-SUB-*](./domain-business-rules.md). | [FR-023](001-build-sets-synergies/spec.md#functional-requirements), [FR-030](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-BLD-003 | **Exotic armor** (non–class-item), when set, is build-level identity by **item** (not instance). Exotic class items are intent-locked and may differ per variant within synergies. **See** [DBR-ID-003–005](./domain-business-rules.md). | [FR-023](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-BLD-004 | **Exotic weapon** may be variant-level **or** build-shared (build-shared ⇒ identity). **See** [DBR-ID-006](./domain-business-rules.md). | [FR-023](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-BLD-005 | Shared build-level fields edited on parent build, not per variant. | [001 edge cases](001-build-sets-synergies/spec.md#edge-cases) |
| BR-BLD-006 | Exactly one default variant per build. | [FR-022](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-BLD-007 | Production Builds provides a **guided finish walkthrough** (Armor → Weapons → Mods): create empty Set + live attach (replace-by-type), link existing, capture-from-build when resolved gear exists, fill slots from Builds; Skip for now does not satisfy. **v1 shipped in 028.** | [028](028-build-inline-sets/spec.md) |
| BR-BLD-008 | Finish primary path is **slot-first**: one-tap Create (inherited name, category type, no tags) or preferred Capture, then first empty required slot fill loop. Finish does not require link/name/type/tag chrome; variant Sets tab retains advanced create/link. Armor manual fill until optimizer Finish (031). | [029](029-finish-slot-first/spec.md) |

---

## 8. Builds — Save Validation

| ID | Rule | FR |
|----|------|-----|
| BR-SAVE-001 | **Superseded by** [DBR-CMPL-001](./domain-business-rules.md): default variant must be a **full combat loadout**, not merely ≥1 slot. | [FR-022](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SAVE-002 | **Superseded in part by** [DBR-CMPL-002](./domain-business-rules.md): non-default variants may have empty slots; default must be complete. Wishlist/unowned desired rolls may save; equip gated separately ([DBR-ROLL-005](./domain-business-rules.md)). | [FR-025](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SAVE-003 | Build must designate ≥1 synergy; zero → `NO_SYNERGY`. Affirmed by [DBR-SYN-003](./domain-business-rules.md). | [FR-024](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SAVE-004 | Empty variant error: `VARIANT_EMPTY` — applies when a variant that must be complete (default) has no equipment; non-default gaps are allowed per [DBR-CMPL-002](./domain-business-rules.md). | [FR-025](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 9. Set Attachments

| ID | Rule | FR |
|----|------|-----|
| BR-ATT-001 | Users attach one or more Sets to a Build variant. | [FR-009](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ATT-002 | Attachment mode: **live** (default) or **snapshot**, per variant. | [FR-009](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ATT-003 | Live: Set edits reflected when viewing build. | [FR-009](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ATT-004 | Snapshot: frozen state at attachment time. | [FR-009](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-ATT-005 | Export includes attachments with live/snapshot indication. | [FR-009](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 10. Cross-Set Slot Conflicts

| ID | Rule | FR |
|----|------|-----|
| BR-CONF-001 | Multiple attached sets must not assign two items to the same slot. | [FR-026](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-CONF-002 | Slot conflict blocks save until resolved. | [FR-026](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-CONF-003 | Error code: `SLOT_CONFLICT`. | [FR-026](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 11. Pair Sets and Exotics

| ID | Rule | FR |
|----|------|-----|
| BR-PAIR-001 | Pair Set exotic armor must match build exotic armor. | [FR-028](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-PAIR-002 | Mismatch → `PAIR_ARMOR_MISMATCH`. | [FR-028](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-PAIR-003 | Pair Set primarily supplies variant exotic weapon. | [FR-028](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 12. Build Variants

| ID | Rule | FR |
|----|------|-----|
| BR-VAR-001 | Multiple variants per build with different sets and exotic weapons. | [FR-014](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-VAR-002 | Attachments are **live by default**; snapshot is opt-in for frozen equipable variants. **Supersedes “typically snapshots”** — see [DBR-CMP-003](./domain-business-rules.md). | [FR-014](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-VAR-003 | Compare view highlights set/weapon/notes differences; shows shared fields as common. | [FR-014](001-build-sets-synergies/spec.md#functional-requirements), [FR-015](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-VAR-004 | Filter builds by exotic armor, exotic weapon, and concept tags. | [FR-015](001-build-sets-synergies/spec.md#functional-requirements), [FR-031](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 13. Synergies

| ID | Rule | FR |
|----|------|-----|
| BR-SYN-001 | Users create and manage library Synergies of defined types (Melee, Verb, Grenade, etc.). **Create** sets type + optional subtype; **edit** may change description and links only — **type and subtype are immutable after create**. **Superseded in part by** [DBR-SYN-012](./domain-business-rules.md). | [FR-011](001-build-sets-synergies/spec.md#functional-requirements), [DBR-SYN-012](./domain-business-rules.md) |
| BR-SYN-002 | Synergies are associable with **weapons**, **weapon perks** (including exotic trait plugs), **origin traits**, **armor set bonuses** (2-piece and 4-piece), **exotic armor**, and **artifact perks**. Example: *Cast No Shadows* origin trait → Melee synergy; Lodestar *Arc Alignment* → Verb: Jolt. Affirmed by [DBR-SYN-014](./domain-business-rules.md). | [FR-012](001-build-sets-synergies/spec.md#functional-requirements), [DBR-SYN-014](./domain-business-rules.md) |
| BR-SYN-003 | Multiple designated synergies on a build contribute **equally** to suggestions. Affirmed by [DBR-SYN-004](./domain-business-rules.md). | [FR-024](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-004 | **All** linked synergies surface as tags/notes when viewing a matching weapon, perk, origin trait, or armor set bonus in catalog/inventory. | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-005 | Each synergy link is validated against manifest data for its kind; invalid targets rejected (`INVALID_SYNERGY_LINK`). | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-006 | A single synergy MAY link to **multiple** targets (e.g. both Eutechnology 2pc and 4pc bonuses on one Void synergy). | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-007 | Synergy link kinds are fixed enumerations (`weapon`, `weapon_perk`, `origin_trait`, `armor_set_bonus`, `exotic_armor`, `artifact_perk`, …) — not free-form text. | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-008 | A single target (weapon, perk, origin trait, or armor set bonus) MAY be linked to **multiple synergies** — many-to-many; no exclusivity. | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-009 | Build intent may designate verbs that **imply element** designations for bridging/coverage. Affirmed by [DBR-SYN-013](./domain-business-rules.md). | [DBR-SYN-013](./domain-business-rules.md), [024](024-build-synergy-types/spec.md) |
| BR-SYN-010 | Update of library synergy with a different type or subtype is rejected (`INVALID_SYNERGY_TYPE` / `INVALID_SYNERGY_SUBTYPE`). | [DBR-SYN-012](./domain-business-rules.md) |
| BR-SYN-011 | Within **one** library synergy, each evidence target appears **at most once**. Link search/picker results omit objects already on the draft link list; save paths dedupe by coverage key. Does not limit the same target linking to **other** synergies (BR-SYN-008). | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SYN-012 | Weapon-perk link search labels each hit as **exotic intrinsic/trait**, **legendary perk**, or **legendary & exotic** based on host weapon tier and plug role, so curators can distinguish exotic evidence from legendary rolls. | [FR-012](001-build-sets-synergies/spec.md#functional-requirements), [DBR-SYN-014](./domain-business-rules.md) |

---

## 14. Suggestions

| ID | Rule | FR |
|----|------|-----|
| BR-SUG-001 | Set suggestions: automatic (contextual) and explicit (user action/goal). | [FR-010](001-build-sets-synergies/spec.md#functional-requirements), [FR-016](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SUG-002 | Roll suggestions return ≥2 manifest-valid perk combinations. | [FR-013](001-build-sets-synergies/spec.md#functional-requirements), [SC-006](001-build-sets-synergies/spec.md#measurable-outcomes) |
| BR-SUG-003 | Roll suggestions distinguish owned vs unowned. | [FR-013](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SUG-004 | Suggestion context includes build tags, attached set tags, synergies, exotics. | [FR-010](001-build-sets-synergies/spec.md#functional-requirements), [FR-016](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-SUG-005 | Synergy suggestions use deterministic type/link/tag matching in US3/US4; LLM enhancement optional in polish. | [FR-016](001-build-sets-synergies/spec.md#functional-requirements) |

---

## 15. Catalog and Item Browsing

| ID | Rule | FR |
|----|------|-----|
| BR-CAT-001 | Fast filter/search for full weapon catalog (manifest). | [FR-006](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-CAT-002 | Fast filter/search for user-owned weapons (inventory sync). | [FR-007](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-CAT-003 | Equivalent filtering for all armor and my armor. | [FR-008](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-CAT-004 | Unsigned users browse manifest with not-owned indication. | [FR-006](001-build-sets-synergies/spec.md#functional-requirements), [FR-007](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-CAT-005 | Filter/search completes in <5 seconds. | [SC-002](001-build-sets-synergies/spec.md#measurable-outcomes) |
| BR-CAT-006 | Multi-value facets support **include OR within dimension**, **AND across dimensions**, and **exclude** (any exclude match drops). Free-text further ANDs. Affirmed by [DBR-ROLL-010](./domain-business-rules.md). | [DBR-ROLL-010](./domain-business-rules.md), [013](013-item-filter-enrichment/spec.md) |
| BR-CAT-007 | Catalog results may **group by** one or more dimensions (element, ammo, archetype, frame, slot, class) for browse; group-by does not replace filter semantics. | [DBR-ROLL-010](./domain-business-rules.md) |
| BR-CAT-008 | Catalog may filter by library **synergy membership** (include/exclude) via server allowlist and/or client hash sets when mixed. | [DBR-ROLL-010](./domain-business-rules.md) |
| BR-CAT-009 | Catalog provides a **Universal** mode for mixed-kind composition search (weapons, armor, mods, perks, traits, set bonuses, artifact perks, subclass pieces). From hit detail, users may create/add **Sets** (wizard + instance pin rules) or **Synergies** only—not Build kit attach. | [027](027-catalog-universal-search/spec.md) |

---

## 16. Exotic Loadout Filtering (Feature 002)

| ID | Rule | FR |
|----|------|-----|
| BR-EXO-001 | Filter loadouts by exact exotic armor name. | [002 FR-001](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-EXO-002 | Filter loadouts by exotic armor slot type. | [002 FR-002](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-EXO-003 | Filter by exact exotic weapon name or weapon slot type. | [002 FR-003](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-EXO-004 | Support exact-specific and slot-type modes for armor and weapons. | [002 FR-004](002-exotic-loadouts-by-type/spec.md#functional-requirements), [002 FR-006](002-exotic-loadouts-by-type/spec.md#functional-requirements), [002 FR-007](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-EXO-005 | Results show actual exotic used per loadout. | [002 FR-005](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-EXO-006 | Contextual discovery is read-only; does not mutate loadouts. | [002 assumptions](002-exotic-loadouts-by-type/spec.md#assumptions) |
| BR-EXO-007 | Scope: authenticated user's saved loadouts only. | [002 FR-009](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-EXO-008 | Loadouts without matching exotic excluded from filter results. | [002 FR-010](002-exotic-loadouts-by-type/spec.md#functional-requirements) |

Note: Feature 002 "category" refers to **exotic slot type**, not concept tags.

---

## 17. Authentication and Validation

| ID | Rule | FR |
|----|------|-----|
| BR-AUTH-001 | Sets, Synergies, Builds APIs require authenticated user. | [002 FR-009](002-exotic-loadouts-by-type/spec.md#functional-requirements) |
| BR-VAL-001 | API inputs validated with zod at route boundary. | Constitution V |
| BR-VAL-002 | Manifest item hashes validated before persistence. | [FR-019](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-VAL-003 | Concept tag ids validated against `conceptTags.ts` enum. | [FR-029](001-build-sets-synergies/spec.md#functional-requirements) |
| BR-UI-001 | **UI prevents Destiny hard constraints** for Sets and Builds: illegal set slot items are not completable via normal fill; **set-wide exotic exclusivity** (≤1 exotic weapon per weapon set, ≤1 exotic armor per armor set); dual exotic on builds; occupied set slots require replace confirm; **aspect/fragment capacity**, **armor mod energy**, and **exotic ability requirements** when known. Soft guidance remains non-blocking. **API remains authoritative**. | [DBR-GUID-003](./domain-business-rules.md), BR-SLOT-008–009, [DAC-DST-009](./domain-acceptance-criteria.md) |

---

## 18. Performance

| ID | Rule | FR |
|----|------|-----|
| BR-PERF-001 | Set attach and slot-conflict checks: <100ms. | [001 plan](001-build-sets-synergies/plan.md) |
| BR-PERF-002 | Support ≥30 sets and ≥20 synergies without UI lag. | [SC-007](001-build-sets-synergies/spec.md#measurable-outcomes) |
| BR-PERF-003 | Tag filter on 30+ sets: <5 seconds. | [FR-031](001-build-sets-synergies/spec.md#functional-requirements), [SC-002](001-build-sets-synergies/spec.md#measurable-outcomes) |

---

## 19. Armor Set Optimizer (Feature 026) — stubs

| ID | Rule | FR |
|----|------|-----|
| BR-OPT-001 | Create-from-build and first-time materialize with **attach-now** use **replace-by-type**: detach existing live attachment(s) of the **same set type** on the variant, then attach the new Set(s). Other types unchanged; detached Sets remain in the library. Names auto-suffix on collision. | [026 FR-002a](026-armor-set-optimizer/spec.md#functional-requirements), [FR-003](026-armor-set-optimizer/spec.md#functional-requirements), [FR-003a](026-armor-set-optimizer/spec.md#functional-requirements), [FR-010](026-armor-set-optimizer/spec.md#functional-requirements) |
| BR-OPT-002 | Armor Sets MAY store **`optimizerConstraints`** (JSON): exotic lock, set-bonus goals, ordered stat priorities/thresholds, mod-aware flag, **`preferReuse`** (default false). Create-from-build **seeds** exotic + soft-stat fields (empty set-bonus goals). First materialize **persists** search constraints; refresh **updates items in place** without changing constraints unless the user edits/saves or **clears** them (clear opts out of improvement checks). | [026 FR-001a](026-armor-set-optimizer/spec.md#functional-requirements), [FR-010](026-armor-set-optimizer/spec.md#functional-requirements)–[FR-010d](026-armor-set-optimizer/spec.md#functional-requirements) |
| BR-OPT-003 | Optimize results **annotate** pieces with other Armor Sets that already use the instance (active items only; self excluded). Optional **prefer-reuse** is a **soft tie-break** after lexicographic stats (+ prioritized-stat sum); never ranks a worse-stat kit above a better one. | [026 FR-005](026-armor-set-optimizer/spec.md#functional-requirements), [FR-005a](026-armor-set-optimizer/spec.md#functional-requirements) |
| BR-OPT-004 | After inventory sync, soft-**suggest** better complete kits for constrained Armor Sets **attached to ≥1 Build**; opening an unattached constrained Set also checks. **Suggest-then-confirm** — never silent auto-apply. Manual refresh remains available. | [026 FR-010c](026-armor-set-optimizer/spec.md#functional-requirements), [FR-010a](026-armor-set-optimizer/spec.md#functional-requirements) |

---

## FR → BR Traceability Index (Feature 001)

| FR | Business rule(s) |
|----|------------------|
| [FR-001](001-build-sets-synergies/spec.md#functional-requirements) | BR-SET-001 |
| [FR-002](001-build-sets-synergies/spec.md#functional-requirements) | BR-SET-001 |
| [FR-003](001-build-sets-synergies/spec.md#functional-requirements) | BR-SET-001, BR-SET-002 |
| [FR-004](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-001, BR-TAG-005 |
| [FR-005](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-004 |
| [FR-006](001-build-sets-synergies/spec.md#functional-requirements) | BR-CAT-001, BR-CAT-004 |
| [FR-007](001-build-sets-synergies/spec.md#functional-requirements) | BR-CAT-002, BR-CAT-004 |
| [FR-008](001-build-sets-synergies/spec.md#functional-requirements) | BR-CAT-003 |
| [FR-009](001-build-sets-synergies/spec.md#functional-requirements) | BR-ATT-001–005 |
| [FR-010](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-010, BR-SUG-001, BR-SUG-004 |
| [FR-011](001-build-sets-synergies/spec.md#functional-requirements) | BR-SYN-001 |
| [FR-012](001-build-sets-synergies/spec.md#functional-requirements) | BR-SYN-002, BR-SYN-004–008 |
| [FR-013](001-build-sets-synergies/spec.md#functional-requirements) | BR-SUG-002, BR-SUG-003 |
| [FR-014](001-build-sets-synergies/spec.md#functional-requirements) | BR-VAR-001–003 |
| [FR-015](001-build-sets-synergies/spec.md#functional-requirements) | BR-VAR-003, BR-VAR-004 |
| [FR-016](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-010, BR-SUG-001, BR-SUG-004, BR-SUG-005 |
| [FR-017](001-build-sets-synergies/spec.md#functional-requirements) | BR-DEL-001–004 |
| [FR-018](001-build-sets-synergies/spec.md#functional-requirements) | BR-FASH-001–003 |
| [FR-019](001-build-sets-synergies/spec.md#functional-requirements) | BR-ROLL-001–004, BR-VAL-002 |
| [FR-020](001-build-sets-synergies/spec.md#functional-requirements) | BR-SET-002, BR-SLOT-001–005, BR-ROLL-005 |
| [FR-021](001-build-sets-synergies/spec.md#functional-requirements) | BR-SLOT-004, BR-SLOT-007 |
| [FR-022](001-build-sets-synergies/spec.md#functional-requirements) | BR-BLD-001, BR-BLD-006, BR-SAVE-001 |
| [FR-023](001-build-sets-synergies/spec.md#functional-requirements) | BR-BLD-002–004 |
| [FR-024](001-build-sets-synergies/spec.md#functional-requirements) | BR-BLD-002, BR-SAVE-003, BR-SYN-003 |
| [FR-025](001-build-sets-synergies/spec.md#functional-requirements) | BR-SAVE-002, BR-SAVE-004 |
| [FR-026](001-build-sets-synergies/spec.md#functional-requirements) | BR-CONF-001–003 |
| [FR-027](001-build-sets-synergies/spec.md#functional-requirements) | BR-SLOT-006 |
| [FR-028](001-build-sets-synergies/spec.md#functional-requirements) | BR-PAIR-001–003 |
| [FR-029](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-001, BR-TAG-003, BR-VAL-003 |
| [FR-030](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-006, BR-BLD-002 |
| [FR-031](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-007, BR-VAR-004, BR-PERF-003 |
| [FR-032](001-build-sets-synergies/spec.md#functional-requirements) | BR-TAG-008 |

---

## FR → BR Traceability Index (Feature 002)

| FR | Business rule(s) |
|----|------------------|
| [002 FR-001](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-001 |
| [002 FR-002](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-002 |
| [002 FR-003](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-003 |
| [002 FR-004](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-004 |
| [002 FR-005](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-005 |
| [002 FR-006](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-004 |
| [002 FR-007](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-004 |
| [002 FR-008](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-001–003 |
| [002 FR-009](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-007, BR-AUTH-001 |
| [002 FR-010](002-exotic-loadouts-by-type/spec.md#functional-requirements) | BR-EXO-008 |

---

## Error Codes Summary

| Code | Rule IDs | FR |
|------|----------|-----|
| `INVALID_TAG` | BR-TAG-003, BR-VAL-003 | [FR-029](001-build-sets-synergies/spec.md#functional-requirements) |
| `DUPLICATE_SET_NAME` | BR-TAG-004 | [FR-005](001-build-sets-synergies/spec.md#functional-requirements) |
| `SET_IN_USE` | BR-DEL-001–004 | [FR-017](001-build-sets-synergies/spec.md#functional-requirements) |
| `SLOT_OCCUPIED` | BR-SLOT-006 | [FR-027](001-build-sets-synergies/spec.md#functional-requirements) |
| `SLOT_CONFLICT` | BR-CONF-001–003 | [FR-026](001-build-sets-synergies/spec.md#functional-requirements) |
| `TOO_MANY_EXOTICS` | BR-UI-001, [DBR-CMP-007](./domain-business-rules.md) | [DAC-DST-001](./domain-acceptance-criteria.md) |
| `ILLEGAL_SUBCLASS_KIT` | BR-UI-001, [DBR-SUB-004](./domain-business-rules.md) | [DAC-DST-003](./domain-acceptance-criteria.md) |
| `MOD_ENERGY_EXCEEDED` | BR-UI-001, [DBR-MOD-001](./domain-business-rules.md)–002 | [DAC-DST-002](./domain-acceptance-criteria.md) |
| `EXOTIC_ABILITY_MISMATCH` | BR-UI-001, [DBR-SUB-005](./domain-business-rules.md) | [DAC-DST-004](./domain-acceptance-criteria.md) |
| `PAIR_ARMOR_MISMATCH` | BR-PAIR-001–002 | [FR-028](001-build-sets-synergies/spec.md#functional-requirements) |
| `VARIANT_EMPTY` | BR-SAVE-002, BR-SAVE-004 | [FR-025](001-build-sets-synergies/spec.md#functional-requirements) |
| `NO_SYNERGY` | BR-SAVE-003 | [FR-024](001-build-sets-synergies/spec.md#functional-requirements) |
| `INVALID_SYNERGY_LINK` | BR-SYN-005 | [FR-012](001-build-sets-synergies/spec.md#functional-requirements) |
| `INVALID_SYNERGY_TYPE` | BR-SYN-010, [DBR-SYN-012](./domain-business-rules.md) | Designation type lock after create |
| `INVALID_SYNERGY_SUBTYPE` | BR-SYN-010, [DBR-SYN-012](./domain-business-rules.md) | Designation subtype lock after create |
| `DEFAULT_VARIANT_INCOMPLETE` | [DBR-VAR-001](./domain-business-rules.md), [015 default-loadout contract](015-build-identity/contracts/default-loadout-naming-contract.md) | [015 FR-007+](015-build-identity/spec.md) |
| `IDENTITY_CONFIRM_REQUIRED` | [DBR-ID-010](./domain-business-rules.md), [015 confirm/fork contract](015-build-identity/contracts/identity-confirm-fork-contract.md) | [015 FR-010+](015-build-identity/spec.md) |
| `DUPLICATE_BUILD_NAME` | [015 naming contract](015-build-identity/contracts/default-loadout-naming-contract.md) | [015 FR-012+](015-build-identity/spec.md) |
| `NOT_EQUIP_READY` | [DBR-EQP-003](./domain-business-rules.md), [016 gate contract](016-wishlist-equip-ready/contracts/equip-dim-gate-contract.md) | [016 FR-006/013](016-wishlist-equip-ready/spec.md) |

---

## Open / Undecided

| Topic | Status |
|-------|--------|
| Large sets (50+ items) | Not resolved |
| Multiple synergies on same items | **Resolved in domain**: many-to-many links; required links AND on default variant — see [DBR-SYN-007–010](./domain-business-rules.md) |
| Manifest deprecation of set items | Soft stale retained; instance stale pins — see [DBR-ROLL-006](./domain-business-rules.md) |
| User-defined custom tags | Out of scope v1 (personal synergy **keywords** allowed — [DBR-SYN-005](./domain-business-rules.md)) |
| Auto-infer tags from set contents | Future enhancement |
| Shareable read-only build links | Planned — [DBR-BLD-005](./domain-business-rules.md) |

## Domain supersession index (2026-07-10; extended 2026-07-14)

When implementing build/equip behavior, prefer [`domain-business-rules.md`](./domain-business-rules.md) over older BR text where marked superseded above. Full mapping: domain doc § Supersessions.

| Legacy / partial rule | Domain / updated replacement |
|----------------------|------------------------------|
| BR-SYN-001 “full CRUD type after create” | DBR-SYN-012, BR-SYN-001 (updated), BR-SYN-010 |
| BR-CAT-001–003 only free-text/generic filter | DBR-ROLL-010, BR-CAT-006–008 |

