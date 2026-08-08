# Product descriptions (high-level requirements)

**Working copy is in Obsidian (ProjectTracker), not duplicated in git.**

## Local soft link (preferred agent path)

| | |
| --- | --- |
| Mount | [`requirements/`](../../requirements/) → vault root |
| Recreate | `pwsh -File scripts/link-projecttracker-requirements.ps1` |
| Vault absolute | `C:\Users\Owner\SyncThing\Obsidian\ProjectTracker` |
| **High-level product requirements** | **`requirements/Projects/Destiny 2 Build Creator/`** |

| Vault path (via mount) | Content |
| --- | --- |
| `requirements/Projects/Destiny 2 Build Creator/Products.md` | Catalog index (domains + areas + Destiny objects) |
| `requirements/Projects/Destiny 2 Build Creator/Domains/` | Domain product descriptions (Build, Variant, Set, Synergy, …) |
| `requirements/Projects/Destiny 2 Build Creator/Areas/` | Area product descriptions (Shell, Build, Catalog, …) |
| `requirements/Projects/Destiny 2 Build Creator/Destiny Objects/` | Game entity presentation / domain use |
| `requirements/Projects/Destiny 2 Build Creator/UX/` | Area UX boards + redesign path narrative |
| `requirements/Projects/Destiny 2 Build Creator.md` | Project note (purpose, success criteria, status) |

**Flutter UX redesign sequence (repo SSoT):** [`docs/ux-redesign/REDESIGN-PATH.md`](../ux-redesign/REDESIGN-PATH.md) — vault mirror `UX/UX Redesign Path.md`.

`requirements/` is a **machine-local junction** (gitignored). If missing, run the link script or open the absolute vault path above.

Open in Obsidian: vault `ProjectTracker` → project [[Destiny 2 Build Creator]] → [[Products]].

## What lives where

| Layer | Location | Owns |
| --- | --- | --- |
| **High-level product requirements** | **Obsidian** `Projects/Destiny 2 Build Creator/` (via `requirements/`) | Intent, framing, scope narrative for domains + areas + Destiny objects |
| Whole product | [`PRODUCT.md`](../../PRODUCT.md) | Purpose, positioning, principles |
| Structure | [`docs/product-map/`](../product-map/) | Surfaces, flows, rule *attachments* |
| Rule wording | [`specs/domain-*.md`](../../specs/), [`business-rules.md`](../../specs/business-rules.md) | Enforceable `DBR` / `DAC` / `BR` text |
| Feature slices | `specs/00N-*/` | Implementation scope |

**Precedence:** Domain rules in `specs/` win on conflict. Product prose is edited in the vault; when meaning changes, update **vault description and** domain rules in the same change.

## Catalog (index only — full text in vault)

### Domain products

| Product | One-liner | Vault note |
| --- | --- | --- |
| Build | Equippable identity + variants | `Domain Build` |
| Variant | Kit slice under a Build | `Domain Variant` |
| Synergy | Type + Object play-pattern | `Domain Synergy` |
| Set | Typed reusable gear package (≥2 items weapon/armor; mod multi-piece) | `Domain Set` |

### Area products

| Product | Role | Vault note |
| --- | --- | --- |
| Shell | Platform chrome | `Area Shell` |
| Build area | Primary spine | `Area Build` |
| Synergy area | P2 library UI | `Area Synergy` |
| Sets area | P2 library UI | `Area Sets` |
| Catalog | Supporting | `Area Catalog` |
| Loadouts | Supporting | `Area Loadouts` |
| Settings | Platform | `Area Settings` |

## Agent / contributor note

1. Prefer reading **`requirements/Projects/Destiny 2 Build Creator/`** for high-level product requirements.
2. Do **not** re-create full product description bodies under `docs/products/domains/` or `docs/products/areas/`.
3. Keep this README as the git-side pointer and catalog index.
4. Enforceable rule IDs still live in `specs/` after re-sync.

Legacy: [`docs/product-areas/`](../product-areas/) also points here.
