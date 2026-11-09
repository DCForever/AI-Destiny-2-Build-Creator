# Requirements checklist: DART-005 Resolve Variant

- [x] CHK001 Scope limited to pure claim merge / conflict / completeness (no DB load)
- [x] CHK002 Out of scope lists loadExpandedAttachmentItems, equipReady, finishGaps, UI, IO
- [x] CHK003 Default vs non-default completeness rules specified (DBR-CMPL-001/002)
- [x] CHK004 Conflict detection parity (DBR-CMP-006, SLOT_CONFLICT)
- [x] CHK005 Stable failure codes documented (SLOT_CONFLICT, PAIR_ARMOR_MISMATCH, VARIANT_EMPTY, DEFAULT_VARIANT_INCOMPLETE)
- [x] CHK006 Zero IO/UI domain deps preserved
- [x] CHK007 Exit criteria match roadmap row DART-005
