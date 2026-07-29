# Synergy — domain product description

**Kind:** domain  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**ID slug:** `domain.synergy`

---

## 1. Definition

A **Synergy** is a curated **Type linked with an Object**: a play-pattern designation (`type` + optional `subType`) plus linked gear evidence (Objects: weapon, perk, origin trait, armor set bonus, exotic armor, artifact perk, etc.). Links are **evidence by default**; authors may mark links **required**.

Distinct from a **Synergy Type designation on a Build**, which is type±subType only and may exist without a library Synergy record.

## 2. Why it exists

Builds are **intent-first**. Synergies give a durable library of play-patterns and evidence so the system can **bridge** designations → coverage and suggestions without free-text “build vibes” alone. Library depth is a readiness bar, not a gate to start composing.

## 3. Shape (product-level)

| Aspect | Description |
|--------|-------------|
| **Ownership** | Private per user library (personal types/keywords supported) |
| **Designation** | `type` + optional `subType` — **immutable after create** |
| **Editable after create** | Description + linked Objects only |
| **Links** | Evidence default; required optional; multi-required = AND |
| **Required checks** | Hard on **default variant** only; soft on others |
| **Bridging** | Build designates Types; system matches library Synergies for coverage |
| **Verb → element** | May imply element for bridging without explicit element designation |
| **LLM** | Manual propose-for-confirm only; never auto-canonical |

## 4. In scope / out of scope

**In:** Library CRUD within rules; custom personal types; required vs evidence; bridging from Build designations; LLM propose-for-confirm.

**Out:** Changing type/subtype after create; requiring a library hit to save a Build; auto-apply LLM output; concept tags as synergy identity.

## 5. Success

| Signal | Ref |
|--------|-----|
| Curated synergies with links | `DAC-P2-001` |
| Immutable designation | `DAC-P2-001a`, `DBR-SYN-012` |
| Required links on default | `DAC-P2-002` |
| Personal types | `DAC-P2-003` |
| LLM confirm-only | `DAC-P2-004` |
| In-flow create | `DAC-P2-005` |
| Build intent ≥1 type | `DAC-P1-001`, `DBR-SYN-003` |

## 6. Canonical rules

| Layer | Prefixes / IDs |
|-------|----------------|
| DBR | `DBR-SYN-001`–`014`, `DBR-LLM-*`, `DBR-PUR-004`–`005`, guidance touch `DBR-GUID-*` |
| DAC | `DAC-P2-*`, `DAC-P1-001`, `DAC-P1-009` |
| BR | `BR-SYN-*` |

**Wording SSoT:** [`specs/domain-business-rules.md`](../../specs/domain-business-rules.md) §6.

## 7. Related products

| Kind | Product |
|------|---------|
| Area | [Synergy area](../areas/synergy.md) (`/synergy`) |
| Domain peers | [Build](./build.md) (designates types), [Set](./set.md) (gear evidence targets), [Variant](./variant.md) (coverage checks) |

## 8. Open questions

- Promote gap-scan to production nav  
- Promote-to-global keyword workflow depth  

## 9. Change log

| Date | Note |
|------|------|
| 2026-07-29 | Initial product description distilled from DBR/DAC |
