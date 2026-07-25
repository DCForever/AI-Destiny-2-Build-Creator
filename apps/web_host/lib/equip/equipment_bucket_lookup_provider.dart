import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Catalog/entity slot builder for Jaspr equip sync (DART-050).
///
/// Web does not download full raw DestinyInventoryItemDefinition (DART-044
/// prebuilt bundles). Slot labels cover weapons + exotic armor; legendary armor
/// may remain unresolved until entity coverage expands. Full web Settings sync
/// depth is DART-056 — this wires the same resolution rules into equip
/// `syncIfStale`.
EquipmentBucketLookupBuilder createWebEquipmentBucketLookupBuilder({
  required OfflineCatalog offlineCatalog,
}) {
  return (List<int> transferItemHashes) async {
    if (transferItemHashes.isEmpty) return const {};
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
