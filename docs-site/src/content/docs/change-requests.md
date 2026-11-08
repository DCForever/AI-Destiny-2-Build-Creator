---
title: Change requests
description: How to propose a modification from this site into the vault or git.
---

1. Read the page.
2. Quote the current text.
3. Write the proposed replacement and why.
4. File the CR on the **correct layer**:

| Layer | File as |
| --- | --- |
| PRD / product intent | Obsidian `Change Requests/CR-YYYYMMDD-###` from `Templates/Change Request` |
| Law, map, ops, git docs | GitHub issue **Docs change request** (`docs-cr`) |

Every page footer has **Propose a change (GitHub)**. For PRDs, still create the vault note — GitHub is the optional pointer.

**Do not** edit `docs-site/src/content/docs/prd/` by hand. Change the Obsidian note, then `npm run docs:sync`.

Apply path:

- PRD → vault note → `docs:sync` → if meaning is enforceable, same-change `DBR`/`DAC`/`BR`.
- Law → edit `specs/` → product-map attachments if IDs moved → site sync.
- UX → `docs/ux-redesign/` brief, not Spec Kit (D-LANES).
