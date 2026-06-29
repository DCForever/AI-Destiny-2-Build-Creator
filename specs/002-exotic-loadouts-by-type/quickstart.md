# Quickstart: Exotic Loadouts by Type

**Updated**: 2026-06-29

**Purpose**: End-to-end validation on **`/loadouts`** (production UI) and optional API checks.

## Prerequisites

```bash
npm run dev
# http://localhost:3000
# Settings → Refresh manifest (BUNGIE_API_KEY)
# Sign in with Bungie
```

Seed data: save **≥3 loadouts** from Generator with varied exotics (e.g. Crown of Tempests Warlock helmet, different Hunter helmet, exotic kinetic + power weapons).

## Scenario 1: P1 — Armor Exact and Slot Filters

**Route**: `/loadouts`

1. Confirm list shows all saved loadouts when no filter active.
2. Open filter → **Armor → Exact** → pick or type "Crown of Tempests".
3. **Pass**: Only loadouts with that exact exotic armor; each row shows armor name (SC-003 exact case).
4. Clear armor filter → full list restored.
5. **Armor → Slot → Helmet**.
6. **Pass**: All loadout rows with any exotic helmet; at least two distinct helmet names if seeded (SC-003 slot case).
7. Filter with no matches → empty state message (acceptance scenario 4).
8. **Pass**: SC-001 — filter applies in under 5 seconds.

**API check** (optional):

```http
GET /api/user/loadouts?armorMode=exact&armorHash=<hash>
GET /api/user/loadouts?armorMode=slot&armorSlot=Helmet
```

## Scenario 2: P2 — Weapon Exact and Slot Filters

1. **Weapon → Exact** → select a saved exotic weapon name.
2. **Pass**: Only loadouts equipping that weapon; weapon name visible on rows.
3. Clear → **Weapon → Slot → Power** (or Kinetic/Energy as seeded).
4. **Pass**: Loadouts with exotic in that slot appear; non-exotic-only loadouts excluded.

**API check**:

```http
GET /api/user/loadouts?weaponMode=slot&weaponSlot=Power
GET /api/user/loadouts?weaponMode=exact&weaponHash=<hash>
```

## Scenario 3: P3 — Contextual Discovery from Sheet

1. Open a loadout using Crown of Tempests.
2. On exotic armor row, click **Loadouts with this exotic** (exact).
3. **Pass**: List filters to Crown-only; sheet may close or stay open per UX; no loadout data mutated.
4. Re-open same loadout → click **Same slot type** (Helmet).
5. **Pass**: Broader helmet list including other exotics (SC-002 within 10s).
6. Repeat for exotic weapon row (exact + slot actions).

## Scenario 4: Combined Filters and Clear

1. Apply armor slot **Helmet** AND weapon slot **Kinetic** together.
2. **Pass**: Only loadouts matching **both** (FR-006 independent dimensions, AND when both set).
3. Clear one dimension → other remains.
4. **Clear all** → full list, no page reload required (SC-005).

## Scenario 5: Class Scoping (edge)

1. Save Titan helmet loadout and Warlock helmet loadout.
2. Filter **Helmet** slot.
3. **Pass**: Each loadout only matches if exotic armor class matches loadout class (no cross-class false positives).

## Gate

```bash
npm run gate
```

**Pass**: All tests green including new `src/lib/loadouts/*.test.ts`.

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Empty filter results after manifest refresh | Open loadout once to trigger re-resolve; then refilter |
| Slot filter excludes loadout | Exotic hash unresolved — verify manifest cached |
| No filter UI | Sign in required; need ≥1 saved loadout for meaningful test |
