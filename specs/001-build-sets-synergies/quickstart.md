# Quickstart: Build Sets and Synergies

**Updated**: 2026-06-28 (debug/service UI iteration)

**Purpose**: Runnable validation via **`/debug/*` pages** and APIs (FR-033). No production UX required.

## Prerequisites

```bash
npm run dev
# http://localhost:3000
# NODE_ENV must NOT be production (debug routes 404 in production)
# Settings → Refresh manifest (BUNGIE_API_KEY)
# Configure LLM endpoint (optional until Phase 9)
# Sign in + sync inventory (for owned catalog scope)
```

**Debug entry points**: `/debug/sets`, `/debug/builds`, `/debug/synergies`, `/debug/catalog`, `/debug/suggestions`

## Scenario 1: P1 — Typed Sets with Slot Rules and Concept Tags

Use **`/debug/sets`**.

1. Create **Weapon Set** named `Solar PVE` with tags `[Solar, PVE]` — add one primary, one special (leave heavy empty).
2. Attempt second primary → API returns `SLOT_OCCUPIED` → resubmit with `confirmReplace: true` (FR-027).
3. Create **Armor Set** named `Ferropotent` with tags `[Solar, Melee]` — one helmet, one chest.
4. Attempt invalid tag → rejected (`INVALID_TAG`, FR-029).
5. Create **Mod Set** with empty mod slots → debug page shows mod-slot-empty hint (FR-021).
6. Create **Pair Set** with exotic armor + exotic weapon entries.
7. Create **Fashion Set** — verify excluded from build attach options on `/debug/builds`.
8. Delete weapon from set → roll history visible in JSON; alternatives offered (FR-019).
8b. Attach set to build variant, attempt delete → blocked with affected build/variant list (FR-017).
9. Duplicate name within same set type → error (FR-005).
10. Filter sets by `Solar` + `Melee` query params → only Ferropotent shown (FR-031).

**Pass**: SC-001 (<60s for 3+ items via debug forms).

## Scenario 2: P2 — Catalog Filtering

Use **`/debug/catalog`** or catalog API directly.

1. Filter all weapons — type/archetype.
2. Set `scope=owned` after inventory sync → only owned items; unsigned-in empty/prompt (FR-007).
3. Repeat for armor (FR-008).

**Pass**: SC-002 (<5s search).

## Scenario 3: P3 — Build + Default Variant Attach

Use **`/debug/builds`**.

1. Create **Build** with exotic armor, subclass, **≥1 synergy** (seed via `/debug/synergies` if needed).
2. Default variant: attach Armor Set (snapshot) + Weapon Set (live).
3. Save — fails if zero equipment slots filled (FR-025).
4. Attach **Pair Set** with matching exotic armor → supplies exotic weapon; mismatch → rejected (FR-028).
5. Conflicting primary + pair exotic weapon → save blocked (FR-026).
6. Edit live set → variant JSON reflects change; snapshot unchanged.
7. Filter attach list by `Solar` + `Melee` tags (FR-032).
8. **Automatic** set suggestions in JSON when exotic/subclass changes (FR-010).
9. **Explicit** set and synergy suggestions via suggest forms (FR-010/016; LLM optional until T077).

**Pass**: SC-003.

## Scenario 4: P4 — Synergies with Links

Use **`/debug/synergies`** and **`/debug/catalog`**.

1. Create **Melee** synergy; link **Cast No Shadows** origin trait (FR-012).
2. Create **Void** synergy; link **Eutechnology** 2pc and 4pc bonuses.
3. Designate **both** on a build; request suggestions → equal weight (FR-024).
4. Catalog reverse lookup JSON shows all linked synergies per target (FR-012, BR-SYN-008).
5. Second synergy on *Cast No Shadows* — both returned in lookup.
6. Invalid link → `INVALID_SYNERGY_LINK`.

## Scenario 5: P5 — Roll Suggestions

Use **`/debug/suggestions`**.

1. With synergies + sets attached, request roll suggestions.
2. Verify ≥2 manifest-valid perk combos (SC-006); owned vs unowned in JSON.

## Scenario 6: P6 — Variants

Use **`/debug/builds`**.

1. Duplicate variant from Crown of Tempests build.
2. Variant A: Osteo Striga + survivability sets.
2b. Set variant notes (`Survivability` / `DPS`).
3. Variant B: Vex Mythoclast + DPS sets.
4. Compare variants via compare API — diff weapons/sets/notes in JSON.
5. Filter builds by exotic armor (FR-015, SC-004).

## Edge Cases

| Case | Expected |
|------|----------|
| `/debug/*` in production | 404 (FR-033) |
| Stale itemHash after manifest refresh | `stale: true` in JSON; new invalid hash rejected |
| Delete attached set | Blocked; list builds/variants (FR-017) |
| Save build without synergy | Blocked (FR-024) |
| 30 sets / 20 synergies full list | No noticeable lag (SC-007; no pagination v1) |
| Fashion set on variant | Display only; ignored in resolution |

## Gate

```bash
npm run gate
```

## References

- [spec.md](./spec.md) — acceptance scenarios
- [data-model.md](./data-model.md) — entities
- [contracts/debug-service-contract.md](./contracts/debug-service-contract.md)
- [contracts/set-attachment-contract.md](./contracts/set-attachment-contract.md)
- [contracts/build-variant-contract.md](./contracts/build-variant-contract.md)
- [contracts/synergy-contract.md](./contracts/synergy-contract.md)
- [research.md](./research.md) — design decisions
