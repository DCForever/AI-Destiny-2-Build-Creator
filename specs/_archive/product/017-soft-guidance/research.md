# Research: Soft Guidance & Coverage Indicators

**Feature**: 017-soft-guidance  
**Date**: 2026-07-10  
**Spec**: [spec.md](./spec.md) (Q1=A, Q2=C, Q3=C)

No NEEDS CLARIFICATION remaining.

---

## 1. Coverage evaluator location

**Decision**: New pure `src/lib/builds/coverage.ts` (+ tests), called from a thin helper used by the coverage route. Not folded into `resolveVariant` or `suggestSets`.

**Rationale**: Mirrors `equipReady.ts`; evaluate-on-read; save paths stay free of soft side effects.

**Alternatives**: Inside resolve (couples soft to hard); inside suggestions/ (wrong home for indicators).

---

## 2. Evidence link matching

**Decision**: `matchEvidenceLink(link, claims, setBonusIndex)`:

| Kind | Match |
|------|--------|
| `weapon` | Claim `itemHash === link.itemHash` |
| `weapon_perk` | `selectedPerks` contains `link.perkHash` |
| `origin_trait` | Trait hash in `selectedPerks` (or manifest origin traits when available) |
| `armor_set_bonus` | Armor claim count in set ≥ `bonusPieces` |

Tier: 0 → `missing`; some → `weak`; all → `supported`. Zero-link synergy → `missing`.

**Rationale**: FR-006; planned rolls (016), not ownership.

---

## 3. Set-bonus soft coverage

**Decision**: Separate breakdown rows via set-bonus store / piece counts on armor claims. Partial pieces = inactive/partial + hint; never invent 2pc/4pc.

**Rationale**: DBR-SETB-001 / US2.

---

## 4. Element / subclass soft mismatch

**Decision**: Soft rows only. Subclass element vs weapon `WeaponRecord.element`; Kinetic never mismatches; Prismatic skips blanket off-element lock. Hint text only; never hard-block.

**Rationale**: Q2=C; FR-008.

---

## 5. API shape

**Decision**: `GET /api/user/builds/:id/variants/:variantId/coverage` returning synergies / setBonuses / elementMismatches (no softStats). Internally resolve then evaluate.

**Rationale**: Keep `.../resolved` focused on equipment + equip-ready (016).

---

## 6. Suggest-sets gap bias

**Decision**: Keep existing `scoreSet`; add equal-weight gap bonus when a set would match currently unmatched evidence links (+ reason). Exclude fashion.

**Rationale**: FR-007 / SC-004 without regressing tag scoring.

---

## 7. Debug UI

**Decision**: BuildsDebugPage “Fetch Coverage” + show tiers/hints; surface gap-close reasons on suggest-sets. No soft-stat rows.

---

## Tech

Existing Next.js + SQLite + vitest + `npm run gate`. No new dependencies.
