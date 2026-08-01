import '../types/stores.dart';
import 'catalog_item.dart';

/// Catalog kind browse modes (product `CatalogBrowseMode`).
///
/// DART-063 / GAP-UI-CATALOG-10: Weapons | Armor | Universal.
enum CatalogBrowseMode {
  /// Legendary + exotic weapons only.
  weapons,

  /// Legendary + exotic armor only.
  armor,

  /// Mixed composition search (weapons, armor, mods, subclass pieces).
  universal,
}

/// MVP store stems for [CatalogBrowseMode.weapons].
const weaponSourceStores = <String>{
  'weapons',
  'exotic-weapons',
};

/// MVP store stems for [CatalogBrowseMode.armor].
const armorSourceStores = <String>{
  'exotic-armor',
  'legendary-armor',
};

/// Store stems treated as Universal composition entities (all MVP stores).
const universalSourceStores = <String>{
  'weapons',
  'exotic-weapons',
  'exotic-armor',
  'legendary-armor',
  'mods',
  'aspects',
  'fragments',
  'abilities',
};

bool _looksLikeWeapon(CatalogItem item) {
  if (item.ammo != null && item.ammo!.isNotEmpty) return true;
  final slot = item.slot;
  return slot == 'Kinetic' || slot == 'Energy' || slot == 'Power';
}

bool _looksLikeArmor(CatalogItem item) {
  if (item.classType != null && item.classType!.isNotEmpty) {
    // Armor usually has class; weapons rarely do in our projector.
    if (!_looksLikeWeapon(item)) return true;
  }
  final slot = item.slot;
  return slot == 'Helmet' ||
      slot == 'Gauntlets' ||
      slot == 'Chest' ||
      slot == 'Legs' ||
      slot == 'ClassItem';
}

/// Whether [item] belongs to [mode].
///
/// Prefer [CatalogItem.sourceStore]; fall back to slot/ammo/class heuristics
/// for fixtures / legacy rows without store annotation.
bool itemMatchesBrowseMode(CatalogItem item, CatalogBrowseMode mode) {
  final store = item.sourceStore;
  switch (mode) {
    case CatalogBrowseMode.weapons:
      if (store != null && store.isNotEmpty) {
        return weaponSourceStores.contains(store);
      }
      return _looksLikeWeapon(item);
    case CatalogBrowseMode.armor:
      if (store != null && store.isNotEmpty) {
        return armorSourceStores.contains(store);
      }
      return _looksLikeArmor(item);
    case CatalogBrowseMode.universal:
      if (store == null || store.isEmpty) return true;
      return universalSourceStores.contains(store) ||
          MvpStoreName.tryParse(store) != null;
  }
}

/// Filter [items] to those appropriate for [mode].
List<CatalogItem> itemsForBrowseMode(
  List<CatalogItem> items,
  CatalogBrowseMode mode,
) {
  return items.where((i) => itemMatchesBrowseMode(i, mode)).toList();
}

/// Infer mode-friendly kind label for list meta.
String browseModeLabel(CatalogBrowseMode mode) {
  switch (mode) {
    case CatalogBrowseMode.weapons:
      return 'Weapons';
    case CatalogBrowseMode.armor:
      return 'Armor';
    case CatalogBrowseMode.universal:
      return 'Universal';
  }
}
