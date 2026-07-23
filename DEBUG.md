# Debug / Service UI

**Canonical operator guide** for local verification of APIs and domain logic via `/debug/*` pages (FR-033). Production polished UI is deferred; debug pages call the same REST APIs documented in `specs/*/contracts/`.

> **Maintenance (required):** Update this file in the same change whenever you modify debug routes, prerequisites, owned-catalog/inventory flows, sync behavior, or related APIs. Feature `quickstart.md` files are scenario checklists; **this file is the single consolidated reference.**

**Last reviewed:** 2026-07-14 (feature 026 armor set optimizer)

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
| [`/debug/sets`](src/app/debug/sets/page.tsx) | Set CRUD, concept tags, slot items, `confirmReplace` on slot conflict, **instance disambiguation carousel** (owned copies with Tier/stats/set-bonus or weapon perks), **per-copy weapon perk grid** (DIM-style columns from instance capture), **armor optimizer** (026): manual optimize, constraints editor, on-open improvement check, materialize / apply-in-place | `/api/user/sets`, `/api/concept-tags`, `/api/catalog/{weapons,armor}`, `/api/user/inventory/instances`, `/api/user/inventory/instances/:instanceId/perk-grid`, `/api/bungie/sync`, `/api/user/armor/optimize`, `/api/user/armor/optimize/materialize`, `/api/user/sets/:id/optimize`, `/api/user/sets/:id/apply-combination` |
| [`/debug/builds`](src/app/debug/builds/page.tsx) | Build pipeline UI: exotic armor/weapon lookup, explicit synergies, structured subclass, variant selection, set attach/detach, suggestions, compare, **armor optimizer** (026): create-sets-from-build, optimize + materialize, soft improvement suggestions | `/api/user/builds`, variants, `/api/manifest/search`, suggest-*, `/api/user/builds/:id/create-sets`, `/api/user/armor/optimize`, `/api/user/armor/optimize/materialize`, `/api/user/armor/improvement-suggestions` |
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
**Needs:** manifest + sign-in (inventory not required for CRUD; inventory sync required for the disambiguation carousel)

1. Create typed sets (Weapon, Armor, Mod, Pair, Fashion).
2. On `SLOT_OCCUPIED`, resubmit with `confirmReplace: true`.
3. Invalid concept tags → `INVALID_TAG`.
4. Fashion sets excluded from build attach on `/debug/builds`.

**Checklist:** `specs/001-build-sets-synergies/quickstart.md` Scenario 1

---

## Flow: Instance disambiguation carousel (010 P1/P2)

**Page:** `/debug/sets` (Item lookup fieldset)  
**Needs:** manifest + sign-in + **inventory sync**

1. Select a Weapon/Armor set + slot, then **Search catalog** (`scope=owned`, `includeInstancePointer=1`).
2. Click an owned catalog row (`ownedCount > 0`) → the picker fetches copies via `instancesHref` and opens a **carousel of all owned copies** (one card per copy, no cap — US1/FR-021).
   - **Armor card**: six Armor 3.0 stats + total, the **Tier** (`Tier N` exact from the API `gearTier`, `~Tier N` estimated fallback, `Exotic`, or `Tier unavailable`), and **Set Bonus** 2pc/4pc text (or "no set bonus"). (US2)
   - **Weapon card**: every equipped socket plug in socket order (unresolved shown by hash). (US2/FR-003)
3. **Remove** copies you don't want → they leave the carousel (session-only, inventory unchanged); **Reset** restores them (US5/FR-016/FR-017).
4. **Select this copy** → fills the item form with that copy's `instanceId` + equipped perks.
   - **Weapon**: a **per-copy perk grid** loads from `GET /api/user/inventory/instances/:instanceId/perk-grid` (equipped + alternates per column, equipped marked, defaults to equipped). Does **not** use catalog `perk-options` (weapon-type pool). Stale copies (`socket_plugs` null) trigger **one automatic** `POST /api/bungie/sync` per copy per session, then re-fetch; until capture completes, grid shows equipped-only with a pending indicator (011 US3).
5. **Put item** → `PUT /api/user/sets/:id/items` records the specific `instanceId` + column-ordered `selectedPerks`. Occupied-slot **replace confirmation** still applies.

**Re-sync notes:**
- Armor **Tier** reads nullable `inventory_items.gear_tier` — copies synced before feature 010 need re-sync to backfill `gearTier`.
- Weapon **per-copy alternates** read nullable `inventory_items.socket_plugs` — copies synced before feature 011 auto re-sync once when the grid opens, or re-sync manually via Settings / `POST /api/bungie/sync`.

**Edge cases:**

