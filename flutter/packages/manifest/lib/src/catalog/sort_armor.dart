import 'canonical_order.dart';
import 'catalog_item.dart';
import 'sort_by_name.dart';

/// Default armor identity sort: slot → exotic → class → tier (when known).
///
/// Pure; does not mutate inputs. One card per definition hash (caller
/// dedupes). Unknown slots/classes sort after known ranks; unknown tier
/// does not invent order (stable name → hash).
int compareCatalogArmor(
  CatalogItem a,
  CatalogItem b, {
  int? Function(CatalogItem item)? tierOf,
}) {
  final slotCmp = catalogCanonicalIndex(kCatalogArmorSlotOrder, a.slot)
      .compareTo(catalogCanonicalIndex(kCatalogArmorSlotOrder, b.slot));
  if (slotCmp != 0) return slotCmp;

  // Exotics first within slot.
  if (a.isExotic != b.isExotic) return a.isExotic ? -1 : 1;

  final classCmp = catalogCanonicalIndex(kCatalogClassOrder, a.classType)
      .compareTo(catalogCanonicalIndex(kCatalogClassOrder, b.classType));
  if (classCmp != 0) return classCmp;

  if (tierOf != null) {
    final ta = tierOf(a);
    final tb = tierOf(b);
    // Only compare when both known — never invent rank for missing tier.
    if (ta != null && tb != null && ta != tb) {
      // Higher gear tier first (Armor 3.0 quality).
      return tb.compareTo(ta);
    }
  }

  final nameCmp = compareDisplayName(a.name, b.name);
  if (nameCmp != 0) return nameCmp;
  return a.hash.compareTo(b.hash);
}

/// Stable armor identity sort after [filterCatalogClient].
List<CatalogItem> sortCatalogArmor(
  Iterable<CatalogItem> items, {
  int? Function(CatalogItem item)? tierOf,
}) {
  final list = List<CatalogItem>.from(items);
  list.sort((a, b) => compareCatalogArmor(a, b, tierOf: tierOf));
  return list;
}
