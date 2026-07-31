# Finish-spec thinning checklist (PROC-06)

**Status:** enforced  
**Updated:** 2026-07-30  
**Closes:** [PROC-06](./multiplatform-dart-feature-gaps.md#process-gaps-why-p0-inventory-issues-shipped) in the feature-gap process table  

## Purpose

Any DART (or product) slice that **intentionally thins** product behavior vs Next / domain SSoT **must** open or update residual trackers **in the same change** as the merge/finish. Silent “MVP ok” without a GAP/RB residual is a process failure (PROC-06).

Offline gate:

```bash
dart run tool/proc06_thinning_gate.dart
```

## When this applies

Run this checklist during **finish-spec** (and before claiming a slice `done`) if any of the following are true:

- A production path deliberately drops, degrades, or skips product behavior documented in DBR/DAC/BR or Next parity
- Host residual is left thinner than pure domain (web without raw defs, mobile N/A, etc.)
- Docs say “MVP”, “residual”, “thinner”, or “not ported” for intentional scope cuts
- A FEAT inventory row would otherwise claim full parity while a GAP residual remains

## Checklist (same change as finish-spec)

Copy into the finish-spec PR/commit description or agent report:

```
PROC-06 thinning:
- [ ] Identified intentional thinning (or N/A — full product parity, no residual)
- [ ] Updated or opened GAP-* row in docs/multiplatform-dart-feature-gaps.md (and/or ui-fidelity GAP-UI-*)
- [ ] Residual note states what is thinner, which shells, and that soft never auto-applies
- [ ] Cutover RB-* residual updated only if cutover trust is affected (most fidelity thinning is not)
- [ ] FEAT inventory Plan/status does not contradict master GAP closed + residual language
- [ ] Soft guidance never auto-applies; no CLIENT_SECRET in clients
```

### Markers (do not remove — offline gate)

The following markers must remain in this document for `tool/proc06_thinning_gate.dart`:

PROC-06-THINNING-CHECKLIST  
INTENTIONAL-THINNING-SAME-CHANGE  
GAP-RESIDUAL-REQUIRED  
SOFT-NEVER-AUTO-APPLIES  
NO-SILENT-MVP-OK

## Agent / finish-spec enforcement

1. **finish-spec skill** (`.cursor/skills/finish-spec/SKILL.md`) requires this checklist before merge when thinning is present.  
2. **Slice roadmap** end-of-finish-spec checklist includes PROC-06.  
3. **Offline gate** `dart run tool/proc06_thinning_gate.dart` verifies this doc + skill + feature-gaps PROC-06 closed language.  

## Soft never auto-applies (PRODUCT / DBR-GUID)

Soft coverage, soft-stat nudges, better-kit banners, and optimizer suggestions are **confirm-only**. Finish-spec must not ship auto-apply of soft guidance. Restated on every inventory residual note where soft paths touch the change.

## Related

| Doc | Role |
| --- | ---- |
| [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) | FEAT inventory + PROC-06 row |
| [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md) | finish-spec update checklist |
| [multiplatform-dart-ui-fidelity.md](./multiplatform-dart-ui-fidelity.md) | GAP-UI residual presentation |
| `.cursor/skills/finish-spec/SKILL.md` | Land Spec Kit branch workflow |
