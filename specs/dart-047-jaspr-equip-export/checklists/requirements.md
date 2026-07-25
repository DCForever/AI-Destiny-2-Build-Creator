# Requirements checklist: DART-047

- [x] Scope limited to Jaspr equip-ready + DIM json + optional equip on web
- [x] Exit: same domain packages as Flutter
- [x] Soft never auto-applies; hard equip-ready blocks stay hard
- [x] Pure Dart I/O; no CLIENT_SECRET; no Node sidecar; no dim.gg
- [x] DIM blocked when not equip-ready
- [x] Optional equip uses DART-037 plan/execute with mockable write client
- [x] Tests with memory DB; no live Bungie required
- [x] Integration base feature/multiplatform-dart only
