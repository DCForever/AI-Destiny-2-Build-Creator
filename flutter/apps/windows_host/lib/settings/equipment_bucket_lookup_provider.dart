import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Production equipment-bucket lookup for Windows inventory sync (DART-050).
///
/// 1. Prefer raw `DestinyInventoryItemDefinition` when downloaded (DART-018).
/// 2. Fall back to OfflineCatalog slot labels (weapons / exotic armor — partial).
///
/// Empty result drops vault/postmaster items — not production-OK when raw tables
/// or entity slots should be available after manifest refresh.
EquipmentBucketLookupBuilder createWindowsEquipmentBucketLookupBuilder({
  required OfflineCatalog offlineCatalog,
  BungieManifestService? manifestService,
}) {
  return (List<int> transferItemHashes) async {
    if (transferItemHashes.isEmpty) return const {};

    final service = manifestService;
    if (service != null) {
      final version = await service.readCurrentVersion();
      if (version != null && version.isNotEmpty) {
        try {
          final table = await service.loadRawTable(
            version,
            'DestinyInventoryItemDefinition',
          );
          final fromRaw =
              buildEquipmentBucketLookup(table, transferItemHashes);
          if (fromRaw.isNotEmpty) {
            return fromRaw;
          }
        } catch (_) {
          // Fall through to catalog slots when raw missing/corrupt.
        }
      }
    }

    if (offlineCatalog.baseItems.isEmpty) {
      await offlineCatalog.loadBase();
    }
    final slots = <int, String>{
      for (final item in offlineCatalog.baseItems)
        if (item.slot != null && item.slot!.isNotEmpty) item.hash: item.slot!,
    };
    return buildEquipmentBucketLookupFromSlots(
      slots,
      onlyHashes: transferItemHashes,
    );
  };
}

/// Catalog-only builder for web / hosts without raw tables (DART-050 / DART-056).
EquipmentBucketLookupBuilder createCatalogEquipmentBucketLookupBuilder({
  required OfflineCatalog offlineCatalog,
}) {
  return createWindowsEquipmentBucketLookupBuilder(
    offlineCatalog: offlineCatalog,
    manifestService: null,
  );
}
