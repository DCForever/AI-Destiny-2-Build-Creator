# Apply to character — end-to-end plan (Flutter Windows host)

**Status:** plan only (no implementation in this change)  
**Baseline:** `main` @ `1837370` (Weapon optimizer v1)  
**Owner requirements:** Daniel, 2026-11-13  
**Claim labels:** **measured** = read in code at baseline; **inferred** = strong deduction from code/docs; **guess** = unverified assumption.

---

## POTETO-LITE

**Goal:** One-click Apply to character on the Windows Builds detail card — sign in if needed, gate on live inventory, then equip (and vault-transfer only when required) with per-item progress.  
**Smallest next change:** Ship live-profile instance presence checks through `runBuildsMockApplyToCharacter` first; leave webview sign-in and token-store hardening for later PRs.

---

## 1. Current state (measured @ `1837370`)

### 1.1 Builds mock apply host — `builds_mock_apply.dart`

File: `flutter/apps/windows_host/lib/builds_mock/builds_mock_apply.dart`

| Lines | What exists |
| --- | --- |
| 9–13 | Host Apply for Builds mock; reuses existing OAuth + `BungieWriteClient`; comment says **no new scopes or auth flows**. |
| 14–35 | `BuildsMockApplyPorts` — optional `services` / `writeClient` / `oauthSession` / `profileClient`; resolvers fall back to `AppServices`. |
| 87–131 | `resolveBuildsMockApplyTarget` — requires signed-in OAuth + profile; uses `getMemberships` then `getCharacters`; picks **first Warlock**; signed out → **`Sign in from Settings to apply.`** (103–104). |
| 138–219 | `runBuildsMockApplyToCharacter` — builds item list from Fill In applied pins, emits initial waiting progress, calls package `applyToCharacter` with access token + membership type + character id. |
| 156–160 | Signed-out mid-run error: `Sign in from Settings to apply this build to a character.` |
| 163–171 | Empty plan → ask user to Fill In → Apply to build first (needs instance ids). |
| 222–241 | `itemsForBuildsMockApply` — only slots with non-empty `instanceId` + `itemHash`. |

**Not present (measured):** no call to `getFullInventory` / live instance presence before EquipItem; no TransferItem planning; no in-app sign-in; button path stays disabled when target unresolved.

### 1.2 Package apply runner — `apply_to_character.dart`

File: `flutter/packages/app/lib/src/equip/apply_to_character.dart`

| Lines | What exists |
| --- | --- |
| 10–16 | `ApplyItemState`: waiting / applying / done / failed. |
| 54–76 | `ApplyToCharacterProgress` + `applyingLine` (`Applying N of M`). |
| 95–98 | **One-click sequential apply** — no per-move confirm; failures do not stop later items. |
| 151–160 | Plan is **`EquipStepKind.equip` only** — no `transfer` steps. |
| 162–194 | Wraps `executeEquipPlan` with per-item progress callbacks. |

