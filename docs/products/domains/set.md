# Set — domain product description

**Kind:** domain  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**ID slug:** `domain.set`

---

## 1. Definition

A **Set** is a **user-owned, typed package of gear (or cosmetics)** used as the normal unit of composition on a Build variant. Sets store **manifest item references** (and roll/pin data where applicable), not full item copies. Types: **Weapon, Armor, Mod, Pair, Fashion**.

## 2. Why it exists

Players reuse the same kits across variants and builds. Sets make composition **attachable and shareable within a private library** without rebuilding every slot from scratch, while still allowing per-variant overrides.

Primary journey: **compose** via set attach + optional slot pins (`DBR-CMP-001`–`002`). Secondary: **curate library** so compose gets faster (`DBR-PUR-003`–`005`).

## 3. Shape (product-level)

| Aspect | Description |
|--------|-------------|
| **Ownership** | Private per user; no sharing in initial scope |
| **Types** | Weapon · Armor · Mod · Pair · Fashion (distinct slot rules) |
| **Slots** | At most 0–1 item per domain slot; empty slots allowed; replace needs confirm |
| **Exotics** | Weapon/armor sets must stay attachable with ≤1 exotic weapon and ≤1 exotic armor across the set |
| **Mods** | Mod sets organized per armor piece; energy capacity enforced |
| **Attachments** | Attached to a **Variant** as live (default) or snapshot |
| **Tags** | Concept tags are filter metadata, not identity |
| **Deletion** | Blocked while attached to any build variant (`SET_IN_USE`) |

## 4. In scope / out of scope

**In:** Typed CRUD; slot cardinality; rolls/pins for set items; live/snapshot attach; fashion as non-combat layer; pair as exotic convenience.

**Out:** Set as build identity; fashion driving synergies/stats; dual-exotic kits; vault transfer product; auto-applying optimizer without confirm.

## 5. Success

| Signal | Ref |
|--------|-----|
| Sets attach into variants without unresolved conflicts | `DAC-P1-004`, `DBR-CMP-*` |
| Slot/exotic rules hold | `DAC-DST-*`, `BR-SLOT-*` |
| Library readiness bar includes sets | `DAC-P1-009` |
| In-flow create still works | `DAC-P2-005` |

## 6. Canonical rules

| Layer | Prefixes / IDs |
|-------|----------------|
| DBR | `DBR-CMP-*`, `DBR-MOD-*`, `DBR-FASH-*`, `DBR-ROLL-*` (item rolls/pins), `DBR-STAT-*` / board (armor sets), `DBR-SETB-*` |
| DAC | `DAC-P1-004`, `DAC-DST-*` (exotics/energy), `DAC-NME-004`, `DAC-P1-009`, `DAC-P2-005` |
| BR | `BR-SET-*`, `BR-SLOT-*`, `BR-ROLL-*`, `BR-DEL-*`, `BR-FASH-*`, `BR-PAIR-*`, `BR-ATT-*`, `BR-OPT-*` |

**Wording SSoT:** [`specs/domain-business-rules.md`](../../specs/domain-business-rules.md) §7+; Sets sections in [`business-rules.md`](../../specs/business-rules.md).

## 7. Related products

| Kind | Product |
|------|---------|
| Area | [Sets area](../areas/sets.md) (`/sets`) |
| Domain peers | [Variant](./variant.md) (attachment target), [Build](./build.md), [Synergy](./synergy.md) (coverage, not set identity) |

## 8. Open questions

- How far set-tag reverse discoverability (“synergized items”) goes as product vs polish  
- Pair set priority vs direct exotic pins on build/variant  

## 9. Change log

| Date | Note |
|------|------|
| 2026-07-29 | Initial product description distilled from DBR/BR |
