# Destiny 2 Build Creator — Execution Plan

Living tracker for roadmap implementation. See `.cursor/plans/` for full spec.

## Phase status

| Phase | Status | Gate |
| --- | --- | --- |
| 0a Infrastructure blockers | Done | build + tests + OAuth + perk index |
| 0b Shared contracts | Done | SQLite repo tests |
| 1 Build core + UX | Done | zero illegal/slot issues on fixtures |
| 2 Platform (auth, loadouts) | Done | save/load loadout |
| 3 Inventory sync | Done | sync → DB → owned builds |
| 3.5 Multi-pass (optional) | Done | behind `LLM_MULTI_PASS_ENABLED` |
| 4 Post-build edit | Done | swap + re-resolve |

## Merge order

```text
0a → 0b → auth → loadouts → build tools → inventory → multi-pass → edit
```

## Gate command

```bash
npm run gate
```

## Traceability (requirement → phase)

| Requirement | Phase |
| --- | --- |
| Save/view loadouts | 2 |
| Default class | 2 |
| Subclass verbs/damage | 1 |
| Champion after weapons | 1 |
| Illegal perk auto-fix (visible) | 1 |
| LLM perk/slot tools | 1 |
| Bungie login anywhere | 2 |
| Full inventory SQLite | 3 |
| Roll tags | 3 |
| Inventory-aware generation | 3 |
| Multi-pass eval | 3.5 |
| Post-build edit | 4 |
