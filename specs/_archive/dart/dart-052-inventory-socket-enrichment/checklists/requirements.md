# Requirements Checklist: DART-052 Inventory Socket Enrichment

**Purpose**: Validate spec completeness and exit criteria before/during implementation  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Spec quality

- [x] CHK001 Scope boundary lists in-scope vs out-of-scope (no DART-053+ bleed)
- [x] CHK002 User stories prioritize pure parity + normalize over docs
- [x] CHK003 Success criteria are parity-specific (columnKind/columnLabel + fixtures), not “sync button works” (PROC-01)
- [x] CHK004 Soft never auto-applies + no CLIENT_SECRET called out
- [x] CHK005 PROC-06 intentional thinning → GAP residual noted
- [x] CHK006 Assumptions document raw-def context + web residual

## Exit criteria mapping

- [x] CHK007 `classifyWeaponSocket` + `buildStoredSocketPlugs` pure port + golden tests
- [x] CHK008 Sync normalize emits plugs with columnKind/columnLabel when context provided
- [x] CHK009 Production hosts wire context builders when raw available
- [x] CHK010 Package docs updated
- [x] CHK011 GAP-INV-03 closed or residual documented
- [x] CHK012 Soft never auto-applies; no CLIENT_SECRET

## Finish-spec gate

- [x] CHK013 Finish-spec rejects “sync works” alone
- [x] CHK014 Roadmap row DART-052 → done; Current pointer advances to DART-053
- [x] CHK015 Merged to `feature/multiplatform-dart` only

## Notes

- Diagnostics UI is **DART-053**
- Live harness is **DART-054**
