# Sets — area product description

**Kind:** area  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**Product-map area:** `sets`  
**Nav / route:** `/sets`  
**Related domain product:** [Set](../domains/set.md)

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | **P2 library** — normal composition unit for Builds |
| **One-liner** | Create and maintain typed Sets (Weapon, Armor, Mod, Pair, Fashion) with slot rules so variants attach reusable kits. |
| **Primary journey** | Attach/live-link into Build compose; fill slots from Catalog/owned; in-flow create from Build still valid. |

---

## 2. Users & jobs

- **Primary job:** Curate reusable packages of gear/mods/fashion that stay attachable without dual-exotic or illegal kits.
- **Secondary jobs:** Fill empty slots; pin owned instances for rolls/stats; see used-by builds; armor base-roll board stats.
- **Not for:** Full loadout identity (that’s Build); vault management; fashion driving synergies/stats.

---

## 3. In scope

- Sets library by type; name uniqueness per type; concept tags (filter metadata)
- Slot cardinality per type; empty slots allowed; replace-with-confirm
- Weapon full roll data; armor instance pins for base-roll stats display
- Mod sets per armor piece + energy capacity
- Pair sets for exotic combos; fashion sets (cosmetic layer only for combat resolve)
- Delete blocked when in use (`SET_IN_USE`)
- Fill-slot pickers constrained by set type / slot

---

## 4. Out of scope / non-goals

- Sets as build identity (identity lives on Build + designated synergies)
- Fashion participating in synergies/suggestions/stats (`DBR-FASH-*`)
- Auto-applying optimizer results without confirm
- Dual exotic weapon/armor in a single attachable kit (`DBR-CMP-007` / set exotic exclusivity)

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| CRUD + types | User can create/edit each set type with valid slots |
| Attachable | Weapon/armor sets respect single-exotic rules |
| Compose aid | Sets attach live to variants without unresolved conflicts |
| Library bar | ≥10 sets spanning weapon/armor/mod (`DAC-P1-009`) |
| In-flow | Create/attach from Build finish path still works (`DAC-P2-005`) |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | `DBR-CMP-*`, `DBR-MOD-*`, `DBR-ROLL-*` (partial), `DBR-FASH-*`, `DBR-STAT-*` / set board, `DBR-SETB-*` |
| **DAC** | `DAC-P1-004`, `DAC-DST-*` (exotics, energy), `DAC-NME-004` (armor detail) |
| **BR** | `BR-SET-*`, `BR-SLOT-*`, `BR-ROLL-*`, `BR-DEL-*`, `BR-FASH-*`, `BR-PAIR-*`, `BR-OPT-*` |
| **Key surfaces** | `sets.library*`, `sets.create*`, `sets.detail*`, `sets.edit`, fill-slot |
| **Key flows** | P2 sets library; armor/weapon set reuse/create/improve from Build |

---

## 7. Presentation notes

Item rows and perk grids: DIM-style density, **icons over text** for items/perks/mods. Armor set board uses base-roll stats (not live modded totals) per domain.

---

## 8. Open product questions

- Synergized-items reverse discoverability on set tags (polish tracker open item)  
- How aggressive “encourage mods” empty-state UX is  

## 9. Related docs

- Domain composition / mods / fashion · finish armor optimize specs 026/030/031  
