# Domain Slice Roadmap — Build Composer

**Base branch**: `feature/overhall`  
**Canonical domain**: [domain-business-rules.md](./domain-business-rules.md), [domain-acceptance-criteria.md](./domain-acceptance-criteria.md)  
**Pipeline per slice**: specify → plan → tasks → implement → finish-spec → **update Domain Slice Loop canvas**  
**Clarify**: pause loop and run `/speckit-clarify` when the spec has underspecified gaps; wait for user answers before continuing.

**Canvas**: `~/.cursor/projects/f-Destiny2BuildCreator/canvases/domain-slice-loop.canvas.tsx` — refresh status, phase, and current-slice callout at the end of every loop wake.

| # | Status | Short name | Focus (DAC / DBR) | Notes |
|---|--------|------------|-------------------|-------|
| 1 | **done** | `build-identity` (`015`) | DAC-P1-002–003, DAC-VAR-004, DAC-NME-*, identity DBR | Merged to `feature/overhall` |
| 2 | **done** | `wishlist-equip-ready` (`016`) | DAC-P1-005, DBR-ROLL-001–008, DBR-EQP-003 | Merged to `feature/overhall` |
| 3 | **done** | `soft-guidance` (`017`) | DAC-P1-006, DBR-GUID-*, DBR-SYN-011; set-bonus + element soft (no soft-stat UI) | Merged to `feature/overhall` |
| 4 | **done** | `artifacts-fashion` (`018`) | DBR-ART-*, DBR-FASH-*, DAC-VAR-002–003 | Merged to `feature/overhall` |
| 5 | **done** | `soft-stat-targets` (`019`) | DBR-STAT-*, EoF six stats | Merged to `feature/overhall` |
| 6 | **done** | `bungie-equip` (`020`) | DAC-P1-007, DBR-EQP-* | Merged to `feature/overhall` |
| 7 | **done** | `dim-export` (`021`) | DAC-P1-008 | Merged to `feature/overhall` |
| 8 | **done** | `class-item-intent` (`022`) | DAC-VAR-005, DBR-ID-005, DBR-ROLL-009 | Merged to `feature/overhall` |
| 9 | **in_progress** | `llm-propose` (`023`) | DAC-P2-004, DBR-LLM-* | Spec started; propose-for-confirm |

**Done when**: all rows are `done` and local `feature/overhall` contains each merge.

**Loop stop conditions**:
- No pending slices remain
- Clarify required (user must answer)
- Gate failure that cannot be fixed in the same turn
- User says stop
