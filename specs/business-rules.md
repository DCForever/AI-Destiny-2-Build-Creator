# Business Rules

**Updated**: 2026-06-28

Consolidated business rules from [001-build-sets-synergies](001-build-sets-synergies/spec.md), [002-exotic-loadouts-by-type](002-exotic-loadouts-by-type/spec.md), contracts, data model, and tasks. Each rule has a stable ID and source reference.

**Canonical tag vocabulary**: [`src/data/conceptTags.ts`](../src/data/conceptTags.ts)

---

## 1. Concept Tags

| ID | Rule | Source |
|----|------|--------|
| BR-TAG-001 | Sets and Builds carry **zero or more concept tags** from a system-defined vocabulary — not user-typed strings. | FR-004, FR-029, Session 2026-06-28 |
| BR-TAG-002 | Set **name** is user-defined and independent of tags (e.g. name `Ferropotent`, tags `[Melee, PVE, Solar]`). | Session 2026-06-28 |
| BR-TAG-003 | Invalid or unknown tag values are rejected at API boundary with `INVALID_TAG`. | FR-029, Contract |
| BR-TAG-004 | Set names are **unique per user per set type** (not scoped by tags). | FR-005 |
| BR-TAG-005 | Tag assignment is **multi-select** on create/edit via `ConceptTagPicker`. | FR-004 |
| BR-TAG-006 | Builds use the **same concept tag vocabulary** as Sets. | FR-030 |
| BR-TAG-007 | Multi-tag filter uses **AND semantics**: `Solar` + `Melee` returns only entities with **both** tags. | FR-031 |
| BR-TAG-008 | Tag filter is available in **SetAttachPicker**, **Sets list**, and **Builds list**; empty state when no matches. | FR-032, BR-TAG-008 |
| BR-TAG-009 | UI notation like `Solar · Melee` is a **filter shorthand** for two tags — not a single compound tag. | Session 2026-06-28 |
| BR-TAG-010 | Suggestions score by tag overlap; explicit attach-flow filter is separate from automatic suggestions. | FR-010, FR-016 |

---

## 2. Sets — General

| ID | Rule | Source |
|----|------|--------|
| BR-SET-001 | Users can create, name, tag, edit, view, and delete Sets. | FR-001–003 |
| BR-SET-002 | Set types are distinct: **Weapon**, **Armor**, **Mod**, **Pair**, **Fashion**. | FR-020, Clarification 2026-06-22 |
| BR-SET-003 | Sets are **private per user**; no sharing in initial scope. | Assumption |
| BR-SET-004 | Sets store **manifest item references**, not full copies. | Assumption |

---

## 3. Sets — Slot Cardinality

| ID | Rule | Source |
|----|------|--------|
| BR-SLOT-001 | **Weapon Sets**: at most 0 or 1 item per primary, special, heavy. | FR-020 |
| BR-SLOT-002 | **Armor Sets**: at most 0 or 1 item per helmet, arms, chest, legs, class item. | FR-020 |
| BR-SLOT-003 | **Pair Sets**: at most 0 or 1 exotic weapon and 0 or 1 exotic armor. | FR-020 |
| BR-SLOT-004 | **Mod Sets**: mods optional but encouraged; not required for valid set. | FR-021 |
| BR-SLOT-005 | Any slot within a set's domain **may be left empty**. | FR-020 |
| BR-SLOT-006 | Adding to an **occupied slot** requires confirmation, then replaces the item. | FR-027, `SLOT_OCCUPIED` |

---

## 4. Fashion Sets

| ID | Rule | Source |
|----|------|--------|
| BR-FASH-001 | Fashion Sets are purely cosmetic/organizational. | FR-018 |
| BR-FASH-002 | Fashion Sets must not participate in build composition, synergies, suggestions, or stats. | FR-018 |
| BR-FASH-003 | Fashion Sets excluded from variant slot resolution. | Tasks, Contract |

---

## 5. Set Items and Weapon Rolls

