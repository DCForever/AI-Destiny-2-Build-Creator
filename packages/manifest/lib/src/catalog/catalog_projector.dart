import '../types/records.dart';
import '../types/stores.dart';
import 'catalog_item.dart';

/// Project MVP entity store records into unified [CatalogItem] rows.
///
/// Inventory fields are always unowned (DART-020).
List<CatalogItem> projectMvpStores({
  List<WeaponRecord> weapons = const [],
  List<ExoticArmorRecord> exoticArmor = const [],
  List<AspectRecord> aspects = const [],
  List<FragmentRecord> fragments = const [],
  List<AbilityRecord> abilities = const [],
  List<ModRecord> mods = const [],
}) {
  final out = <CatalogItem>[];

  for (final w in weapons) {
    out.add(
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

  for (final a in exoticArmor) {
    out.add(
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

  for (final a in aspects) {
    out.add(
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
    out.add(
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
    out.add(
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
    out.add(
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

  return out;
}
