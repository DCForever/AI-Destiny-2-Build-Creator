# Product descriptions

**Working copy is in Obsidian (ProjectTracker), not this folder.**

| | |
| --- | --- |
| Vault | `ProjectTracker` |
| Catalog | `Projects/Destiny 2 Build Creator/Products.md` |
| Domains | `Projects/Destiny 2 Build Creator/Domains/` |
| Areas | `Projects/Destiny 2 Build Creator/Areas/` |
| Open in Obsidian | Project note [[Destiny 2 Build Creator]] → [[Products]] |

## What lives where

| Layer | Location | Owns |
| --- | --- | --- |
| **Product descriptions** | **Obsidian** (path above) | Intent, framing, scope narrative for domains + areas |
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

Do **not** re-create full product description bodies under `docs/products/domains/` or `docs/products/areas/`. Edit the vault notes instead. Keep this README as the git-side pointer and catalog index.

Legacy: [`docs/product-areas/`](../product-areas/) also points here.
