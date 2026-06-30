# Debug / Service UI

**Canonical operator guide** for local verification of APIs and domain logic via `/debug/*` pages (FR-033). Production polished UI is deferred; debug pages call the same REST APIs documented in `specs/*/contracts/`.

> **Maintenance (required):** Update this file in the same change whenever you modify debug routes, prerequisites, owned-catalog/inventory flows, sync behavior, or related APIs. Feature `quickstart.md` files are scenario checklists; **this file is the single consolidated reference.**

**Last reviewed:** 2026-06-29 (feature 006 synergy refinement)

---

## Access rules

| Rule | Behavior |
|------|----------|
| Environment | `NODE_ENV` must **not** be `production` — all `/debug/*` return **404** in production (`src/app/debug/layout.tsx`). |
| Authentication | Signed-in Bungie session required — unsigned users redirect to `/api/auth/login`. |
| APIs | `/api/user/*` and owned catalog scope use the same session as debug pages. |

---

## Setup (do once per machine)

### 1. Start the app

```bash
npm install
cp .env.local.example .env.local   # fill values
npm run dev                        # http://localhost:3000
```

### 2. Refresh manifest (required for catalog, perks, most APIs)

1. Open **Settings** (`/settings`).
2. Click **Refresh manifest** (needs `BUNGIE_API_KEY` in `.env.local`).

Without manifest: generation and perk resolution fail; catalog filters return errors or empty stores.

### 3. Bungie sign-in (required for `/debug/*` and owned data)

1. Configure in `.env.local`: `BUNGIE_API_KEY`, `BUNGIE_CLIENT_ID`, `BUNGIE_CLIENT_SECRET`, `SESSION_SECRET`.
2. Bungie OAuth requires **HTTPS** and refuses `localhost`:
   - Run `npm run dev:https`
   - Open `https://127.0.0.1:3000`
   - Register redirect `https://127.0.0.1:3000/api/auth/callback` in your Bungie app.
3. **Settings → Sign in with Bungie**, or visit any `/debug/*` route (redirects to login).

### 4. Inventory sync (required for owned catalog + instance APIs)

Owned scope and instance listing read SQLite `inventory_items` — **no sync on search**; data must exist first.

**Recommended:** While signed in, use **Settings → Refresh manifest**. After manifest refresh completes, inventory sync runs automatically (see spec US5).

**Manual sync** (optional if you already refreshed manifest without signing in first):

```bash
# From a signed-in browser session (cookies), e.g. DevTools console:
fetch('/api/bungie/sync', { method: 'POST' }).then(r => r.json()).then(console.log)
```

Or use curl with your session cookie after signing in via the browser.

**Verify sync:**

```http
GET /api/bungie/inventory/status
```

Expect `itemCount > 0` and `lastFullSyncAt` set. If `itemCount` is 0, owned catalog and instance APIs return `syncPrompt: true` with guidance (not an error).

**Prerequisites chain for owned inventory:**

```
manifest refresh (Settings; auto-syncs inventory when signed in) → owned catalog / instances
```

Sign in before refreshing manifest if you want the one-step manifest + inventory flow. Otherwise: sign in → manual `POST /api/bungie/sync`.

---

## Debug routes

Nav: header on every debug page (`src/app/debug/layout.tsx`).

| Route | Purpose | Primary APIs |
|-------|---------|--------------|
| [`/debug/sets`](src/app/debug/sets/page.tsx) | Set CRUD, concept tags, slot items, `confirmReplace` on slot conflict | `/api/user/sets`, `/api/concept-tags` |
| [`/debug/builds`](src/app/debug/builds/page.tsx) | Builds, variants, set attachments (live/snapshot), synergies, suggestions, compare | `/api/user/builds`, variants, suggest-* |
| [`/debug/synergies`](src/app/debug/synergies/page.tsx) | Synergy CRUD with auto-generated names, sub-type pickers, catalog-backed link search, description preview | `/api/user/synergies`, `/api/catalog/synergy-pickers/*` |
| [`/debug/catalog`](src/app/debug/catalog/page.tsx) | Catalog browse (`scope=all\|owned`), owned instance drill-down, weapon synergy badges, synergy reverse lookup, direct instance API panel | `/api/catalog/weapons`, `/api/catalog/armor`, `/api/user/inventory/instances`, `/api/user/synergies/by-target` |
| [`/debug/suggestions`](src/app/debug/suggestions/page.tsx) | Roll / set / synergy suggestion requests | `/api/user/suggestions/rolls`, build suggest endpoints |
| [`/debug/loadouts`](src/app/debug/loadouts/page.tsx) | Loadout list exotic armor/weapon filter query builder (API verification) | `/api/user/loadouts` |

