# Build — domain product description

**Kind:** domain  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**ID slug:** `domain.build`

---

## 1. Definition

A **Build** is both a **fully equippable loadout identity** and a **stable product object with variants**. It is **class-bound** (Titan / Hunter / Warlock). **Primary identity** is designated synergies (types), plus optional identity fields (exotic armor item, build-shared exotic weapon, build-pinned Super). Character is chosen at equip time, not as build identity.

## 2. Why it exists

Players need a durable “same kit family” across activities and rolls—not a one-shot loadout randomizer. Build is the spine of **intent → compose → equip**.

## 3. Shape (product-level)

| Aspect | Description |
|--------|-------------|
| **Ownership** | Private per user; shareable links planned later |
| **Class** | Bound to one Destiny class |
| **Variants** | Exactly one **default** + optional others ([Variant](./variant.md)) |
| **Identity** | Designated synergy types; optional exotic armor hash; optional build-shared exotic weapon; optional build-pinned Super |
| **Not identity** | Concept tags; most gear/mods/fashion/artifact; non-pinned abilities |
| **Identity change** | Confirm in-place (all variants) or fork |
| **Naming** | Derived default name; rename unique per class per user |
| **Subclass tree** | Shared element/tree across variants |
| **Notes** | Free-form on build/variant; not identity |

## 4. In scope / out of scope

**In:** Identity model; multi-variant; set attach + overrides; soft guidance; wishlist vs equip-ready; equip/DIM gates.

**Out:** Tags as identity; inventory-first product; DIM LO as required compose path; multi-tenant sharing as v1 requirement.

## 5. Success

| Signal | Ref |
|--------|-----|
| Intent ≥1 synergy type | `DAC-P1-001` |
| Identity established | `DAC-P1-002` |
| Default full combat loadout | `DAC-P1-003` |
| Compose via sets/overrides | `DAC-P1-004` |
| Wishlist save; equip gated | `DAC-P1-005` |
| Soft guidance visible | `DAC-P1-006` |
| Equip / DIM when ready | `DAC-P1-007`–`008` |

## 6. Canonical rules

| Layer | Prefixes / IDs |
|-------|----------------|
| DBR | `DBR-BLD-*`, `DBR-ID-*`, `DBR-NAME-*`, `DBR-SUB-*`, `DBR-SYN-*` (designation), `DBR-CMPL-*`, `DBR-EQP-*`, … |
| DAC | `DAC-P1-*`, `DAC-VAR-*` |
| BR | `BR-BLD-*`, `BR-SAVE-*`, `BR-VAR-*`, … |

**Wording SSoT:** [`specs/domain-business-rules.md`](../../specs/domain-business-rules.md) §2–5+.

## 7. Related products

| Kind | Product |
|------|---------|
| Area | [Build area](../areas/build.md) (`/build`) |
| Domain peers | [Variant](./variant.md), [Synergy](./synergy.md), [Set](./set.md) |

## 8. Open questions

- Shareable read-only build links scope/UX  
- Build-shared exotic weapon defaults vs always variant-level  

## 9. Change log

| Date | Note |
|------|------|
| 2026-07-29 | Initial product description distilled from DBR/DAC |
