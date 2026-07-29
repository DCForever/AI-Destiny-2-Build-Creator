# Product descriptions

**Unified catalog** of product definitions for Destiny 2 Build Creator.

Each **Product Description** is a short, reviewable document you can change alongside peers—whether it is a **domain concept** (Set, Synergy) or a **UI area** (Build shell, Catalog).

Domain **rule IDs** (`DBR-*` / `DAC-*` / `BR-*`) stay the enforceable SSoT for behavior. Product descriptions own **intent, framing, and scope narrative**; when meaning changes, update **both** the description and the domain rules in the same change.

## Kinds

| Kind | Folder | What it is |
|------|--------|------------|
| **Domain product** | [`domains/`](./domains/) | A core concept/entity in the product model (Set, Synergy, Build, …) |
| **Area product** | [`areas/`](./areas/) | A user-facing place in the app (nav surface / workspace) |

Future kinds (same hub, new subfolders when needed): platform capabilities, multi-app domains, external integrations—keep the same catalog + template pattern.

## How layers fit

| Layer | Location | Owns |
|-------|----------|------|
| Whole product | [`PRODUCT.md`](../../PRODUCT.md) | Purpose, positioning, principles |
| **Product descriptions** | **this hub** | Reviewable intent/scope for domains + areas |
| Structure | [`docs/product-map/`](../product-map/) | Surfaces, flows, rule *attachments* |
| Rule wording | [`specs/domain-*.md`](../../specs/), [`business-rules.md`](../../specs/business-rules.md) | Enforceable `DBR`/`DAC`/`BR` text |
| Feature slices | `specs/00N-*/` | Implementation scope |

**Precedence:** Domain rules win on conflict with feature BRs and with prose in product descriptions. Fix the description if it drifts; do not implement against description-only fiction.

## Catalog — domain products

| Product | One-liner | Description |
|---------|-----------|-------------|
| [Build](./domains/build.md) | Equippable identity + variants | Core compose object |
| [Variant](./domains/variant.md) | Kit slice under a Build | Default vs non-default completeness |
| [Synergy](./domains/synergy.md) | Type + Object play-pattern | Intent library + evidence |
| [Set](./domains/set.md) | Typed reusable gear package | Normal composition unit |

Add new domain products under `domains/` when you promote a concept to first-class review (e.g. Roll/pin, Soft guidance, Fashion layer).

## Catalog — area products

| Product | Role | Description |
|---------|------|-------------|
| [Shell](./areas/shell.md) | Platform chrome | Nav, auth, gates |
| [Build area](./areas/build.md) | **Primary spine** | Intent → compose → equip UI |
| [Synergy area](./areas/synergy.md) | P2 library UI | Curate synergies |
| [Sets area](./areas/sets.md) | P2 library UI | Curate sets |
| [Catalog](./areas/catalog.md) | Supporting | Browse / fill aid |
| [Loadouts](./areas/loadouts.md) | Supporting | In-game loadout readout |
| [Settings](./areas/settings.md) | Platform | Auth, sync, manifest |

## Templates

| Kind | Template |
|------|----------|
| Domain | [`domains/_template.md`](./domains/_template.md) |
| Area | [`areas/_template.md`](./areas/_template.md) |

Keep descriptions ≈1–2 pages. Prefer links to rule prefixes over copying full rule tables.

## Domain vs area (same word, two products)

| Concept | Domain product | Area product |
|---------|----------------|--------------|
| **Set** | What a Set *is* (types, slots, attach semantics) | `/sets` library workspace |
| **Synergy** | What a Synergy *is* (type+object, required links) | `/synergy` library workspace |
| **Build** | What a Build *is* (identity, variants, class-bound) | `/build` composer + library UI |

Review both when changing meaning *or* the workspace that owns that concept.

## Same-change discipline

When a product description’s meaning changes:

1. Edit the description in this hub  
2. Update domain markdown (`DBR`/`DAC`/`BR`) if semantics changed  
3. Update product-map `rules:` / surfaces if structure or attachments changed → `npm run product-map:sync`  
4. Update `PRODUCT.md` if whole-product framing shifts  

Pure UI polish → [`docs/ui-polish-tracker.md`](../ui-polish-tracker.md).

## Other domains later

To add a second top-level domain (e.g. another game or product line):

1. Either nest under `docs/products/<domain-line>/…` **or** keep one catalog with a `domain_line:` field in each file front matter  
2. Prefer **one catalog index** (this README or a `catalog.yaml`) so review stays in one place  
3. Do not fork DBR/DAC IDs per platform—same rule atoms, multi-platform bindings stay in product-map  

v1 of this hub is the single Destiny 2 Build Creator line only.

## Legacy path

[`docs/product-areas/`](../product-areas/) redirects here; prefer `docs/products/`.
