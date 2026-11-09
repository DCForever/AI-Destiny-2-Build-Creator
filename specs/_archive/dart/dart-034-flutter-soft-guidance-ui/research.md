# Research: DART-034 Flutter Soft Guidance UI

**Date**: 2026-07-24  
**Slice**: DART-034

## Decisions

### R1 — Soft section on Builds detail (after compose)

Reuse DART-033 compose surface. Soft guidance is read-mostly display under attachments/pins so the P3 spine is one pane: identity → variants → attach → soft chips/targets.

### R2 — Query via `queryVariantCoverage`

DART-028 already loads designated synergies, resolves claims, calls pure `evaluateCoverage`. Host does not reimplement matching. Optional maps (`setBonusByItemHash`, `weaponElementByHash`, `statEstimate`) default empty/null offline — synergy tiers still work from claims + library synergies.

### R3 — Soft stat targets = explicit build update only

Targets live on the build row. UI draft → `updateUserBuild(..., softStatTargets: ...)`. No `targetsFromAcceptedNudges` auto path; nudges remain domain-only helpers for later UX.

### R4 — Soft never auto-applies

Coverage refresh is side-effect free for kit state. Tests assert attachments unchanged after soft miss display. Caption documents advisory nature (DBR-GUID / port decisions).

### R5 — Chip semantics

| Tier | Label | Tone key |
| ---- | ----- | -------- |
| supported | supported | success |
| weak | weak | warning |
| missing | missing | danger |

Set-bonus / element rows use compact list tiles with status/hint text when present.

### R6 — P3 phase gate

This slice is the last P3 UI row: after soft guidance, Windows can create build, attach sets, pin slots, and **see soft coverage** without equip. Equip remains P4.

## Dependencies confirmed

- DART-004 pure soft coverage + soft stats
- DART-028 `queryVariantCoverage`, `updateUserBuild` softStatTargets
- DART-033 variant compose selection + attachments

## Alternatives rejected

- Auto-suggest attach of evidence items — soft must never auto-apply.
- Separate Soft nav destination — unnecessary for thin display slice.
- Hard-blocking default variant on missing coverage — product/domain: soft only (DBR-SYN-011).
