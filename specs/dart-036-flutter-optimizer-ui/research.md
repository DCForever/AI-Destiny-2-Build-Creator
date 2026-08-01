# Research: DART-036 Flutter Optimizer UI

**Date**: 2026-07-24  
**Slice**: DART-036

## Decisions

### R1 — Workspace placement

**Decision**: Embed Armor optimizer on **Sets library detail** when selected set type is `armor` (not a new nav rail item).  
**Rationale**: Roadmap depends on DART-030; apply-in-place targets an armor set id; matches product “constrained armor set” re-optimize path.  
**Alternatives**: Builds/Finish path only — deferred; can deep-link later without blocking confirm-only exit criteria.

### R2 — Confirm-only UX

**Decision**: After Find kits, suggestions are display-only. Apply / Materialize open a **confirm dialog**; cancel leaves DB unchanged; only confirm calls DART-035 use cases.  
**Rationale**: Exit criterion “Suggest → user confirm; never silent apply”; aligns with soft-guidance never auto-apply and port decisions.

### R3 — Candidates

**Decision**: Controller accepts **injected candidates** (tests) and a default **inventory map** path (bucket → slot + optional catalog). Full inventory projection polish is out of scope.  
**Rationale**: DART-035 injects candidates; UI must still work offline with fixtures.

### R4 — Optimize runner

**Decision**: Default `optimizeArmorInIsolate`; tests may inject `optimizeArmorLocal` for determinism/speed.  
**Rationale**: UI-thread safety from DART-035; local path for widget tests under flutter_tester.

### R5 — Soft goals

**Decision**: Soft thresholds and preferReuse are draft goals for the next Find kits only; they never write set items.  
**Rationale**: DBR-GUID / soft never auto-applies.

## References

- `packages/app/lib/src/optimizer_isolate.dart`
- `packages/app/lib/src/optimizer_use_cases.dart`
- Product `specs/031-finish-armor-optimize-ui/spec.md` (goals / top-3 / apply)
- `docs/multiplatform-dart-port-decisions.md` (soft never auto-applies)
