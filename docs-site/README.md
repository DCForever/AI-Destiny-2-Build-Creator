# Curated doc site

Starlight site for **reading, reviewing, and proposing change requests**.

First install: `cd docs-site && npm install` (once). Then from monorepo root:

| Command | Effect |
| --- | --- |
| `npm run docs:sync` | Snapshot Obsidian PRDs + law + selected ops into `src/content/docs/` |
| `npm run docs:dev` | Sync then serve (`http://127.0.0.1:4321`) |
| `npm run docs:build` | Sync then production build |

## Sources

| Site section | Source of truth | Generated? |
| --- | --- | --- |
| `/prd/…` | Obsidian `Projects/Destiny 2 Build Creator/` via `requirements/` junction | Yes — do not hand-edit |
| `/law/…` | `specs/domain-*.md`, `business-rules.md` | Yes |
| `/product/…` | `PRODUCT.md` | Yes |
| `/ops/…` | `docs/README.md`, `docs/architecture/README.md` | Yes |
| Home / layers / CRs | files in this package | Hand-authored |

If the vault junction is missing, PRD sync is skipped and the last committed snapshot (if any) remains.

## Change requests

Footer **Propose a change** opens a GitHub `docs-cr` issue. PRD meaning also gets a vault `CR-YYYYMMDD-###`. See [Change requests](./src/content/docs/change-requests.md).
