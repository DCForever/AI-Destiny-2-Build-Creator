# Requirements checklist: DART-037 equip-orchestrator

## Scope

- [x] planEquipSteps pure planner (transfer → equip → artifact → fashion)
- [x] BungieWriteClient + HTTP + mock
- [x] executeEquipPlan best-effort partial (no rollback)
- [x] Tests with mocked write API
- [x] Out of scope: Flutter equip UI (DART-038), DIM UI, CLIENT_SECRET, soft auto-apply

## Functional

- [x] FR-001 planEquipSteps export
- [x] FR-002 vault hop / vault pull / skip transfer rules
- [x] FR-003 NOT_EQUIP_READY on missing combat instance
- [x] FR-004 write client interface + mock
- [x] FR-005 HTTP POST Platform paths, no secret
- [x] FR-006 execute order + continue on failure
- [x] FR-007 EquipStatus counts
- [x] FR-008 unit tests plan + execute partial
- [x] FR-009 no soft auto-apply / no local save mutation

## Assumptions documented

- [x] A1–A8 in spec.md
