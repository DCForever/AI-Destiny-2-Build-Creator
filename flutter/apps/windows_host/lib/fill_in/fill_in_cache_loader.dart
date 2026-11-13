import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

/// Outcome of loading both Fill In DIM CSV caches (armor + exotic weapons).
///
/// Never throws — missing or unreadable caches surface as [errorMessage].
class FillInCacheLoadResult {
  const FillInCacheLoadResult._({
    this.items = const <FillInInventoryItem>[],
    this.errorMessage,
  });

  factory FillInCacheLoadResult.ok(List<FillInInventoryItem> items) {
    return FillInCacheLoadResult._(
      items: List<FillInInventoryItem>.unmodifiable(items),
    );
  }

  factory FillInCacheLoadResult.missing(String message) {
    return FillInCacheLoadResult._(errorMessage: message);
  }

  final List<FillInInventoryItem> items;
  final String? errorMessage;

  bool get isOk => errorMessage == null;
}

/// Loads `{StorageRoot}/fill_in/dim_armor_inventory.csv` and
/// `dim_weapons_inventory.csv` via the existing importers' [loadCache].
///
/// Read-only: never imports, never writes. No network.
typedef FillInCacheLoader = Future<FillInCacheLoadResult> Function();

/// Default loader bound to [storageRoot].
FillInCacheLoader defaultFillInCacheLoader(StorageRoot storageRoot) {
  return () => loadFillInCaches(storageRoot);
}

Future<FillInCacheLoadResult> loadFillInCaches(StorageRoot storageRoot) async {
  final armor = await DimArmorCsvImporter(root: storageRoot).loadCache();
  if (!armor.isOk) {
    return FillInCacheLoadResult.missing(
      _settingsHint(
        armor.error ?? "Couldn't read armor cache",
        kind: 'Armor',
      ),
    );
  }
  final weapons = await DimWeaponsCsvImporter(root: storageRoot).loadCache();
  if (!weapons.isOk) {
    return FillInCacheLoadResult.missing(
      _settingsHint(
        weapons.error ?? "Couldn't read weapons cache",
        kind: 'Weapons',
      ),
    );
  }
  return FillInCacheLoadResult.ok(<FillInInventoryItem>[
    ...armor.items!,
    ...weapons.items!,
  ]);
}

String _settingsHint(String detail, {required String kind}) {
  return 'DIM $kind inventory cache is missing or unreadable ($detail). '
      'Import it in Settings (DIM $kind CSV), then try Fill In again.';
}
