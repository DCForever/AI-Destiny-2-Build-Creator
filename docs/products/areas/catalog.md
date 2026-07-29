# Catalog — area product description

**Kind:** area
**Status:** draft
**Domain line:** Destiny 2 Build Creator  
**Updated:** 2026-07-29  
**Product-map area:** `catalog`  
**Nav / route:** `/catalog` (also embedded as set-fill / pick mode)

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | **Supporting** composition aid |
| **One-liner** | Browse and filter Destiny items (manifest + owned instances) to pick gear and inspect rolls—not a separate product job. |
| **Primary journey** | Shortens fill-slot and set curation; never replaces intent-first Build compose. |

---

## 2. Users & jobs

- **Primary job:** Find a catalog identity or owned copy that matches facet constraints (element, ammo, archetype, slot, class, exotic, text, exclude, group-by).
- **Secondary jobs:** Inspect weapon/armor detail (stats, perk grid, icons); pick into Sets/Build fill mode when constrained.
- **Not for:** Inventory organization as primary product; full DIM notes/tags/transfer; build identity editing.

---

## 3. In scope

- Weapons / armor (and related catalog surfaces) for signed-in and limited signed-out manifest browse
- Multi-facet include/exclude + group-by (`DBR-ROLL-010`)
- Owned instance listing with roll/perk resolution
- Item detail closer to DIM (stat bars, perk columns, icon density)
- Pick / constraint mode when embedded from Sets or Build

---

## 4. Out of scope / non-goals

- Catalog as the product’s primary job (`DBR-PUR-002`)
- Full boolean query language / Peggy as required for v1 (see `docs/catalog-filter-phases.md` later phases)
- Vault transfer, notes, tags parity with DIM product
- Synergy membership as sole browse dimension (optional later)

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| Facet browse | Multi-dimension filter works (`DAC-NME-003`) |
| Detail fidelity | Armor/weapon detail usable for set fill (`DAC-NME-004`) |
| Owned copies | User can distinguish and choose instances for pins |
| Embeddable | Slot-fill constraints lock catalog to the right domain |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | `DBR-ROLL-010`, `DBR-PUR-002`, display `DBR-ROLL-007`–`008`, `DBR-UI-*` |
| **DAC** | `DAC-NME-003`, `DAC-NME-004`, soft `DAC-DST-008` |
| **BR** | `BR-CAT-*` |
| **Key surfaces** | `catalog.*` weapons/armor filters, lists, detail, signed-out variants |
| **Key flows** | Catalog as fill aid from sets/build (map transitions) |

---

## 7. Presentation notes

**Strongest DIM North Star surface** after loadout chrome: icon-first grids, perk columns, stat bars. Prefer assets over text labels (`DBR-UI-005`). Screenshots under `docs/dim-reference-screenshots/` (weapon/exotic overviews, perk popup).

---

## 8. Open product questions

- Phase timing for Peggy / advanced query (`docs/catalog-filter-phases.md`)  
- Universal search depth vs type-scoped browse  

## 9. Related docs

- `docs/catalog-filter-phases.md` · domain rolls/catalog · polish tracker Catalog section  
