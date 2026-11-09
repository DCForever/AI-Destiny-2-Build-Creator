# Requirements Checklist: DART-043 Jaspr OPFS SQLite

**Purpose**: Validate spec completeness for Drift WASM + OPFS single-writer  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 In scope limited to WASM/OPFS open + single-tab writer UX + docs
- [x] CHK002 Out of scope lists DART-044+ (bundles, OAuth, compose, import)
- [x] CHK003 No CLIENT_SECRET / no Node sidecar / no multi-writer Edge SQLite

## Exit criteria

- [x] CHK004 Second tab read-only **or** blocked (default blocked) is specified
- [x] CHK005 Documented limits required (OPFS, headers, fallbacks)
- [x] CHK006 Same Drift schema (AppDatabase) as desktop path

## Quality

- [x] CHK007 Assumptions A1–A8 avoid NEEDS CLARIFICATION
- [x] CHK008 Automated tests required for coordinator + Settings status
- [x] CHK009 Soft guidance never auto-applies restated
