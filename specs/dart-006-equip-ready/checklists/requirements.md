# Requirements checklist: DART-006 Equip Ready

- [x] CHK001 Scope limited to pure equipReady / pin status (no equip write, no DIM payload)
- [x] CHK002 Wishlist cannot be equip-ready (FR-003, FR-007, SC-002)
- [x] CHK003 Stale rules: instance_missing + hash_mismatch (FR-004, FR-005)
- [x] CHK004 Empty combat gaps ignored; only applied slots (FR-002)
- [x] CHK005 Stable failure code NOT_EQUIP_READY documented
- [x] CHK006 Zero IO/UI domain deps preserved
- [x] CHK007 Exit criteria match roadmap row DART-006
