# Quickstart: DART-043 Jaspr OPFS SQLite

## Prerequisites

- Dart SDK compatible with `apps/web_host` (`^3.10`)
- Browser with WebAssembly (Chrome/Firefox/Safari modern)
- Optional: COOP/COEP headers for best OPFS path (see limits doc)

## Fetch web DB assets

```powershell
cd apps\web_host
powershell -File tool\fetch_drift_web_assets.ps1
```

Places `web/sqlite3.wasm` and `web/drift_worker.js`.

## Serve

```powershell
cd apps\web_host
dart pub get
jaspr serve
```

Open `http://localhost:8080` — Settings shows **Database** status (writer + storage mode when open succeeds).

Open a **second tab** to the same origin — Settings should show **blocked** (another tab holds the writer).

## Test

```powershell
cd apps\web_host
dart test

cd ..\..\packages\db
dart test
```

## Limits

See [docs/multiplatform-dart-web-opfs-limits.md](../../docs/multiplatform-dart-web-opfs-limits.md).
