# Quickstart: DART-025 Inventory Sync UI

## Dev (Windows)

1. Configure public credentials only:
   - `--dart-define=BUNGIE_CLIENT_ID=...`
   - `--dart-define=BUNGIE_API_KEY=...`
   - Optional: `--dart-define=BUNGIE_REDIRECT_URI=http://127.0.0.1:8765/callback`
2. Run host: `flutter run -d windows` from `apps/windows_host`
3. Settings → Sign in (browser loopback) → **Sync inventory** → confirm item count updates

## Tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter test
```

## Programmatic

```dart
// After HostBootstrap.open(...)
await services.inventorySync.refreshStatus();
await services.inventorySync.syncNow();
```
