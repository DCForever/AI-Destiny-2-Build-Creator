# Contract: Equip Status Semantics

- Steps run in plan order; failure does not undo prior ok steps.
- `completed` = count ok; `failed` = count !ok.
- Empty fashion slots are not steps (leave-as-is).
- Missing artifact on resolved → no artifact step.
- Retry: client re-POSTs; planner re-reads inventory after optional sync.
