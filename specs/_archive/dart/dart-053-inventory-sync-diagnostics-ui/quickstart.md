# Quickstart: DART-053 Inventory Sync Diagnostics UI

## Verify package formatter

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/bungie/test/format_sync_diagnostics_test.dart
```

## Verify Windows host

```powershell
cd apps/windows_host
flutter test test/inventory_sync_controller_test.dart test/inventory_sync_card_test.dart test/settings_page_test.dart test/catalog_page_test.dart
```

## Manual (Windows)

1. Sign in → Settings → Sync now.
2. Confirm diagnostics block shows Bungie raw / Parsed / Dropped / Stored after resolution lines.
3. With empty entity cache (or delete entity stores), open Catalog → Owned: message must mention entity cache, not only Sync now.
4. Settings manifest panel shows entity-cache empty warning when applicable.

## Web parity

```powershell
cd apps/web_host
dart test test/settings_page_test.dart
```

Settings must show Owned/entity dependency warning (full web inventory sync is DART-056).
