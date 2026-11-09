# Quickstart: DART-020 Flutter Catalog Offline

## Pure filter (library)

```dart
import 'package:destiny2_manifest/destiny2_manifest.dart';

final filtered = filterCatalogClient(
  items,
  CatalogClientFilters(
    elements: FacetFilter(include: ['Solar', 'Arc']),
    ammos: FacetFilter(exclude: ['Special']),
    query: 'breath',
  ),
);
```

## Offline load

```dart
final catalog = OfflineCatalog(storageRoot: root);
final base = await catalog.loadBase(); // uses current-version.json
final page = catalog.browse(CatalogClientFilters(query: 'void'));
```

## Tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/manifest
cd apps/windows_host
flutter test
```

## Host

Run Windows host; open **Catalog** tab; filter chips + search work offline when entity stores exist under app-support `entities/<version>/`.