| ID | Rule | Source |
|----|------|--------|
| BR-ROLL-001 | Weapon SetItems store **full roll data** (perks, barrels, traits, masterwork, etc.). | FR-019 |
| BR-ROLL-002 | Removed SetItems retain roll history for display (soft-remove). | FR-019 |
| BR-ROLL-003 | After removal, system should offer alternative weapons with similar perks. | FR-019 |
| BR-ROLL-004 | Weapon perks validated against manifest sockets on save. | Data model |
| BR-ROLL-005 | At most one active SetItem per `(setId, slot)`. | Data model, FR-020 |

---

## 6. Set Deletion

| ID | Rule | Source |
|----|------|--------|
| BR-DEL-001 | Deleting a Set attached to any Build variant is **blocked**. | FR-017 |
| BR-DEL-002 | Blocked deletion shows affected builds/variants. | FR-017 |
| BR-DEL-003 | User must detach Set from all references before deletion. | FR-017 |
| BR-DEL-004 | Error code: `SET_IN_USE` with `{ buildIds, variantIds }`. | Contract |

---

## 7. Builds — Structure

| ID | Rule | Source |
|----|------|--------|
| BR-BLD-001 | Build contains one default variant and optional additional variants. | Spec |
| BR-BLD-002 | Shared across variants: subclass, aspects, exotic armor, designated synergies, concept tags. | FR-023, FR-030 |
| BR-BLD-003 | **Exotic armor** is build-level, shared by all variants. | FR-023 |
| BR-BLD-004 | **Exotic weapon** may differ per variant. | FR-023 |
| BR-BLD-005 | Shared build-level fields edited on parent build, not per variant. | Edge case |
| BR-BLD-006 | Exactly one default variant per build. | Data model |

---

## 8. Builds — Save Validation

| ID | Rule | Source |
|----|------|--------|
| BR-SAVE-001 | Build cannot save unless default variant has ≥1 equipment slot via attached sets. | FR-022 |
| BR-SAVE-002 | Variant cannot save unless ≥1 equipment slot filled via attached sets. | FR-025 |
| BR-SAVE-003 | Build must designate ≥1 synergy; zero → `NO_SYNERGY`. | FR-024 |
| BR-SAVE-004 | Empty variant error: `VARIANT_EMPTY`. | Contract |

---

## 9. Set Attachments

| ID | Rule | Source |
|----|------|--------|
| BR-ATT-001 | Users attach one or more Sets to a Build variant. | FR-009 |
| BR-ATT-002 | Attachment mode: **live** (default) or **snapshot**, per variant. | FR-009 |
| BR-ATT-003 | Live: Set edits reflected when viewing build. | FR-009 |
| BR-ATT-004 | Snapshot: frozen state at attachment time. | FR-009 |
| BR-ATT-005 | Export includes attachments with live/snapshot indication. | US3 |

---

## 10. Cross-Set Slot Conflicts

| ID | Rule | Source |
|----|------|--------|
| BR-CONF-001 | Multiple attached sets must not assign two items to the same slot. | FR-026 |
| BR-CONF-002 | Slot conflict blocks save until resolved. | FR-026 |
| BR-CONF-003 | Error code: `SLOT_CONFLICT`. | Contract |

---

## 11. Pair Sets and Exotics

| ID | Rule | Source |
|----|------|--------|
| BR-PAIR-001 | Pair Set exotic armor must match build exotic armor. | FR-028 |
| BR-PAIR-002 | Mismatch → `PAIR_ARMOR_MISMATCH`. | FR-028 |
| BR-PAIR-003 | Pair Set primarily supplies variant exotic weapon. | FR-028 |

---

## 12. Build Variants

| ID | Rule | Source |
|----|------|--------|
| BR-VAR-001 | Multiple variants per build with different sets and exotic weapons. | FR-014 |
| BR-VAR-002 | Variants typically use snapshots for stable compositions. | FR-014, US6 |
| BR-VAR-003 | Compare view highlights set/weapon differences; shows shared fields as common. | US6 |
| BR-VAR-004 | Filter builds by exotic armor, exotic weapon, and concept tags. | FR-015, FR-031 |

---

## 13. Synergies

