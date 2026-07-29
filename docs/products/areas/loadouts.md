# Loadouts — area product description

**Kind:** area
**Status:** draft
**Domain line:** Destiny 2 Build Creator  
**Updated:** 2026-07-29  
**Product-map area:** `loadouts`  
**Nav / route:** `/loadouts` (in-game loadouts)

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | **Supporting** readout / bridge to in-game state |
| **One-liner** | Show Bungie in-game loadouts with real icons/colors and filters so players relate game slots to app Builds—not a second composer. |
| **Primary journey** | Supports equip understanding and exotic/context discovery; compose stays on Build. |

---

## 2. Users & jobs

- **Primary job:** See what is currently (or recently) represented as in-game loadouts for the account.
- **Secondary jobs:** Filter by exotic / slot type; expand slot detail; spot linked Builds when hashes match.
- **Not for:** Primary build creation; DIM LO replacement; full equip sheet editor as polish-perfect Bungie parity.

---

## 3. In scope

- Signed-in loadout list with icon/color presentation
- Filters (exotic, exact item, slot-type as product already exposes)
- Slot expanded detail
- Linked build labels when match rules exist
- Signed-out empty / gate messaging

---

## 4. Out of scope / non-goals

- Becoming the intent-first composer  
- Full equip/sheet import depth as unbounded polish (`ui-polish-tracker` deferred)  
- Full DIM notes/tags/transfer product  
- Replacing Settings inventory sync  

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| Truthful list | Loadouts reflect Bungie data with real presentation |
| Orientation | User can open a loadout and understand slots/exotics |
| Bridge | Related Builds surface when identity match exists |
| Clarity | Signed-out state doesn’t fake private data |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | Supporting to `DBR-EQP-*`, `DBR-PUR-002`; presentation `DBR-UI-*` |
| **DAC** | Indirect via equip readiness elsewhere; no dedicated DAC pack yet |
| **BR** | Loadout exotic filter / feature BRs from 002 where applicable |
| **Key surfaces** | `loadouts.*`, filters, row, slot-expanded |
| **Key flows** | Signed-out loadouts empty; production nav entry |

---

## 7. Presentation notes

High DIM alignment for **loadout chrome and slot icons**. Icon-first strips; text secondary. Do not pull compose UX into this list.

---

## 8. Open product questions

- How deep equip-from-sheet / import goes vs stay on Build equip  
- Whether loadout→build create shortcuts are product goals  

## 9. Related docs

- Feature 002 exotic loadouts · polish Loadouts section · Bungie component presentation  
