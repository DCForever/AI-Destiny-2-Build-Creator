# Domain Slice Roadmap — Build Composer

**Base branch**: `feature/overhall`  
**Canonical domain**: [domain-business-rules.md](./domain-business-rules.md), [domain-acceptance-criteria.md](./domain-acceptance-criteria.md)  
**Pipeline per slice**: specify → plan → tasks → implement → finish-spec  
**Clarify**: pause loop and run `/speckit-clarify` when the spec has underspecified gaps; wait for user answers before continuing.

| # | Status | Short name | Focus (DAC / DBR) | Notes |
|---|--------|------------|-------------------|-------|
| 1 | **done** | `build-identity` (`015`) | DAC-P1-002–003, DAC-VAR-004, DAC-NME-*, identity DBR | Merged to `feature/overhall` |
| 2 | **in_progress** | `wishlist-equip-ready` (`016`) | DAC-P1-005, DBR-ROLL-001–008, DBR-EQP-003 | Spec/plan/tasks done; implement next |
| 3 | pending | `soft-guidance` | DAC-P1-006, DBR-GUID-*, DBR-SYN-011, DBR-STAT-004 | Coverage indicators; soft only |
| 4 | pending | `artifacts-fashion` | DBR-ART-*, DBR-FASH-*, DAC artifact/fashion ACs | 6 artifacts per variant; fashion on variant for later equip |
| 5 | pending | `soft-stat-targets` | DBR-STAT-*, EoF six stats | Soft targets at build level; UI + validation soft |
| 6 | pending | `bungie-equip` | DAC-P1-007, DBR-EQP-* | Sync-on-equip, transfer, apply; best-effort partial |
| 7 | pending | `dim-export` | DAC-P1-008 | Export equip-ready variant to DIM |
| 8 | pending | `class-item-intent` | Exotic class-item intent-lock | Deferred from slice 1 |
| 9 | pending | `llm-propose` | LLM propose-for-confirm | Manual re-run; no auto-apply |

**Done when**: all rows are `done` and local `feature/overhall` contains each merge.

**Loop stop conditions**:
- No pending slices remain
- Clarify required (user must answer)
- Gate failure that cannot be fixed in the same turn
- User says stop