Each page: HTML forms → JSON request/response panels. No production design system.

---

## Flow: Owned catalog browse

**Page:** `/debug/catalog`  
**Needs:** manifest + sign-in + inventory sync

1. Set **Kind** (Weapons / Armor), **Scope** = **Owned**.
2. Optional filters: `q`, slot, item type, frame, class (armor).
3. Click **Search** — JSON panel shows `items`, `count`, `syncPrompt` if empty.
4. If unsigned: redirect to login. If signed in but never synced: `syncPrompt: true`, empty `items`.

**API:**

```http
GET /api/catalog/weapons?scope=owned&q=<name>
GET /api/catalog/armor?scope=owned&q=<name>
```

---

## Flow: Per-copy owned instances (003)

**Page:** `/debug/catalog` (owned scope)  
**Needs:** manifest + sign-in + inventory sync  
**Spec:** `specs/003-owned-inventory-instances/quickstart.md`

### Via catalog row (recommended)

1. Owned catalog search → pick a row with `ownedCount > 0`.
2. Click the row — instance panel **auto-fetches** (no second manual step).
3. Uses `instancesHref` from catalog when **includeInstancePointer=1** was set on search; otherwise builds `?itemHash=<hash>`.
4. Each copy is a separate row: `instanceId`, power, location, flags, resolved plugs, character labels when on a character.

### Via direct instance API panel

On `/debug/catalog`, **Instance API (direct)** section:

- `itemHash` — filter to one manifest item
- `kind` — `weapons` or `armor`
- `q` — case-insensitive substring on resolved perk names (includes intrinsics, mods, masterwork, cosmetics — not just roll perks; see 004)

### Plug resolution (004)

Instance APIs build a **hybrid plug name map** per request: entity stores (`weapon-perks`, `mods`, `origin-traits`) plus manifest `DestinyInventoryItemDefinition` fallback for plug hashes on the user's equipment rows. No sync or API shape changes.

**Fixture weapon:** The Ringing Nail (`itemHash` `4206550094`) — see [`specs/004-full-plug-resolution/quickstart.md`](specs/004-full-plug-resolution/quickstart.md) for expected named plugs (Precision Frame, Synergy, Default Shader, etc.).

**Search examples:**

```http
GET /api/user/inventory/instances?q=Synergy
GET /api/user/inventory/instances?q=Precision
```

**When manifest is missing:** more plugs show hash fallback (`resolved: false`); instances still return `200`.

### Catalog instance pointer (optional)

```http
GET /api/catalog/weapons?scope=owned&includeInstancePointer=1&q=funnel
```

Adds `instancesHref` per owned row (no inline instance arrays). Clients that ignore it are unchanged.

### Instance list API

```http
GET /api/user/inventory/instances?itemHash=<hash>
GET /api/user/inventory/instances?kind=weapons&q=frenzy
GET /api/user/inventory/instances/<instanceId>
```

| State | List response |
|-------|----------------|
| Not signed in | `401` |
| Signed in, never synced | `200`, `syncPrompt: true`, `instances: []` |
| Synced, no matches | `200`, `syncPrompt: false`, `instances: []` |
| Synced, matches | `200`, instances sorted **power descending** |

Item **name** search stays on catalog (`q` on catalog API). Instance API uses `itemHash`, `bucket`, `kind`, perk `q` only.

---

## Flow: Sets (001 P1)

**Page:** `/debug/sets`  
**Needs:** manifest + sign-in (inventory not required)

1. Create typed sets (Weapon, Armor, Mod, Pair, Fashion).
2. On `SLOT_OCCUPIED`, resubmit with `confirmReplace: true`.
3. Invalid concept tags → `INVALID_TAG`.
4. Fashion sets excluded from build attach on `/debug/builds`.

**Checklist:** `specs/001-build-sets-synergies/quickstart.md` Scenario 1

---

## Flow: Builds & variants (001 P3/P6)

**Page:** `/debug/builds`  
**Needs:** manifest + sign-in; seed synergies via `/debug/synergies` if needed

1. Create build with exotic armor, subclass, ≥1 synergy.
2. Default variant: attach armor set (snapshot) + weapon set (live).
3. Pair set exotic armor must match build exotic.
4. Duplicate variant, compare, filter by exotic armor hash.

