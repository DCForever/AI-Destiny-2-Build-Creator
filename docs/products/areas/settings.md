# Settings — area product description

**Kind:** area
**Status:** draft
**Domain line:** Destiny 2 Build Creator  
**Updated:** 2026-07-29  
**Product-map area:** `settings`  
**Nav / route:** `/settings`

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | **Platform** |
| **One-liner** | Establish trust with Bungie: sign-in, inventory sync, and manifest refresh so compose/equip have real data. |
| **Primary journey** | Prerequisite for owned pins, equip, and accurate catalog/owned browse—not a daily “feature” surface. |

---

## 2. Users & jobs

- **Primary job:** Sign in with Bungie; keep inventory and manifest fresh enough for pins and equip.
- **Secondary jobs:** See membership/status; sign out; understand rate limits / last sync.
- **Not for:** Build editing, synergy curation, or optional LLM config as the center of the product.

---

## 3. In scope

- Signed-out and signed-in Settings
- OAuth sign-in / sign-out / session status
- Inventory sync card (action, progress, last updated, rate-limit honesty)
- Manifest refresh and version/status display
- Operator-facing clarity when keys/env are missing (without leaking secrets)

---

## 4. Out of scope / non-goals

- Multi-tenant account admin / cloud billing  
- Full DIM sync product features  
- Hiding the need for local single-process SQLite constraints  
- Turning Settings into a second home for compose  

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| Auth | User can complete OAuth and see signed-in status |
| Inventory | Sync populates owned instances for pins/equip |
| Manifest | Refresh unlocks catalog/composition entity stores |
| Honesty | Rate limits and failures are visible, not silent |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | `DBR-EQP-007` (refresh on equip / rate limit), ownership pins, local-first constraints in PRODUCT |
| **BR** | `BR-AUTH-*`, inventory/manifest feature BRs |
| **Key surfaces** | `settings.signed-out`, `settings.signed-in`, inventory-sync, manifest cards |
| **Key flows** | Signed-out settings; first-run path in README |

---

## 7. Presentation notes

Operator clarity over marketing. Status cards; no need for DIM item density here. Matte Flap Ledger forms/panels.

---

## 8. Open product questions

- How much optional LLM/SearXNG configuration belongs in production Settings vs docs/env only  
- Accessibility formal target (open in PRODUCT)  

## 9. Related docs

- `README.md` Getting started · `DEBUG.md` · env example · durable constraints in `PRODUCT.md`  
