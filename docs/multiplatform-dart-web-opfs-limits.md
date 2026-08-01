# Jaspr web SQLite / OPFS limits (DART-043)

**Status:** active  
**Updated:** 2026-07-25  
**Architecture:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) — **D-WEB-DB (1a)**  
**Slice:** DART-043 `jaspr-opfs-sqlite`

This note documents **browser persistence limits** for the Jaspr host (`apps/web_host`). It does not change product DBR/DAC rules.

## Single-tab writer (product policy)

Local-first product semantics are **single-writer SQLite**. On web:

| Role | Meaning |
| ---- | ------- |
| **Writer** | First tab that acquires the app-level exclusive lock. Opens Drift via `WasmDatabase.open` and may mutate data. |
| **Blocked** | Any additional concurrent tab of the same origin. Does **not** open a second writer connection. Settings explains that another tab holds the writer. |

- Closing the writer tab (or lock expiry after crash) allows another tab to become writer.
- This is an **application policy** on top of Drift. Even when Drift can share a DB across tabs via workers, we still elect a single product writer for clear UX and to avoid multi-tab write races on weaker storage modes.

**Read-only multi-tab** (open DB without writes) is allowed by the roadmap exit wording but **not implemented** in DART-043 — second tab is **blocked**.

## Drift storage strategies

Drift picks an implementation based on browser APIs (`WasmDatabaseResult.chosenImplementation`):

| Strategy | Notes |
| -------- | ----- |
| `opfsShared` | OPFS + shared worker (best multi-tab sharing where supported; Firefox-oriented path). |
| `opfsLocks` | OPFS without shared workers; prefers **COOP/COEP** headers. |
| `sharedIndexedDb` | IndexedDB in a shared worker — good fallback. |
| `unsafeIndexedDb` | IndexedDB **without** cross-tab sync — **unsafe for multi-tab writes**. Our single-writer lock mitigates product writes; still avoid dual writers. |
| `inMemory` | No persistence (private mode / missing APIs). Data lost on refresh. |

Missing features are surfaced in Settings when Drift reports them.

## COOP / COEP headers (recommended, not required)

For the preferred OPFS + `Atomics` path, serve the app with:

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

(or `credentialless` for COEP where appropriate).

- **Without** these headers, Drift typically still works via a slower fallback.
- Headers can break some third-party popup OAuth flows — re-test before production (DART-045 Public+PKCE).
- `sqlite3.wasm` must be served as `Content-Type: application/wasm`.

## Assets

Under `apps/web_host/web/`:

| File | Purpose |
| ---- | ------- |
| `sqlite3.wasm` | sqlite3 compiled to WebAssembly |
| `drift_worker.js` | Drift web worker for background DB / sharing |

Fetch with:

```powershell
cd apps\web_host
powershell -File tool\fetch_drift_web_assets.ps1
```

Pin versions to the resolved `drift` / `sqlite3` packages when upgrading.

## Browser caveats (high level)

| Environment | Caveat |
| ----------- | ------ |
| **Private / incognito** | OPFS may be unavailable; IndexedDB or in-memory fallback. |
| **Safari** | Historically weaker OPFS; may be “good” rather than “full” without headers. |
| **Chrome Android** | Shared workers limited; multi-tab without headers can be unsafe at storage layer — **use single-writer policy**; prefer headers when possible. |
| **Multiple devices** | No cloud multi-writer; each origin/device has its own OPFS/IDB. |
| **Full raw manifest rebuild** | Desktop (Windows) first; web uses **hybrid prebuilt entity channel** (DART-044 + **DART-059**): pointer `web/entities/channel.json` → ship-in-app `web/entities/prod/bundle.json` (optional CDN); legacy demo `prebuilt/bundle.json`. Catalog facets offline after install; no isolate raw rebuild; no Next manifest API. See [multiplatform-dart-entity-bundle-channel.md](./multiplatform-dart-entity-bundle-channel.md). |

## Explicit non-goals

- Multi-worker Edge SQLite / multi-tenant writers  
- Local Node helper process for DB  
- Flutter Web as product web target  

## Related

- Host README: `apps/web_host/README.md`  
- Spec: `specs/dart-043-jaspr-opfs-sqlite/`  
- Drift web docs: https://drift.simonbinder.eu/platforms/web/
