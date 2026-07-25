import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Catalog/entity slot builder for Jaspr inventory sync + equip (DART-050/056).
///
/// Web does not download full raw DestinyInventoryItemDefinition (DART-044
/// prebuilt bundles). Slot labels cover weapons + exotic armor; legendary armor
/// may remain unresolved until entity coverage expands. Settings `syncNow` and
/// equip `syncIfStale` share this builder so vault/postmaster resolve the same.
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
