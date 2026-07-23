# Contract: Finish Gaps Evaluation

**Type**: Pure domain function (+ optional thin read DTO on build detail)  
**Stories**: US4 (drives US1–US3 CTAs)  
**Rules**: FR-018–023, DBR-CMPL-001/002, DBR-CMP-001

## Function

```ts
evaluateFinishGaps(input: {
  variantId: string;
  isDefaultVariant: boolean;
  attachments: Array<{ setId: string; mode: "live" | "snapshot"; setType: "armor" | "weapon" | "mod" | "pair" | "fashion"; setName?: string }>;
  /** Resolved combat claims keyed by slot (from resolveVariantEquipment) */
  equipment: Partial<Record<string, { slot: string; itemHash: number; itemName: string; instanceId?: string | null }>>;
  /** Optional: known armor-slot mod presence for soft mod completeness */
  hasModCoverage?: boolean;
}): FinishGapsResult;
```

See [data-model.md](../data-model.md) for `FinishGapsResult` / `FinishGap`.

## Behavior

1. Evaluate categories in order **armor → weapon → mod**.
2. Covering set = attachment with matching `setType` (prefer live if multiple).
3. Required slots (default variant): armor five slots; weapon three slots. Non-default may use same list for guidance but `complete` may be softer (UI: strong CTA only if default).
4. Slot filled if `equipment[slot]` present with itemHash.
5. Status:
   - no covering set + claims → `capture_available` (also treat as needs_set for actions)
   - no covering set + no claims → `needs_set`
   - covering set + empty required slots → `needs_fill`
   - covering set + all required filled → `satisfied`
6. Mod: if create-from-build cannot snapshot mods, `canCapture` false; `needs_set` until mod set attached or `hasModCoverage` true per product rule documented in implementation tests.
7. Pure: no I/O.

## Optional API (not required for v1)

If build detail already returns enough attachment+equipment summary, gaps can be computed client-side from the same payload. A dedicated `GET .../finish-gaps` is optional and only added if payload is insufficient.

## Errors

N/A for pure function. Callers handle missing build/variant before invoke.
