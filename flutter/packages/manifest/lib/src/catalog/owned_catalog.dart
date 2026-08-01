import 'catalog_item.dart';

/// Build itemHash → owned instance count from a sequence of inventory hashes.
///
/// MVP (DART-026): one count per definition hash (no searchName aggregation).
Map<int, int> countOwnedByItemHash(Iterable<int> itemHashes) {
  final counts = <int, int>{};
  for (final hash in itemHashes) {
    counts[hash] = (counts[hash] ?? 0) + 1;
  }
  return counts;
}

/// Annotate [items] with [ownedCounts] (itemHash → copy count).
///
/// Returns new list; does not mutate [items]. Unlisted hashes get
/// `owned: false`, `ownedCount: 0`.
List<CatalogItem> annotateCatalogWithOwned(
  List<CatalogItem> items,
  Map<int, int> ownedCounts,
) {
  if (ownedCounts.isEmpty) {
    return [
      for (final item in items)
        item.owned || item.ownedCount != 0
            ? item.copyWith(owned: false, ownedCount: 0)
            : item,
    ];
  }
  return [
    for (final item in items)
      () {
        final count = ownedCounts[item.hash] ?? 0;
        if (item.ownedCount == count && item.owned == (count > 0)) {
          return item;
        }
        return item.copyWith(owned: count > 0, ownedCount: count);
      }(),
  ];
}