Tests: `flutter/packages/app/test/apply_to_character_test.dart` (sequential progress, continue-after-failure).  
No-dismantle guard: `apply_path_no_dismantle_guard_test.dart` (extended to host apply file in #31).

### 1.3 UI wiring (progress already on the card)

| File | Lines | Behavior |
| --- | --- | --- |
| `builds_mock_page.dart` | 98–104, 259–268, 367–401 | Holds `_applyTarget` / disabled reason / progress maps; `_applyToCharacter` calls `runBuildsMockApplyToCharacter` and updates progress. |
| `builds_mock_page_build_detail.dart` | 155–180 | **Apply to character** disabled when `_applyTarget == null` (signed-out shows reason text, not a sign-in modal). |
| same | 271–287, 640–728 | `_ApplyProgressPanel` — summary + per-item waiting/applying/done/failed rows with optional `reason`. |

**Measured vs owner UX:** progress UI skeleton exists; signed-out path is **disable + Settings copy**, not “tap Apply → sign-in modal → continue.”

### 1.4 Auth + token storage

| File | Lines | Behavior |
| --- | --- | --- |
| `windows_oauth_session.dart` | 63–185 | `restore()` — load store; silent `refreshTokens` when refresh present; keep store on transient network errors. |
| same | 189–357 | `signIn()` — Public+PKCE, **system browser** via `BrowserLauncher`, HTTPS loopback callback, code exchange, persist tokens. |
| `token_store.dart` | 36–52 | Secure key **`destiny2.bungie.oauth.tokens`** via `flutter_secure_storage` + default `WindowsOptions()`. |
| same | 74–192 | `FileTokenStore` + `DualTokenStore` (Credential Locker primary, app-support JSON secondary). |
| `host_bootstrap.dart` | 127–149 | Wires `DualTokenStore` + `WindowsOAuthSession.restore()`. |
| `bungie_oauth_client.dart` | 62–71 | Authorize URL: `client_id`, `response_type`, `state`, `redirect_uri`, PKCE — **no `scope` query param** (correct for Bungie portal-scoped apps; **measured**). |
| `settings/oauth_account_card.dart` | ~133 | Settings **Sign in** calls `session.signIn()` (external browser). |

**Docs tension (measured in docs, not contradicted by code path):** `flutter/apps/windows_host/README.md` and `docs/flutter-confidential-desktop-oauth-note.md` state Public clients **do not receive `refresh_token`** (~1h access). Code already supports refresh when a refresh token exists. Owner wants silent refresh + Credential Manager — **inferred:** either live Public app unexpectedly issues refresh (**guess**), or product must accept a Confidential / helper path (ADR in confidential note) before refresh is reliable.

**Launch-independence gap (inferred):** fixed storage *key* exists, but Windows Credential Locker identity often follows exe/package identity; `DualTokenStore` file sidecar is under **application-support** (path can differ by run mode). Owner’s “dev / release / any launch method reuse one name” is **not proven** by current `WindowsOptions()` alone — needs explicit Win32 Credential Manager / DPAPI target name verification.

### 1.5 Profile client (read-only)

File: `flutter/packages/bungie/lib/src/profile/bungie_profile_client.dart`

| Lines | Behavior |
| --- | --- |
| 8 | Inventory components: `102,201,205,300,304,305,310`. |
| 17–43 | Port: memberships, characters, loadouts profile, **`getFullInventory` / WithDiagnostics**. |
| 91–113 | HTTP GetProfile → `parseFullInventoryResponse` → `RawInventoryItem` list (includes `instanceId`, `location`, `characterId`). |

Wired on host as `AppServices.profileClient` (`host_bootstrap.dart` 153–158, 205).  
Apply target resolution already uses profile for characters; **apply equip path does not re-read live inventory** (measured).

### 1.6 Write surface + TransferItem

| Piece | Status |
| --- | --- |
| `HttpBungieWriteClient.equipItem` / `transferItem` | Implemented (`write_client.dart` 95–125). |
| `executeEquipPlan` | Runs transfer / equip / artifact / fashion (`equip_orchestrator.dart`). |
| Builds Apply path | **Equip only** (`apply_to_character.dart` 151–160). |
| Domain `planEquipSteps` | Adds TransferItem when location is vault or item is on another character (`equip_plan.dart` 185–239, 272–274). |

**Is TransferItem required?** **Yes, when the live instance is in the vault** (and for other-character hops the existing planner uses vault as intermediate). **Why (measured + inferred):** `EquipItem` only works for items already on the target character’s inventory; vault copies must `TransferItem` (`transferToVault: false`) first. Owner rule: **never dismantle/delete**; allow TransferItem **only** for vault→character (and vault hop if still needed for other-character). Current Apply path will **fail EquipItem** for vault-only pins unless TransferItem is added.

### 1.7 Stale-instance disclaimer / weapon optimize comment

| Claim | Label |
| --- | --- |
| Exact string `stale-instance protection is NOT in v1` **not found** in tree @ `1837370` | **measured** (search) |
| `weapon_optimize.dart` L105: inventory is “not checked against the live profile” | **measured** |
| Owner ask to remove that disclaimer + comment after live-profile gate lands | treat L105 comment as the tracked disclaimer; if a “NOT in v1” string is added in an interim PR, remove it in the same safety PR |

### 1.8 What the user sees today

On Builds detail, if signed out / no host services: Apply button **disabled**, muted text **`Sign in from Settings to apply.`** (measured). Progress panel only appears after a run starts while signed in with a resolved Warlock target.

---

## 2. Owner requirements → design commitments

| Requirement | Plan commitment |
| --- | --- |
| One click, no per-move confirm | Keep; already true in `applyToCharacter`. |
| Progress on build detail, one change at a time | Keep `_ApplyProgressPanel`; extend reasons + transfer rows if TransferItem added. |
| Signed out → in-app Bungie login webview; fallback external browser; app never handles password | New modal; reuse PKCE + loopback; password stays on Bungie page. |
| Refresh token in Win Credential Manager / DPAPI under fixed launch-independent name; silent refresh | Harden token store; resolve Public-vs-Confidential refresh reality. |
| Narrowest OAuth scopes | Portal-only (see §3); do not add authorize `scope` param. |
| Never dismantle/delete; writes = EquipItem + TransferItem only when vault requires it | Keep no-dismantle guards; add vault TransferItem only. |
| Before EquipItem: live profile inventory check; skip missing; visible reason; test via `runBuildsMockApplyToCharacter`; remove stale disclaimer / L105 comment | First HIGH-risk PR. |
| No tokens/secrets in repo, logs, tests, CI | Keep redaction + gitleaks + `client_secret_scan`. |

---

## 3. OAuth scopes needed

Bungie scopes are configured on the **application portal**, not in the authorize URL (**measured** from Bungie OAuth docs + current `buildAuthorizeUrl`).

**Narrowest set for Apply + live inventory gate:**

| Portal scope | Why |
| --- | --- |
| `ReadBasicUserProfile` | Implicit for all apps; memberships / identity. |
| `ReadDestinyInventoryAndVault` | Live `GetProfile` inventory for stale-instance gate + location (vault vs character). |
| `MoveEquipDestinyItems` | `EquipItem` + `TransferItem`. |

**Do not request:** groups admin/write, BnetWrite, EditUserData, vendors/advisors (obsolete), token claim scopes, etc.

**Ops note (inferred):** if the Public app’s portal scopes are already broader, shrink to the three above before shipping write Apply; users who authorized an older broader scope must re-auth after a scope change (Bungie refresh keeps old scope until re-auth).

**Refresh token:** silent multi-day refresh is a **Confidential** (or local helper) concern per `docs/flutter-confidential-desktop-oauth-note.md`. Public+PKCE remains default architecture (**measured** docs). Decide in the token-storage PR whether operator Confidential is in scope for Windows Apply; do not embed `CLIENT_SECRET` in the binary/repo.

---

## 4. Failure handling

| Failure | Behavior |
| --- | --- |
| **Token expiry / invalid_grant** | On Apply start: `restore`/refresh once; if definitive auth failure → clear or mark signed-out and open sign-in modal (same path as cold signed-out). Mid-run 401: stop further writes, mark remaining items failed with “session expired — sign in and retry”, keep already-applied rows (no rollback — matches existing best-effort orchestrator). |
| **Partial apply** | Continue after per-item failure (**measured** today). Final summary `N applied, M failed`. Failed rows keep visible reasons. No automatic undo/dismantle. User re-runs Apply after fixing inventory/CSV. |
| **Rate limits / throttle** | `BungieHttpClient` already surfaces throttle hooks (`rate_limit.dart`, error code 1672). Apply should pause/retry with backoff for throttle signals (**inferred** need — not wired in apply path today), show “Rate limited — waiting…” on the current row; abort remaining only after repeated failure with clear summary. |
| **Character in an activity** | Equip/Transfer often fails while in activities (**guess** exact Platform error code; map by message/`ErrorCode` once captured from live fail). Mark current + optionally remaining items failed with “Character is in an activity — return to orbit and retry.” Do not retry aggressively. |
| **Instance missing from live profile** | Skip EquipItem/TransferItem for that id; row → failed with **`not in current inventory - re-import DIM CSV`** (owner copy). |
| **Vault item without TransferItem** | Until Transfer PR lands: treat as failed with reason that item is in vault (or block earlier). After Transfer PR: transfer then equip as two progress steps or one logical change with sub-status (**mockup**). |

Never log access/refresh tokens (existing redaction in OAuth client snippets). Tests use fakes/`MemoryTokenStore` only.

---

## 5. UI pieces that are new (need mockup)

Existing progress panel / button chrome can stay as the baseline; **new** surfaces that need a Windows mockup (ux-redesign / Widgetbook) before polish PRs:

1. **In-app Bungie sign-in modal** — embedded webview (`webview_windows` or equivalent) loading Bungie’s authorize URL; cancel; “Having trouble? Open in browser” fallback.  
2. **Signed-out Apply CTA** — button **enabled** when signed out (today it is disabled); tap starts modal then continues Apply.  
3. **Missing-instance / skip reason** — progress row copy: `not in current inventory - re-import DIM CSV`.  
4. **Terminal failure banners** — session expired, rate limited, character in activity, partial summary.  
5. **Transfer-aware progress** (if TransferItem shows as its own step) — vault → character then equip, still “one change at a time” on the card.

**Not new (measured):** Apply button label, Applies-to Warlock label, waiting→applying→done/failed list.

---

## 6. PR sequence (one HIGH-risk concern per PR)

Order is dependency-aware: safety gate before broader write surface; token identity before relying on silent session; webview before “Apply while signed out”; TransferItem before claiming vault builds work; final PR wires the full click path.

### PR1 — Live-profile stale-instance gate

| | |
| --- | --- |
| **HIGH-risk concern** | Equipping / trusting CSV instance ids that are gone live (wrong EquipItem calls / user confusion). |
| **Scope** | Before any EquipItem in the Builds Apply path, call existing read-only `BungieProfileClient.getFullInventory` (or WithDiagnostics). Skip instances not present; set visible reason `not in current inventory - re-import DIM CSV`. Exercise through `runBuildsMockApplyToCharacter`. Remove `weapon_optimize.dart` L105 “not checked against the live profile” comment (and any interim “stale-instance … NOT in v1” disclaimer if introduced). Do **not** add TransferItem, webview, or Credential Manager changes. |
| **Files (expected)** | `builds_mock_apply.dart`; possibly small helper under `packages/app` or `packages/bungie`; `builds_mock_apply_test.dart`; `weapon_optimize.dart` (comment only); optional `apply_to_character.dart` if gate is shared. |
| **Size** | Medium |
| **Tests** | Fake profile with missing/present instance ids; assert no `equipItem` for missing; assert reason string; extend `runBuildsMockApplyToCharacter` tests. |
| **Risk** | High — false negatives if inventory components incomplete; extra GetProfile latency/rate use. |

### PR2 — Launch-independent token storage + silent refresh

| | |
| --- | --- |
| **HIGH-risk concern** | Losing / forking refresh credentials across debug vs release vs launch method; secret handling if Confidential. |
| **Scope** | Persist refresh under a **fixed Win Credential Manager / DPAPI name** independent of exe path (verify `flutter_secure_storage` Windows target or replace with explicit CredWrite/DPAPI). Keep DualTokenStore healing only if secondary is not a second identity. Document Public refresh limits; if product requires multi-day silent refresh, follow confidential-desktop note (operator secret or local helper) **without** committing secrets. Silent refresh on Apply start via existing `restore`/refresh. |
| **Files** | `token_store.dart`, possibly new Win32/DPAPI wrapper, `windows_oauth_session.dart`, `host_bootstrap.dart`, README / confidential note / port-decisions if Confidential chosen, token store tests. |
| **Size** | Medium (Large if Confidential helper lands) |
| **Tests** | Store round-trip with fixed key; refresh success/invalid_grant; **no** token literals in fixtures beyond obvious fakes; `client_secret_scan` green. |
| **Risk** | High — auth lockout, credential duplication, secret leakage if Confidential mishandled. |

### PR3 — In-app sign-in webview modal (+ browser fallback)

| | |
| --- | --- |
| **HIGH-risk concern** | OAuth embed security / Bungie blocking embedded login / loopback callback races. |
| **Scope** | Modal hosting authorize URL in embedded webview; PKCE + existing loopback unchanged; app never sees password fields as first-party UI. Detect embed failure / user choice → existing `BrowserLauncher` path. Cancel cleans loopback. No Apply auto-continue yet (that is PR5) unless trivial. |
| **Files** | New modal widget under `windows_host/lib/auth/`; `windows_oauth_session.dart` injection for “open authorize URL” without forcing system browser; Settings card can reuse; pubspec (`webview_windows` or chosen plugin); widget tests with fakes. |
| **Size** | Large |
| **Tests** | Session still exchanges code via loopback with fake browser/webview; cancel; fallback flag; no secrets in logs. |
| **Risk** | High — broken sign-in, CSRF/state bugs, plugin Windows path-length issues. |

### PR4 — TransferItem for vault-only hops (still no dismantle)

| | |
| --- | --- |
| **HIGH-risk concern** | Expanding write surface incorrectly (wrong direction, other-character moves, anything resembling delete). |
| **Scope** | After live presence check: if instance is in **vault**, emit TransferItem (`transferToVault: false`) then EquipItem. Optionally vault-hop for other-character using existing `planEquipSteps` rules — but **only** transfer/equip; never dismantle/delete/scrap. Tighten no-dismantle guards to assert Apply path call set. Progress may show transfer then equip. |
| **Files** | `apply_to_character.dart` and/or planner adapter; `builds_mock_apply.dart`; orchestrator already supports transfer; tests + no-dismantle guard. |
| **Size** | Medium |
| **Tests** | Vault item → transfer then equip; character-local → equip only; missing → skip; guard forbids dismantle symbols/APIs. |
| **Risk** | High — mis-transfer, double-transfer, activity failures mid-hop. |

### PR5 — End-to-end Apply wiring (signed-out → modal → apply)

| | |
| --- | --- |
| **HIGH-risk concern** | Product path integration: wrong ordering, double Apply, stuck signingIn, target/label drift. |
| **Scope** | Enable Apply when signed out; tap opens PR3 modal; on success refresh target; run PR1 gate + PR4 writes; keep one-click no confirm; progress on card. Map token expiry / throttle / in-activity into row + banner copy from §4. Remove Settings-only dead-end as the primary path (Settings sign-in remains available). |
| **Files** | `builds_mock_page.dart`, `builds_mock_page_build_detail.dart`, apply helper, copy strings; page/widget tests. |
| **Size** | Medium |
| **Tests** | Signed-out tap → signIn invoked; after fake sign-in apply runs; disabled only while applying; progress keys stable. |
| **Risk** | High — UX regressions on Builds detail; race if user navigates away mid-oauth. |

### PR6 — Progress / failure UX polish (mockup-driven)

| | |
| --- | --- |
| **HIGH-risk concern** | Lowest remaining product risk: copy/layout only (keep scope narrow so it stays one concern). |
| **Scope** | Implement mockups from §5 for reasons, banners, transfer step labels; no new write APIs. |
| **Files** | Detail progress widgets; optional Widgetbook use case; presentation tests. |
| **Size** | Small |
| **Tests** | Widget tests for reason strings and banner keys. |
| **Risk** | Low–Medium (product copy); treat as **Medium** if it still touches apply state machine. Prefer **no new write behavior** here so HIGH risk stays out. |

---

## 7. Testing strategy (cross-cutting)

- **Unit / fake HTTP:** profile missing/present; equip/transfer call order; throttle and 401 mapping.  
- **Host:** `runBuildsMockApplyToCharacter` + Builds detail widget tests (already cover Applies-to label / enablement).  
- **Guards:** no-dismantle + client_secret_scan + gitleaks.  
- **Manual (Windows):** sign-in modal + browser fallback; Credential Manager entry name across `flutter run` vs release; Apply with vault item; Apply while in activity; partial failure.  
- **Never:** real refresh/access tokens in fixtures, logs, or CI artifacts.

---

## 8. Out of scope (this program)

- Dismantle / lock / inject socket / DIM network apply.  
- Per-item confirm dialogs.  
- Character picker beyond current auto Warlock target (unless a later product change).  
- Shipping Confidential secret inside public binaries.  
- Next.js / Jaspr Apply parity (Windows host first).

---

## 9. Suggested implementation order (checklist)

1. PR1 live-profile gate + remove L105 disclaimer comment.  
2. PR2 token identity + refresh policy decision.  
3. PR3 webview modal + browser fallback.  
4. PR4 vault TransferItem.  
5. PR5 wire signed-out Apply → modal → full run.  
6. PR6 mockup polish for failure/progress copy.

---

## 10. Traceability

| Owner ask | Where addressed |
| --- | --- |
| One-click like DIM | §1.2, §2, PR5 |
| Progress on card | §1.3, §5, PR6 |
| Webview sign-in + browser fallback | §5, PR3, PR5 |
| Credential Manager / DPAPI fixed name | §1.4, PR2 |
| Narrowest scopes | §3 |
| EquipItem + TransferItem vault-only; no dismantle | §1.6, PR4 |
| Live profile check + reason + tests + remove disclaimer | §1.7, PR1 |
| Secrets never in repo/logs/tests/CI | §2, §7, PR2 |
