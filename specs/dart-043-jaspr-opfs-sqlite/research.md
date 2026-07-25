# Research: DART-043 Jaspr OPFS SQLite

**Date**: 2026-07-25  
**Branch**: `dart-043-jaspr-opfs-sqlite`

## Decisions

### R1 — Drift WasmDatabase.open (not legacy WebDatabase)

| Option | Pros | Cons |
| ------ | ---- | ---- |
| `WasmDatabase.open` | Stable API; OPFS; worker sharing; Jaspr-compatible | Needs wasm + worker assets; COOP/COEP for best path |
| Legacy `package:drift/web.dart` | Older examples | Deprecated / slower; not OPFS-first |

**Choice**: `WasmDatabase.open` with `sqlite3.wasm` + `drift_worker.js`.  
**Rationale**: Matches D-WEB-DB 1a and Drift’s recommended web path (works with Jaspr / package:web).

### R2 — Single-tab writer: app-level lock + second tab blocked

| Option | Pros | Cons |
| ------ | ---- | ---- |
| Rely only on Drift shared workers | Less app code | Unsafe on `unsafeIndexedDb`; not explicit UX |
| App exclusive lock; second **blocked** | Clear UX; hard single-writer | Second tab cannot write until first releases |
| App lock; second **read-only** open | Better multi-tab browse | Harder to guarantee safe multi-connection |

**Choice**: App-level exclusive **writer** lock; second tab **blocked** (default).  
**Rationale**: Exit criteria allows read-only *or* blocked; blocked is safer and testable without multi-connection OPFS. Aligns with “local-first single-writer SQLite semantics.”

### R3 — Lock backend: injectable + browser heartbeat

**Choice**: Pure `TabWriterCoordinator` + `TabLockBackend` interface.  
- Tests: in-memory backend.  
- Browser: `localStorage` heartbeat + optional `BroadcastChannel` notify (Web Locks API when easy via `dart:js_interop`).

**Rationale**: VM `dart test` cannot exercise OPFS multi-tab; coordinator tests prove policy.

### R4 — destiny2_db conditional native open

**Choice**: Remove unconditional `dart:io` / `drift/native` from `app_database.dart`; open via conditional `connection/open_*.dart`. Preserve `AppDatabase.memory()` / `.file()` on native for Flutter hosts/tests.

**Rationale**: Web host must import schema without FFI.

### R5 — Assets versioning

**Choice**: Document + script download of:

- `drift_worker.js` from Drift release matching lockfile drift version when available  
- `sqlite3.wasm` from Drift release (if present) or `sqlite3` / `sqlite3_flutter_libs` release assets  

**Rationale**: Drift 2.31.0 lockfile may only attach worker JS; wasm often ships on sqlite3 releases. Script pins URLs.

### R6 — Settings UX only (no compose)

**Choice**: Extend Hello Settings with DB status panel; no library/build UI.

**Rationale**: Slice is OPFS + lock UX; compose is DART-046.

## References

- https://drift.simonbinder.eu/platforms/web/
- docs/multiplatform-dart-port-decisions.md — D-WEB-DB
- packages/db AppDatabase (DART-013/014)
- apps/web_host DART-042 skeleton