**Checklist:** Scenarios 3 and 6 in 001 quickstart

---

## Flow: Synergies (001 P4 + 006 refinement)

**Pages:** `/debug/synergies`, `/debug/catalog` (reverse lookup + weapon badges)

**Needs:** manifest refresh (sub-type vocabularies and link pickers read entity stores).

1. Open `/debug/synergies`. Category list excludes legacy `kinetic_weapon` / `damage`; use `element` + Kinetic or `dps` instead. Playstyle/role categories without sub-types include **DPS**, **Healing**, **Solo**, **DR** (`damage_resist`), **General Weapon**, and **Team**.
2. Pick category → sub-type loads from `GET /api/catalog/synergy-pickers/subtypes?category=…` (Base for melee/grenade/super; verbs/elements from manifest).
3. Auto-generated name preview updates as category, sub-type, and link selection change (server always persists generated name).
4. Link targets: search catalog pickers only — weapons via `GET /api/catalog/weapons?q=`, other kinds via `GET /api/catalog/synergy-pickers/links?kind=…`. Description panel shows selected row text.
5. Create posts to `POST /api/user/synergies` with `type`, optional `subType`, and `links[]` built from picker selection (no manual hash fields).
6. Reverse lookup on `/debug/synergies`: origin trait / perk / armor by name, or weapon by `itemHash`.
7. On `/debug/catalog`, select a weapon row — violet badges list **all** synergies linked to that `itemHash`. JSON panel still supports `GET /api/user/synergies/by-target?kind=origin_trait&name=…`.

**Checklist:** `specs/006-synergy-refinement/quickstart.md` Scenarios 1–6; Scenario 4 in 001 quickstart for origin-trait lookup.

---

## Flow: Roll suggestions (001 P5)

**Page:** `/debug/suggestions` (also triggers on `/debug/builds`)

**Needs:** builds with attached sets/synergies for meaningful results.

**Checklist:** Scenario 5 in 001 quickstart

---

## Flow: Loadout exotic filters (002)

**Production UI:** `/loadouts` (primary validation)  
**Debug API panel:** `/debug/loadouts`

**Needs:** manifest + sign-in + **≥1 saved loadout** from Generator

```http
GET /api/user/loadouts?armorMode=exact&armorHash=<hash>
GET /api/user/loadouts?armorMode=slot&armorSlot=Helmet
GET /api/user/loadouts?weaponMode=slot&weaponSlot=Power
```

**Checklist:** `specs/002-exotic-loadouts-by-type/quickstart.md`

---

## Edge cases

| Case | Expected |
|------|----------|
| `/debug/*` in production | 404 |
| Owned catalog, unsigned | Login redirect or empty + message on API |
| Owned catalog/instances, signed in, no sync | `syncPrompt: true`, empty lists (`200`, not 500) |
| Manifest not refreshed | Sync may return `503`; catalog/perks degraded |
| Sync already running | `POST /api/bungie/sync` → `409` |
| Stale `itemHash` after manifest refresh | API may return `stale: true` on set items |
| Unresolved plug hash | Instance still returns; `displayName` = hash, `resolved: false` (rare when manifest loaded; see 004 quickstart) |

---

## Validation gate

```bash
npm run gate
```

Feature-specific scenario checklists:

| Feature | Quickstart |
|---------|------------|
| Sets, catalog, builds, synergies (platform) | [`specs/001-build-sets-synergies/quickstart.md`](specs/001-build-sets-synergies/quickstart.md) |
| Exotic loadout filters | [`specs/002-exotic-loadouts-by-type/quickstart.md`](specs/002-exotic-loadouts-by-type/quickstart.md) |
| Owned inventory instances | [`specs/003-owned-inventory-instances/quickstart.md`](specs/003-owned-inventory-instances/quickstart.md) |
| Full plug resolution | [`specs/004-full-plug-resolution/quickstart.md`](specs/004-full-plug-resolution/quickstart.md) |

Contract reference: [`specs/001-build-sets-synergies/contracts/debug-service-contract.md`](specs/001-build-sets-synergies/contracts/debug-service-contract.md)

---

## Related source

| Area | Path |
|------|------|
| Debug layout + auth | `src/app/debug/layout.tsx` |
| Owned catalog auth helper | `src/app/api/catalog/_ownedFilter.ts` |
| Inventory sync | `src/app/api/bungie/sync/route.ts` |
| Instance domain | `src/lib/inventory/instances/` |
| SQLite | `.cache/app.db` (single-process local only) |
