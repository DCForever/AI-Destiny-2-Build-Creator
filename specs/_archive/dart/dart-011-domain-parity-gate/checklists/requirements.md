# Requirements Checklist: DART-011 Domain Parity Gate

**Purpose**: Validate specification completeness for the P0 phase gate  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to aggregate pure suite + dep graph guard + P0 gate docs
- [x] CHK002 Out of scope excludes Drift/Flutter/Jaspr/network ports
- [x] CHK003 Depends on DART-003–010 called out

## Requirements coverage

- [x] CHK004 FR-001 single command full pure suite
- [x] CHK005 FR-002 non-zero exit on test failure
- [x] CHK006 FR-003 graph/dep guard for pure packages
- [x] CHK007 FR-004 forbidden IO/UI dep set
- [x] CHK008 FR-005 self-test for forbidden dep detection
- [x] CHK009 FR-006 non-interactive Melos/script entries
- [x] CHK010 FR-007 P0 gate documentation
- [x] CHK011 FR-008 no pure-package purity regressions

## Success criteria

- [x] CHK012 SC measurable (time, exit codes, docs, roadmap)
- [x] CHK013 Assumptions document pure package list and guard depth

## Notes

- Soft guidance never auto-applies; hard DBR blocks stay in existing evaluators only.
