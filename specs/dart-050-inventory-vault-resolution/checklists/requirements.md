# Requirements Checklist: DART-050 Inventory Vault Resolution

**Purpose**: Validate spec completeness and exit criteria before/during implementation  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Spec quality

- [x] CHK001 Scope boundary lists in-scope vs out-of-scope (no DART-051+ bleed)
- [x] CHK002 User stories prioritize vault storage (P1) over optional weapon stats (P3)
- [x] CHK003 Success criteria are parity-specific (vault copies stored), not “sync button works” (PROC-01)
- [x] CHK004 PROC-02 production wiring call sites named (Windows Settings, Windows equip, Jaspr equip)
- [x] CHK005 GAP-INV-06 residual → DART-053 documented
- [x] CHK006 Soft never auto-applies + no CLIENT_SECRET called out
- [x] CHK007 Intentional thinning requires GAP+RB (PROC-06)

## Exit criteria mapping

- [x] CHK008 `buildEquipmentBucketLookup` from DestinyInventoryItemDefinition exists + unit tests
- [x] CHK009 Entity/catalog slot fallback builder exists for non-raw hosts
- [x] CHK010 Windows Settings `syncNow` wires non-empty lookup
- [x] CHK011 Windows equip `syncIfStale` wires lookup
- [x] CHK012 Jaspr equip `syncIfStale` wires lookup
- [x] CHK013 Package tests assert `resolvedFromTransfer > 0` for vault fixtures with lookup
- [x] CHK014 Host vault fixtures fail without lookup / assert resolution
- [x] CHK015 Package docs stop treating empty lookup as production-OK
- [x] CHK016 GAP-INV-06 residual docs updated
- [x] CHK017 Optional GAP-INV-07 delivered or residual noted

## Finish-spec gate

- [x] CHK018 Finish-spec rejects “user can sync” alone
- [ ] CHK019 Roadmap row DART-050 → done; Current pointer advances
- [ ] CHK020 Merged to `feature/multiplatform-dart` only

## Notes

- Live Next tolerance harness is **DART-054**, not this slice
- Roll tags / sockets / diagnostics UI are later P6 slices
