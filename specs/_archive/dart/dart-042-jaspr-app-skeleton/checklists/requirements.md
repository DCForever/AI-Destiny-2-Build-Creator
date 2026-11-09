# Requirements Checklist: DART-042 Jaspr App Skeleton

**Purpose**: Validate specification completeness and exit criteria coverage  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Scope & exit criteria

- [x] CHK001 Exit “Hello Settings page” is specified as a user story with acceptance scenarios
- [x] CHK002 Exit “no Next dependency” is a functional requirement and acceptance check
- [x] CHK003 Goal “app shell + routing + design tokens (CSS)” covered by FR-001–004
- [x] CHK004 Out of scope lists DART-043+ (OPFS, OAuth, compose) without implementing them here
- [x] CHK005 Depends DART-011 / DART-013 noted; skeleton does not require DB at runtime

## Architecture alignment

- [x] CHK006 Web shell is Jaspr (not Flutter Web) per D-NOT-FLUTTER-WEB
- [x] CHK007 Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET
- [x] CHK008 Tokens shared via pure `destiny2_ui_tokens` (DART-029)
- [x] CHK009 Soft guidance never auto-applies

## Testability

- [x] CHK010 Automated tests required for Settings content + token CSS mapping
- [x] CHK011 Assumptions document client mode SPA defaults without NEEDS CLARIFICATION

## Notes

- Checklist written at specify; re-verify at finish-spec against implemented package.
