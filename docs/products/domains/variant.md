# Variant — domain product description

**Kind:** domain  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**ID slug:** `domain.variant`

---

## 1. Definition

A **Variant** is a **named kit slice under a Build**: set attachments, slot overrides, rolls/pins, subclass aspects/abilities (within shared tree), artifact config, fashion, soft stat targets, and notes—while preserving the parent Build’s identity. Exactly one variant is the **default**.

## 2. Why it exists

Same play-pattern identity, different loadouts (weapons/armor/activity tweaks) without forking a new Build every time.

## 3. Shape (product-level)

| Aspect | Description |
|--------|-------------|
| **Parent** | Always belongs to one [Build](./build.md) |
| **Default** | Exactly one; must be full combat loadout when “complete” |
| **Non-default** | May have gaps; soft guidance; equip-with-gaps rules as domain allows |
| **Composition** | Sets live/snapshot + slot pins/overrides |
| **Equip-ready** | Every applied combat slot pinned to non-stale owned instance |
| **Wishlist** | Desired rolls may save without pins; equip/export blocked |
| **Artifact** | Exactly one of fixed artifacts + config per variant (domain ART) |
| **Fashion** | Per-variant cosmetic layer; not identity/stats/synergies |

## 4. In scope / out of scope

**In:** Completeness split default vs other; attach modes; pins/stale; soft coverage; equip/export readiness.

**Out:** Changing build identity without confirm/fork; treating tags as identity; soft misses as hard blocks on non-default save.

## 5. Success

| Signal | Ref |
|--------|-----|
| Default full loadout | `DAC-P1-003`, `DBR-CMPL-001` |
| Non-default gaps | `DAC-VAR-001`, `DBR-CMPL-002` |
| Wishlist vs equip-ready | `DAC-P1-005` |
| Artifact / fashion | `DAC-VAR-002`–`003` |

## 6. Canonical rules

| Layer | Prefixes / IDs |
|-------|----------------|
| DBR | `DBR-BLD-002`–`003`, `DBR-CMPL-*`, `DBR-CMP-*`, `DBR-ROLL-*`, `DBR-ART-*`, `DBR-FASH-*`, `DBR-GUID-*` |
| DAC | `DAC-P1-003`–`006`, `DAC-VAR-*` |
| BR | `BR-VAR-*`, `BR-ATT-*`, `BR-SAVE-*` (partial supersession) |

## 7. Related products

| Kind | Product |
|------|---------|
| Area | Primarily [Build area](../areas/build.md) (composer tabs) |
| Domain peers | [Build](./build.md), [Set](./set.md), [Synergy](./synergy.md) |

## 8. Open questions

- Equip-with-gaps confirmation UX depth for non-default  
- How many variants we encourage before fork  

## 9. Change log

| Date | Note |
|------|------|
| 2026-07-29 | Initial product description distilled from DBR/DAC |
