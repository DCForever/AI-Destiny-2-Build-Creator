# Documentation map

One place to see **what is live**, **where it is authored**, and **what the doc site publishes**.

Curated site (local): `npm run docs:dev` → see [`../docs-site/README.md`](../docs-site/README.md).

## Layers (one job each)

| # | Layer | Author here | Do not use it for |
| --- | --- | --- | --- |
| 1 | **PRD / product intent** | Obsidian `Projects/Destiny 2 Build Creator/` (Domains, Areas, Destiny Objects). Junction: [`../requirements/`](../requirements/). Git pointer: [`products/README.md`](./products/README.md) | Enforceable IDs, tickets |
| 2 | **Domain law** | [`../specs/domain-business-rules.md`](../specs/domain-business-rules.md), [`domain-acceptance-criteria.md`](../specs/domain-acceptance-criteria.md), [`business-rules.md`](../specs/business-rules.md) | Product narrative, UI chrome |
| 3 | **Structure** | [`product-map/`](./product-map/) (YAML). Viewer: `npm run product-map:view` | Rule wording, PRDs |
| 4 | **This slice** | Vault `Features/` + Spec Kit **system only** (`specs/dart-NNN-*`) **or** [`ux-redesign/`](./ux-redesign/) for chrome | Replacing layers 1–2 |
| 5 | **Ops / architecture** | [`architecture/README.md`](./architecture/README.md) + living `multiplatform-dart-*.md` | Product law |
| — | **History** | [`../specs/_archive/`](../specs/_archive/), [`_archive/`](./_archive/) | New work |

**Precedence:** domain law wins on conflict with PRD prose and with feature BRs. When PRD **meaning** changes, update the vault note **and** law IDs in the same change. Vault→law **re-sync of the full packs is a gated follow-on** (product notes are still `draft`).

**Whole-product framing:** [`../PRODUCT.md`](../PRODUCT.md) (purpose, positioning). Visual language: [`../DESIGN.md`](../DESIGN.md). Agent operating rules: [`../AGENTS.md`](../AGENTS.md).

## Change requests

Read a page on the doc site → **Propose change**:

| Layer you are changing | File the CR |
| --- | --- |
| PRD / product intent | Vault note from `Templates/Change Request.md` (`CR-YYYYMMDD-###`) |
| Law, ops, map, this git doc | GitHub issue template **Docs change request** (`docs-cr`) |

Do **not** hand-edit generated `docs-site/src/content/docs/prd/` — change the Obsidian note and run `npm run docs:sync`.

## What agents should open

1. This file (or the doc site home).
2. Vault product notes for intent (if `requirements/` is mounted).
3. The three `specs/domain-*.md` / `business-rules.md` files for IDs.
4. `docs/product-map/` only when the UI place or flow changes.
5. Active UX brief or active Spec Kit folder — **not** `_archive/`.
