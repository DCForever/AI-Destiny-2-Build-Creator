# Quickstart: DART-044 Jaspr Entity Bundles

## Package (pure)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/manifest
```

Bundle APIs: `EntityBundleDocument`, `MemoryEntityCache`, `offlineCatalogFromBundle`.

## Web host

```powershell
cd apps\web_host
dart pub get
dart test
# optional serve:
# jaspr serve  → open /catalog
```

Static fixture: `web/entities/prebuilt/bundle.json`.

## Architecture reminder

| Surface | Entity source |
| ------- | ------------- |
| Windows Flutter | `FileEntityCache` under StorageRoot (refresh DART-018) |
| Jaspr web | Prebuilt bundle JSON only (this slice) — **no** raw rebuild |

No `CLIENT_SECRET`. Soft guidance never auto-applies.
