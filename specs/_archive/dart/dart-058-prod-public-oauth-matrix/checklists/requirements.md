# Requirements checklist: DART-058

- [x] CHK001 Scope limited to prod Public redirect matrix, secret scan, smoke docs, RC-AUTH/RB-03 (not DART-059 entity CDN, not DART-060 dual-run, not full mobile OAuth session UI)
- [x] CHK002 Windows HTTPS loopback exact URI published
- [x] CHK003 Jaspr `/auth/callback` under prod origin published
- [x] CHK004 Mobile schemes published for portal registration
- [x] CHK005 Zero CLIENT_SECRET / SESSION_SECRET in client artifacts (scan gate)
- [x] CHK006 Soft never auto-applies; no Node sidecar
- [x] CHK007 Exit criteria parity-specific (matrix strings + scan + RC-AUTH), not only “button works”
- [x] CHK008 Assumptions documented (A1–A7); no retained NEEDS CLARIFICATION
