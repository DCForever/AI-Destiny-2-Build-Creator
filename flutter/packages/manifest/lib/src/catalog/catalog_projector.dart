import '../types/records.dart';
import '../types/stores.dart';
import 'catalog_item.dart';

/// Project MVP entity store records into unified [CatalogItem] rows.
///
/// Inventory fields are always unowned (DART-020).
/// DART-062: includes exotic weapons + legendary armor.
List<CatalogItem> projectMvpStores({
  List<WeaponRecord> weapons = const [],
  List<ExoticWeaponRecord> exoticWeapons = const [],
  List<ExoticArmorRecord> exoticArmor = const [],
  List<LegendaryArmorRecord> legendaryArmor = const [],
  List<AspectRecord> aspects = const [],
  List<FragmentRecord> fragments = const [],
  List<AbilityRecord> abilities = const [],
  List<ModRecord> mods = const [],
}) {
  // Dedupe by hash: weapons + exoticWeapons (and armor stores) can overlap.
  // Prefer exotic / richer rows (BUG-20260726-002).
  final byHash = <int, CatalogItem>{};

  void put(CatalogItem item) {
    final existing = byHash[item.hash];
    if (existing == null) {
      byHash[item.hash] = item;
      return;
    }
    if (item.isExotic && !existing.isExotic) {
      byHash[item.hash] = item;
      return;
    }
    // Prefer longer description / more complete type when flags equal.
    final itemScore = (item.description?.length ?? 0) +
        (item.itemTypeName?.length ?? 0) +
        (item.frame?.length ?? 0);
    final existingScore = (existing.description?.length ?? 0) +
        (existing.itemTypeName?.length ?? 0) +
        (existing.frame?.length ?? 0);
    if (itemScore > existingScore) {
      byHash[item.hash] = item;
    }
  }

  for (final w in weapons) {
    put(
      CatalogItem(
        hash: w.hash,
        name: w.name,
        icon: w.icon,
        slot: w.slot.label,
        element: w.element.label,
        ammo: w.ammo.label,
        itemTypeName: w.itemTypeName,
        frame: w.frame.isEmpty ? null : w.frame,
        isExotic: false,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.weapons.fileStem,
      ),
    );
  }

  for (final w in exoticWeapons) {
    put(
      CatalogItem(
        hash: w.hash,
        name: w.name,
        icon: w.icon,
        slot: w.slot.label,
        element: w.element.label,
        ammo: w.ammo.label,
        itemTypeName: w.itemTypeName.isEmpty ? null : w.itemTypeName,
        frame: w.frame.isEmpty ? null : w.frame,
        description: w.intrinsic.description.isNotEmpty
            ? w.intrinsic.description
            : w.intrinsic.name,
        isExotic: true,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.exoticWeapons.fileStem,
      ),
    );
  }

  for (final a in exoticArmor) {
    put(
      CatalogItem(
        hash: a.hash,
        name: a.name,
        icon: a.icon,
        slot: a.slot.label,
        classType: a.classType.label,
        frame: a.archetype,
        description: a.intrinsic.description.isNotEmpty
            ? a.intrinsic.description
            : a.intrinsic.name,
        isExotic: true,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.exoticArmor.fileStem,
      ),
    );
  }

  for (final a in legendaryArmor) {
    put(
      CatalogItem(
        hash: a.hash,
        name: a.name,
        icon: a.icon,
        slot: a.slot.label,
        classType: a.classType.label,
        frame: a.archetype,
        isExotic: false,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.legendaryArmor.fileStem,
      ),
    );
  }

  for (final a in aspects) {
    put(
      CatalogItem(
        hash: a.hash,
        name: a.name,
        icon: a.icon,
        element: a.element.label,
        classType: a.classType?.label,
        description: a.description,
        itemTypeName: 'Aspect',
        isExotic: false,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.aspects.fileStem,
      ),
    );
  }

  for (final f in fragments) {
    put(
      CatalogItem(
        hash: f.hash,
        name: f.name,
        icon: f.icon,
        element: f.element.label,
        description: f.description,
        itemTypeName: 'Fragment',
        isExotic: false,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.fragments.fileStem,
      ),
    );
  }

  for (final ab in abilities) {
    put(
      CatalogItem(
        hash: ab.hash,
        name: ab.name,
        icon: ab.icon,
        element: ab.element.label,
        classType: ab.classType?.label,
        description: ab.description,
        itemTypeName: ab.kind.json,
        isExotic: false,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.abilities.fileStem,
      ),
    );
  }

  for (final m in mods) {
    put(
      CatalogItem(
        hash: m.hash,
        name: m.name,
        icon: m.icon,
        slot: m.slotCategory.json,
        description: m.description,
        itemTypeName: 'Mod',
        isExotic: false,
        owned: false,
        ownedCount: 0,
        sourceStore: MvpStoreName.mods.fileStem,
      ),
    );
  }

  final out = byHash.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return out;
}
