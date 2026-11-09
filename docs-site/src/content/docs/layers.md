---
title: Documentation layers
description: One job per layer — PRD, law, map, slice, ops, archive.
---

Canonical map in the repo: [`docs/README.md`](https://github.com/DCForever/AI-Destiny-2-Build-Creator/blob/main/docs/README.md).

| # | Layer | Author | This site |
| --- | --- | --- | --- |
| 1 | PRD / intent | Obsidian product notes | `/prd/…` (generated snapshot) |
| 2 | Domain law | `specs/domain-*.md`, `business-rules.md` | `/law/…` |
| 3 | Structure | `docs/product-map/` | Link only — use `npm run product-map:view` |
| 4 | This slice | Vault Feature + Spec Kit **or** `docs/ux-redesign/` | Not dumped here |
| 5 | Ops | `docs/architecture/` + living port docs | `/ops/…` |
| — | History | `specs/_archive/`, `docs/_archive/` | Hidden from nav |

**Precedence:** law wins on conflict. When a PRD meaning change is enforceable, update vault **and** law in the same change.