| ID | Rule | Source |
|----|------|--------|
| BR-SYN-001 | Users CRUD Synergies of defined types (Melee, Verb, Grenade, etc.). | FR-011 |
| BR-SYN-002 | Synergies associable with items, sets, or builds. | FR-012 |
| BR-SYN-003 | Multiple designated synergies contribute **equally** to suggestions. | FR-024 |
| BR-SYN-004 | Relevant synergies surface as tags/notes on owned items/sets. | US4 |

---

## 14. Suggestions

| ID | Rule | Source |
|----|------|--------|
| BR-SUG-001 | Set suggestions: automatic (contextual) and explicit (user action/goal). | FR-010, FR-016 |
| BR-SUG-002 | Roll suggestions return ≥2 manifest-valid perk combinations. | SC-006 |
| BR-SUG-003 | Roll suggestions distinguish owned vs unowned. | US5 |
| BR-SUG-004 | Suggestion context includes build tags, attached set tags, synergies, exotics. | Contract |

---

## 15. Catalog and Item Browsing

| ID | Rule | Source |
|----|------|--------|
| BR-CAT-001 | Fast filter/search for full weapon catalog (manifest). | FR-006 |
| BR-CAT-002 | Fast filter/search for user-owned weapons (inventory sync). | FR-007 |
| BR-CAT-003 | Equivalent filtering for all armor and my armor. | FR-008 |
| BR-CAT-004 | Unsigned users browse manifest with not-owned indication. | US2 |
| BR-CAT-005 | Filter/search completes in <5 seconds (SC-002). | SC-002 |

---

## 16. Exotic Loadout Filtering (Feature 002)

| ID | Rule | Source |
|----|------|--------|
| BR-EXO-001 | Filter loadouts by exact exotic armor name. | FR-001 (002) |
| BR-EXO-002 | Filter loadouts by exotic armor slot type. | FR-002 (002) |
| BR-EXO-003 | Filter by exact exotic weapon name or weapon slot type. | FR-003 (002) |
| BR-EXO-004 | Support exact-specific and slot-type modes for armor and weapons. | FR-004 (002) |
| BR-EXO-005 | Results show actual exotic used per loadout. | FR-005 (002) |
| BR-EXO-006 | Contextual discovery is read-only; does not mutate loadouts. | Assumption (002) |
| BR-EXO-007 | Scope: authenticated user's saved loadouts only. | FR-009 (002) |

Note: Feature 002 "category" refers to **exotic slot type**, not concept tags.

---

## 17. Authentication and Validation

| ID | Rule | Source |
|----|------|--------|
| BR-AUTH-001 | Sets, Synergies, Builds APIs require authenticated user. | Contract |
| BR-VAL-001 | API inputs validated with zod at route boundary. | Constitution V |
| BR-VAL-002 | Manifest item hashes validated before persistence. | Constitution V |
| BR-VAL-003 | Concept tag ids validated against `conceptTags.ts` enum. | FR-029 |

---

## 18. Performance

| ID | Rule | Source |
|----|------|--------|
| BR-PERF-001 | Set attach and slot-conflict checks: <100ms. | Plan |
| BR-PERF-002 | Support ≥30 sets and ≥20 synergies without UI lag. | SC-007 |
| BR-PERF-003 | Tag filter on 30+ sets: <5 seconds. | SC-002, FR-031 |

---

## Open / Undecided

| Topic | Status |
|-------|--------|
| Large sets (50+ items) | Not resolved |
| Multiple synergies on same items | Not resolved |
| Manifest deprecation of set items | Not resolved |
| User-defined custom tags | Out of scope v1 |
| Auto-infer tags from set contents | Future enhancement |

---

## Error Codes Summary

| Code | Rule IDs |
|------|----------|
| `INVALID_TAG` | BR-TAG-003, BR-VAL-003 |
| `DUPLICATE_SET_NAME` | BR-TAG-004 |
| `SET_IN_USE` | BR-DEL-001–004 |
| `SLOT_OCCUPIED` | BR-SLOT-006 |
| `SLOT_CONFLICT` | BR-CONF-001–003 |
| `PAIR_ARMOR_MISMATCH` | BR-PAIR-001–002 |
| `VARIANT_EMPTY` | BR-SAVE-002 |
| `NO_SYNERGY` | BR-SAVE-003 |
