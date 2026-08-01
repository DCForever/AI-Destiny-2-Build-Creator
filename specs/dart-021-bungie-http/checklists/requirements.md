# Requirements Checklist: DART-021 Bungie HTTP

**Purpose**: Validate specification completeness for shared Bungie HTTP client  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to shared HTTP client: API key header, errors, rate-limit hooks, mocked tests
- [x] CHK002 Out of scope excludes OAuth, profile sync, equip, Flutter UI, manifest download migration
- [x] CHK003 Depends on DART-011; pure packages stay pure (bungie is not pure)

## Requirements coverage

- [x] CHK004 FR-001 new workspace package destiny2_bungie
- [x] CHK005 FR-002 X-API-Key on every request
- [x] CHK006 FR-003 optional Bearer token
- [x] CHK007 FR-004 GET/POST unwrap ErrorCode==1 Response
- [x] CHK008 FR-005 typed HTTP + platform errors
- [x] CHK009 FR-006 rate-limit hooks / throttle metadata
- [x] CHK010 FR-007 injectable transport + mock tests
- [x] CHK011 FR-008 no CLIENT_SECRET / no hard-coded secrets
- [x] CHK012 FR-009 domain purity preserved
- [x] CHK013 FR-010 soft never auto-applies

## Success criteria

- [x] CHK014 SC unit tests mocked HTTP; headers/errors/hooks proven; workspace + pure guard

## Notes

- Soft guidance never auto-applies; hard DBR blocks remain in domain evaluators only.
- Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET in clients.
