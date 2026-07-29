# Shell — area product description

**Kind:** area
**Status:** draft
**Domain line:** Destiny 2 Build Creator  
**Updated:** 2026-07-29  
**Product-map area:** `shell`  
**Nav / route:** global chrome (`/*`)

---

## 1. Role in the product

| Field | Content |
|-------|---------|
| **Product role** | Platform / supporting chrome |
| **One-liner** | Stable app frame: navigation, auth control, theme, and signed-out gates so product areas share one trust model. |
| **Primary journey** | Does not compose builds; enables reach to every production surface and makes Bungie session state visible. |

---

## 2. Users & jobs

- **Primary job:** Move between Loadouts, Build, Synergy, Sets, Catalog, Settings without relearning chrome.
- **Secondary jobs:** See sign-in state; switch theme; hit signed-out gates with a clear path to Settings/auth.
- **Not for:** Feature content, inventory management, or debug tooling.

---

## 3. In scope

- Main nav labels and order (Loadouts · Build · Synergy · Sets · Catalog · Settings)
- Header chrome, theme toggle, Bungie auth control / session indicator
- Shared signed-out gate pattern for private areas
- Global presentation principles attached on `shell` (`DBR-UI-*`)

---

## 4. Out of scope / non-goals

- Feature-specific IA inside Build/Sets/etc. (owned by those areas)
- `/debug/*` power tools as primary nav
- Full DIM product chrome (vault grid as home, notes, tags)

---

## 5. Success (product-level)

| Signal | How we know |
|--------|-------------|
| Reachability | Signed-in user can open each primary production area in one nav hop |
| Auth clarity | Signed-out user sees gate + path to sign-in; no fake private data |
| Consistency | Areas share Matte Flap Ledger shell primitives |

---

## 6. Domain & structure links

| Kind | Refs |
|------|------|
| **DBR** | `DBR-PUR-*` (purpose on shell), `DBR-UI-001`–`005` (presentation North Star) |
| **BR** | `BR-AUTH-*` |
| **Key surfaces** | `shell`, `shell.nav.*`, `shell.auth.*`, `shell.signed-out-gate`, `shell.theme` |
| **Key flows** | Signed-out gates flow |

---

## 7. Presentation notes

Shell chrome stays **Matte Flap Ledger**. Destiny *data* elsewhere is DIM North Star + icon-first; shell itself is brand chrome, not a DIM clone.

---

## 8. Open product questions

- How far to promote debug / gap-scan tools into production nav (see `PRODUCT.md` open decisions)

## 9. Related docs

- [`PRODUCT.md`](../../PRODUCT.md) · [`docs/product-map/surfaces.yaml`](../product-map/surfaces.yaml) · [`src/components/ui/`](../../src/components/ui/)
