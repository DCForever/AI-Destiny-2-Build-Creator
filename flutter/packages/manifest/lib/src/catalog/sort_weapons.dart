import 'canonical_order.dart';
import 'catalog_item.dart';
import 'sort_by_name.dart';

/// Slot order for weapons default sort (Kinetic → Energy → Power, then rest).
///
/// Alias of [kCatalogSlotOrder] for existing call sites.
const List<String> kWeaponSlotSortOrder = kCatalogSlotOrder;

/// Ammo order for weapons default sort (Primary → Special → Heavy, then rest).
///
/// Alias of [kCatalogAmmoOrder] for existing call sites.
const List<String> kWeaponAmmoSortOrder = kCatalogAmmoOrder;

/// Ordered sort keys for weapons browse (GAP-CAT-BROWSE-003).
///
/// Host may reorder via progressive sheet; default is
/// slot → exotic → ammo → archetype → name.
enum CatalogSortKey {
  slot,
  exotic,
  ammo,
  archetype,
  name,
}

/// Default sort priority (brief lock).
const List<CatalogSortKey> kDefaultWeaponSortKeys = [
  CatalogSortKey.slot,
  CatalogSortKey.exotic,
  CatalogSortKey.ammo,
  CatalogSortKey.archetype,
  CatalogSortKey.name,
];

/// Human labels for sort/group progressive sheet.
const Map<CatalogSortKey, String> kCatalogSortKeyLabels = {
  CatalogSortKey.slot: 'Slot',
  CatalogSortKey.exotic: 'Exotic first',
  CatalogSortKey.ammo: 'Ammo',
  CatalogSortKey.archetype: 'Archetype / frame',
  CatalogSortKey.name: 'Name',
};

int _indexOrTail(List<String> order, String? value) {
  if (value == null || value.isEmpty) return order.length;
  final i = order.indexOf(value);
  return i < 0 ? order.length : i;
}

int _compareBySortKey(CatalogItem a, CatalogItem b, CatalogSortKey key) {
  switch (key) {
    case CatalogSortKey.slot:
      return _indexOrTail(kWeaponSlotSortOrder, a.slot).compareTo(
        _indexOrTail(kWeaponSlotSortOrder, b.slot),
      );
    case CatalogSortKey.exotic:
      // Exotics first.
      if (a.isExotic == b.isExotic) return 0;
      return a.isExotic ? -1 : 1;
    case CatalogSortKey.ammo:
      return _indexOrTail(kWeaponAmmoSortOrder, a.ammo).compareTo(
        _indexOrTail(kWeaponAmmoSortOrder, b.ammo),
      );
    case CatalogSortKey.archetype:
      // Weapon type (itemTypeName): Rocket Launcher always last among known types.
      final typeA = a.itemTypeName ?? '';
      final typeB = b.itemTypeName ?? '';
      final typeCmp = compareCanonicalLabels(
        typeA,
        typeB,
        kCatalogWeaponArchetypeOrder,
      );
      if (typeCmp != 0) return typeCmp;
      final frameA = (a.frame ?? '').toLowerCase();
      final frameB = (b.frame ?? '').toLowerCase();
      return frameA.compareTo(frameB);
    case CatalogSortKey.name:
      return compareDisplayName(a.name, b.name);
  }
}

/// Compare two catalog rows by an ordered list of [sortKeys].
///
/// Pure; does not mutate inputs. Falls back to name then hash for stability.
int compareCatalogItemsByKeys(
  CatalogItem a,
  CatalogItem b,
  List<CatalogSortKey> sortKeys,
) {
  final keys = sortKeys.isEmpty ? kDefaultWeaponSortKeys : sortKeys;
  for (final key in keys) {
    final cmp = _compareBySortKey(a, b, key);
    if (cmp != 0) return cmp;
  }
  final nameCmp = compareDisplayName(a.name, b.name);
  if (nameCmp != 0) return nameCmp;
  return a.hash.compareTo(b.hash);
}

/// Compare two catalog rows with weapons default order:
/// slot → exotic → ammo → archetype → display name.
///
/// Pure; does not mutate inputs. Use after [filterCatalogClient] for weapons
/// browse only — armor/universal callers keep alpha via [filterCatalogClient].
int compareCatalogWeapons(CatalogItem a, CatalogItem b) {
  return compareCatalogItemsByKeys(a, b, kDefaultWeaponSortKeys);
}

/// Stable weapons sort with optional multi-key priority.
List<CatalogItem> sortCatalogWeapons(
  Iterable<CatalogItem> items, {
  List<CatalogSortKey> sortKeys = kDefaultWeaponSortKeys,
}) {
  final list = List<CatalogItem>.from(items);
  list.sort((a, b) => compareCatalogItemsByKeys(a, b, sortKeys));
  return list;
}
