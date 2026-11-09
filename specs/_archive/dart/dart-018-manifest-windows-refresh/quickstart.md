# Quickstart: DART-018 Manifest Windows Refresh

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/manifest
```

## Host usage (Flutter Windows later)

```dart
final root = StorageRoot.windowsAppSupport(supportDirectory.path);
await root.ensureLayout();

final refreshApi = WindowsManifestRefresh(
  storageRoot: root,
  apiKey: platformApiKey, // public Bungie API key only
);

final status = await refreshApi.status();
if (status.isStale) {
  final after = await refreshApi.refresh(); // partial download + isolate rebuild
  print(after.entityCache?.counts);
}
```

## Force full re-download

```dart
await refreshApi.refresh(forceFullDownload: true);
```
