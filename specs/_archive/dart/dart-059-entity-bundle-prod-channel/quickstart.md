# Quickstart: DART-059 Entity Bundle Prod Channel

## Channel decision (summary)

| Item | Value |
| ---- | ----- |
| **Chosen channel** | **Hybrid** |
| **Primary offline** | Ship-in-app `/entities/prod/bundle.json` |
| **Pointer** | `/entities/channel.json` |
| **Optional CDN** | `cdnUrl` in channel.json (tried first) |
| **Legacy demo** | `/entities/prebuilt/bundle.json` |

Full write-up: [docs/multiplatform-dart-entity-bundle-channel.md](../../docs/multiplatform-dart-entity-bundle-channel.md)

## Operator: ship a new prod bundle

1. Extract MVP stores on desktop (Windows DART-018 path) into `EntityBundleDocument` JSON.
2. Set `manifestVersion` (e.g. `entity-bundle-prod-2026-07-25`).
3. Write to deploy tree: `apps/web_host/web/entities/prod/bundle.json` (or CDN object).
4. Update `channel.json` `bundleVersion` to match; set `cdnUrl` only if using CDN.
5. Redeploy Jaspr static assets (or CDN object only when hybrid CDN is used).

## Dev: run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\packages\manifest
dart test test/entity_bundle_channel_test.dart test/entity_bundle_test.dart

cd F:\Destiny2BuildCreator-multiplatform-dart\apps\web_host
dart test test/entity_bundle_loader_test.dart test/catalog_page_test.dart
```

## Verify Catalog offline path

1. Serve web host static assets (includes `/entities/channel.json` + prod bundle).
2. Open `/catalog` — status should show prod version (not only `prebuilt-mvp-1`).
3. Disconnect network after assets loaded — facets still work from in-memory catalog.
4. Compose builds/sets/synergies on writer tab — no Next `/api` manifest calls.

## Cutover evidence

- RB-05 cleared / RC-WEB-DATA PASS in cutover checklist after this slice merges.
- GAP-WEB-02 closed in feature-gaps doc.
