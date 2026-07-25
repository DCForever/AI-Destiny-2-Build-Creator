# Requirements Checklist: DART-019 Flutter Windows Host Skeleton

**Purpose**: Validate spec completeness for the minimal Flutter Windows host  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Exit criteria limited to: app launches, single DB connection, Settings stub (manifest status), no OAuth
- [x] CHK002 Out of scope lists catalog, OAuth, inventory, design tokens, Jaspr/mobile
- [x] CHK003 Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET
- [x] CHK004 Soft guidance never auto-applies noted

## Requirements quality

- [x] CHK005 FR-001–FR-009 are testable and map to user stories
- [x] CHK006 Single DB connection defined (one AppDatabase lifetime owner)
- [x] CHK007 Manifest status fields named (cached, remote, isStale, entity cache)
- [x] CHK008 StorageRoot via path_provider (not repo `.cache`) required

## Assumptions

- [x] CHK009 App path `apps/windows_host`, package `destiny2_windows_host` documented
- [x] CHK010 Optional API key via dart-define; status works without key
- [x] CHK011 Full download refresh not required for exit (status only)

## Notes

- Checklist completed at specify time; implementation verifies SC-* via flutter test/build.