| Case | Expected |
|------|----------|
| Item owned in one copy | single-card carousel, still selectable |
| Never-synced / unsigned | sync prompt / auth error (no empty carousel) |
| Armor with API `gearTier` | exact `Tier N` (not approximate) |
| Legacy armor (`gearTier` null) + complete stats | estimated `~Tier N` |
| `gearTier` null + incomplete stats | `Tier unavailable` |
| Armor in no set (exotic/standalone) | "no set bonus" |
| Weapon socket with no alternatives | only the equipped perk shown |
| Stale weapon copy (`socket_plugs` null) | one auto sync + equipped-only grid until capture completes |
| Sync failure / capture unavailable | equipped-only grid + indicator; no catalog type pool |
| Enhanced perk in column | base and enhanced as separate options; enhanced labeled `(Enhanced)` |
| All candidates removed | empty state with reset |

**Checklist:** `specs/010-instance-disambiguation/quickstart.md` Scenarios A & B; `specs/011-per-copy-perk-grid/quickstart.md` Scenarios A–D

---

## Flow: Builds pipeline (012)

**Page:** `/debug/builds`  
**Needs:** manifest + sign-in; at least one synergy created via `/debug/synergies`

1. If the account has no synergies, create one on `/debug/synergies` first. Build create no longer auto-seeds a first/default synergy; `POST /api/user/builds` requires explicit `synergyIds`.
2. Create on `/debug/builds` with exotic armor lookup, structured subclass fields, synergy multi-select, and concept tags. An empty default variant is allowed, but create is blocked when no synergies exist or none are selected; the empty state links to `/debug/synergies`.
3. Empty **Search** clicks browse scoped lookup results instead of erroring: Stormcaller shows Warlock + Arc abilities/aspects/fragments, and Prismatic Warlock shows Prismatic kit only. Switching class/subclass clears incompatible structured picks while keeping compatible names.
4. Exotic armor empty Search is scoped by the selected guardian class. Exotic weapon empty Search browses all exotic weapons because weapon records are not class-scoped.
5. Select a build, then use `VariantSelect` to choose the active variant. Variant-scoped actions are disabled until a variant is selected.
6. Use exotic weapon lookup to set or clear the selected variant's exotic weapon.
7. Attach sets through `SetAttachPicker` with type + tag filters, choosing live or snapshot mode. Attach is additive; Remove detaches one set and sends the remaining full attachment list.
8. Edit synergy designations after create with the same multi-select, then resolve, compare, export, or request set/synergy/roll suggestions using the selected variant.

**Checklist:** `specs/012-build-pipeline-consistency/quickstart.md`

---

## Flow: Armor Set Optimizer (026)

**Pages:** `/debug/builds`, `/debug/sets`, **Settings** (`/settings` — post-sync hook)
**Needs:** manifest + sign-in + inventory sync; owned armor for the selected class

1. **Create Sets from Build**: `/debug/builds` → **Create sets from build (026)** → `attachNow` → new Armor Set seeded with `optimizerConstraints` (Build exotic + soft-stat priorities), replace-by-type attach.
2. **Optimize armor**: `/debug/builds` (seeds class/exotic/soft targets from the selected build) or `/debug/sets` (manual `classType`, required when no build) → checkboxes for `includeModEstimates` / `preferReuse`, extra JSON constraints (set-bonus goals, thresholds, etc.) → ranked complete five-slot kits.
3. **Materialize**: fill the armor set name / `createModSet` / `attachNow` inputs above the results table, click **Materialize** on a row → `POST /api/user/armor/optimize/materialize` creates a new Armor Set with the search's constraints persisted (never the response `seed`).
4. **Apply in place**: on `/debug/sets`, with an Armor Set selected, result rows show **Apply in place** → `POST /api/user/sets/:id/apply-combination` rewrites that Set's items without touching stored constraints or its id.
5. **Constraints editor** (`/debug/sets` → **Optimizer constraints (026)**): JSON textarea + **Save constraints** (`PATCH` `optimizerConstraints`) + **Clear constraints** (`PATCH` `optimizerConstraints: null`, opts the Set out of suggestions per FR-010d).
6. **On-open improvement check**: selecting an Armor Set with stored constraints on `/debug/sets` auto-calls `POST /api/user/sets/:id/optimize`; a soft banner (Confirm / Dismiss) appears when a better kit exists. Never auto-applies.
7. **Post-sync soft suggestions**: Settings → **Sync inventory** success calls `GET /api/user/armor/improvement-suggestions?afterSync=1`; a **"Better armor kits found"** banner lists constrained Armor Sets attached to a Build with a better kit (Confirm applies in place; Dismiss only clears the banner). Same endpoint is available as a manual **Fetch improvement suggestions** button on `/debug/builds`.

**Checklist:** `specs/026-armor-set-optimizer/quickstart.md`

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
| Armor Set Optimizer | [`specs/026-armor-set-optimizer/quickstart.md`](specs/026-armor-set-optimizer/quickstart.md) |

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
