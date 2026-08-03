import 'catalog_item.dart';
import 'sort_by_name.dart';

/// Slot order for weapons default sort (Kinetic → Energy → Power, then rest).
const List<String> kWeaponSlotSortOrder = ['Kinetic', 'Energy', 'Power'];

/// Ammo order for weapons default sort (Primary → Special → Heavy, then rest).
const List<String> kWeaponAmmoSortOrder = ['Primary', 'Special', 'Heavy'];

int _indexOrTail(List<String> order, String? value) {
  if (value == null || value.isEmpty) return order.length;
  final i = order.indexOf(value);
  return i < 0 ? order.length : i;
}

/// Compare two catalog rows with weapons default order:
/// slot → exotic (exotics first) → ammo → archetype → display name.
///
/// Pure; does not mutate inputs. Use after [filterCatalogClient] for weapons
/// browse only — armor/universal callers keep alpha via [sortByDisplayName].
int compareCatalogWeapons(CatalogItem a, CatalogItem b) {
  final slotCmp =
      _indexOrTail(kWeaponSlotSortOrder, a.slot).compareTo(
    _indexOrTail(kWeaponSlotSortOrder, b.slot),
  );
  if (slotCmp != 0) return slotCmp;

  // Exotics first within slot.
  if (a.isExotic != b.isExotic) {
    return a.isExotic ? -1 : 1;
  }

  final ammoCmp =
      _indexOrTail(kWeaponAmmoSortOrder, a.ammo).compareTo(
    _indexOrTail(kWeaponAmmoSortOrder, b.ammo),
  );
  if (ammoCmp != 0) return ammoCmp;

  final archA = (a.itemTypeName ?? a.frame ?? '').toLowerCase();
  final archB = (b.itemTypeName ?? b.frame ?? '').toLowerCase();
  final archCmp = archA.compareTo(archB);
  if (archCmp != 0) return archCmp;

  return compareDisplayName(a.name, b.name);
}

/// Stable weapons default sort: slot → exotic → ammo → archetype → name.
List<CatalogItem> sortCatalogWeapons(Iterable<CatalogItem> items) {
  final list = List<CatalogItem>.from(items);
  list.sort(compareCatalogWeapons);
  return list;
}
