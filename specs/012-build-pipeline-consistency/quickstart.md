# Quickstart: Build Pipeline Consistency

**Feature**: 012-build-pipeline-consistency  
**Date**: 2026-07-08

Manual verification that create → designate → variant → attach → resolve works **without typing hashes or opaque IDs**.

## Prerequisites

1. Local app: `npm run dev` (non-production).
2. Signed in via Bungie (debug layout redirects if not).
3. At least one user synergy exists (create on `/debug/synergies` with catalog link pickers if needed).
4. At least one Weapon Set and one Armor Set exist on `/debug/sets` (catalog item lookup OK).
5. Manifest/entity cache available (normal app startup).

See also: [DEBUG.md](../../../DEBUG.md) (update when this feature lands).

## Automated checks (after implementation)

```bash
npm run gate
```

Focus areas: `src/lib/builds/buildService.test.ts` (explicit synergies), `src/app/api/manifest/search` scoped empty browse, `src/lib/debug/subclassScope.test.ts`, attachment merge helper tests.

## Scenario A — Create build (US1)

1. Open `/debug/builds`.
2. Create form:
   - Pick **exotic armor** via search (no hash field required).
   - Pick **subclass** via structured fields (class → subclass name → abilities/aspects/fragments).
   - Select **≥1 synergy** from multi-select.
   - Select concept tags as desired.
   - Leave the default variant empty if desired.
3. Submit create.
4. **Expect**: Build appears; detail/JSON shows exotic name+hash, synergies, default variant. No “seeded default synergy” without selection.
5. **Negative**: Clear synergies and attempt create → blocked with clear `NO_SYNERGY` (or equivalent message).
6. **Negative**: With zero user synergies in the account, open create → blocked with message + path/link to `/debug/synergies` (no inline wizard).

## Scenario B — Variant accounting (US3)

1. Select the build from Scenario A.
2. Confirm **Variant** dropdown lists Default (visible selection).
3. Duplicate variant.
4. **Expect**: Both variants listed; selection can switch between them.
5. On the copy, set an **exotic weapon** via catalog search (or clear) → **Expect**: only that variant updates.
6. With **no** variant selected (if UI allows clear), attempt Resolve → blocked with prompt to select a variant.

## Scenario C — Attach / detach sets (US2)

1. Select variant **Default**.
2. Open set attach: filter by type `weapon` and a tag the weapon set has; select set; mode `live`; confirm (variant name shown).
3. Attach a **second** set to Default → **Expect**: both attachments present (additive; no wipe).
4. Select the **duplicate** variant; attach an armor set.
5. On Default, **Remove** one attachment → **Expect**: only that set gone; the other remains.
6. For each variant, run **Resolved JSON**.
7. **Expect**: Each resolution reflects only that variant’s attachments; shared exotic armor/subclass/synergies appear on both.

## Scenario D — Synergy edit (US4)

1. On Synergies debug, ensure two synergies exist.
2. On Builds, select build → multi-select both → save designations (PATCH).
3. Remove one → save.
4. Run suggest-sets / suggest-synergies.
5. Run compare / resolve against the selected variant.
6. **Expect**: Designation list matches selection; selected-variant suggestions, compare, and resolve run without error.

## Scenario E — Lookup parity smoke (US5)

| Entity | On Builds | On reference page | Check |
|--------|-----------|-------------------|--------|
| Exotic armor | Create + filter | Catalog | Search → select; same identity fields |
| Set | Attach picker | Sets list | type + tag AND |
| Synergy | Multi-select | Synergies list | name + type visible |
| Variant | VariantSelect | (Builds only) | name + default flag |

Empty Search on scoped lookups → browse valid results; empty non-browse lookups still show clear empty state.

## Scenario F — End-to-end timing (SC-001)

From a clean browser session (already signed in, sets+synergies exist), complete A→C resolve in under 5 minutes **without** entering any hash or UUID by hand.

## Scenario G — Scoped empty search (SC-007 / FR-020–022)

1. On `/debug/builds` create form, set class **Warlock**, subclass **Stormcaller**.
2. Clear the Super search box → click **Search** → **Expect**: only Warlock + Arc supers (not Solar/Void/etc.).
3. Pick a Super; switch subclass to **Dawnblade** → **Expect**: Arc-incompatible Super cleared; empty Super Search now lists Solar-scoped options.
4. Exotic armor empty Search with class Warlock → **Expect**: only Warlock exotic armor.
5. Prismatic Warlock empty ability Search → **Expect**: Prismatic-tagged options only (not all Warlock elements).

## Pass criteria

- [ ] Happy path uses pickers only (SC-002)
- [ ] Multi-variant actions hit selected variant only (SC-003)
- [ ] Parity table above passes (SC-004)
- [ ] Invalid ops show clear messages (SC-005)
- [ ] Scoped empty search / subclass switch (SC-007 / Scenario G)
- [ ] `npm run gate` green
