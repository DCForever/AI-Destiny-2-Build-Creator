# Build — area product description

**Kind:** area  
**Status:** draft  
**Updated:** 2026-07-29  
**Domain line:** Destiny 2 Build Creator  
**Product-map area:** `build`  
**Nav / route:** `/build` (home)  
**Related domain products:** [Build](../domains/build.md), [Variant](../domains/variant.md)

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | **Primary product spine** |
| **One-liner** | Create and maintain class-bound Builds: designate intent, compose variants via sets/overrides, soft-guide quality, equip or export when equip-ready. |
| **Primary journey** | Owns **intent → compose → equip** end-to-end (with Settings for sync/auth, Catalog/Sets/Synergy as suppliers). |

---

## 2. Users & jobs

- **Primary job:** Leave a session with a stable Build identity and at least one coherent default combat loadout, with a path to equip/export.
- **Secondary jobs:** Manage variants; finish armor/weapons/mods; see soft coverage; pin owned instances; resolve conflicts/stale pins.
- **Not for:** Long-term vault organization (DIM), free-form inventory transfer UI, treating tags as build identity.

---

## 3. In scope

- Build library (list, filters, search, selection)
- Create draft → live identity (class, subclass tree, synergy types, optional exotic armor / shared exotic weapon / pinned Super)
- Default + additional variants; notes; naming
- Set attach (live/snapshot), slot overrides, finish walkthrough (slot-first; armor optimize path)
- Soft guidance / coverage; soft stat targets
- Wishlist desired rolls vs equip-ready pins; equip / DIM export entry when ready
- In-flow create of sets/synergies when library is thin

---

## 4. Out of scope / non-goals

- Cloning DIM Loadout Optimizer as the **compose** path (`DBR-UI-002`)
- Full Bungie transfer/vault product (equip may transfer as needed; not a vault app)
- Auto-applying optimizer or soft suggestions without confirm
- Making deep library a hard gate to start composing (`DBR-PUR-004`)

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| Intent | ≥1 synergy type to save (`DAC-P1-001`) |
| Identity | Synergies (+ optional identity fields) saved (`DAC-P1-002`) |
| Default complete | Full combat loadout on default (`DAC-P1-003`) |
| Compose | Sets/overrides without unresolved conflicts (`DAC-P1-004`) |
| Wishlist vs equip | Save without pins OK; equip/export gated (`DAC-P1-005`) |
| Soft guidance | Coverage visible; soft doesn’t block non-default save (`DAC-P1-006`) |
| Equip / DIM | Equip-ready path works (`DAC-P1-007`–`008`) |
| Library bar | Domain “P1 done” includes ≥10 synergies + ≥10 sets (`DAC-P1-009`) |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | `DBR-PUR-*`, `DBR-BLD-*`, `DBR-ID-*`, `DBR-NAME-*`, `DBR-SUB-*`, `DBR-SYN-*`, `DBR-CMP-*`, `DBR-CMPL-*`, `DBR-ROLL-*`, `DBR-GUID-*`, `DBR-STAT-*`, `DBR-EQP-*`, `DBR-ART-*`, `DBR-FASH-*` |
| **DAC** | `DAC-P1-*`, `DAC-VAR-*`, `DAC-DST-*` (constraints during compose) |
| **BR (feature)** | `BR-BLD-*`, `BR-SAVE-*`, `BR-ATT-*`, `BR-CONF-*`, finish/opt slices |
| **Key surfaces** | `build.library*`, `build.create*`, `build.edit.*`, finish/armor/weapon paths |
| **Key flows** | P1 journey; create draft→live; compose default variant; finish→equip/DIM; armor/weapon set paths |

---

## 7. Presentation notes

- **Compose workflow is product-owned** (not DIM LO).  
- **Readouts** of gear, perks, mods, stats should still feel DIM-familiar: dense, **icon-first** (`DBR-UI-001`, `DBR-UI-005`).  
- Refs: [`docs/dim-reference-screenshots/`](../dim-reference-screenshots/).

---

## 8. Open product questions

- Shareable read-only build links (planned, UX undecided)  
- How much finish chrome stays production vs advanced Sets tab only  

## 9. Related docs

- [`PRODUCT.md`](../../PRODUCT.md) · domain DBR/DAC · `specs/028`–`031` finish/optimizer · ui-mocks under `docs/ui-mocks/`
