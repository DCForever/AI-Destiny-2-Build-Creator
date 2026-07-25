# Requirements checklist: DART-041

- [x] Scope limited to mobile reduced-density compose (create → attach → soft)
- [x] Soft never auto-applies; hard DBR blocks stay hard
- [x] Pure Dart I/O; no CLIENT_SECRET; no Node sidecar
- [x] Focus Swap retained (list XOR detail)
- [x] Sheets for create/attach; linear detail sections
- [x] Exit criteria: create build → attach → soft guidance on device; P4 phase gate
- [x] No later slices (OAuth, equip, catalog, Jaspr) in this branch
- [x] Assumptions documented; no NEEDS CLARIFICATION retained
