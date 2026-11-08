# Requirements Checklist: DART-051 Inventory Roll Tags

**Purpose**: Validate spec completeness and exit criteria before/during implementation  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Spec quality

- [x] CHK001 Scope boundary lists in-scope vs out-of-scope (no DART-052+ bleed)
- [x] CHK002 User stories prioritize pure parity + normalize over docs
- [x] CHK003 Success criteria are parity-specific (golden tags), not “sync button works” (PROC-01)
- [x] CHK004 Soft never auto-applies + no CLIENT_SECRET called out
- [x] CHK005 PROC-06 intentional thinning → GAP residual noted
- [x] CHK006 Assumptions document missing weapon-perks store + raw def fallback

## Exit criteria mapping

- [x] CHK007 `computeRollTags` pure port + golden tests match Next fixtures
- [x] CHK008 Sync normalize emits tags for crafted/champion/build samples with maps
- [x] CHK009 Production hosts wire enrichment inputs
- [x] CHK010 Package docs updated
- [x] CHK011 GAP-INV-02 closed or residual documented
- [x] CHK012 Soft never auto-applies; no CLIENT_SECRET

## Finish-spec gate

- [x] CHK013 Finish-spec rejects “sync works” alone
- [x] CHK014 Roadmap row DART-051 → done; Current pointer advances
- [x] CHK015 Merged to `feature/multiplatform-dart` only

## Notes

- Socket enrichment is **DART-052**
- Live harness is **DART-054**
