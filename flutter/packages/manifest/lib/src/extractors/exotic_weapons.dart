import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

const _itemTypeWeapon = 3;
const _tierExotic = 6;
const _weaponPerksCategoryHash = 4241085061;

/// Extract exotic weapons (product `exoticWeaponsExtractor`, DART-062).
class ExoticWeaponsExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.exoticWeapons;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final slotTable = await loadTable('DestinyEquipmentSlotDefinition');
    final damageTable = await loadTable('DestinyDamageTypeDefinition');
    final plugSets = await loadTable('DestinyPlugSetDefinition');

    final slotMap = _buildSlotMap(slotTable);
    final damageMap = _buildDamageMap(damageTable);
    final result = <ExoticWeaponRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isExoticWeapon(item)) continue;

      final slotHash = item.equippingBlock?['equipmentSlotTypeHash'] as num?;
      final slot = slotHash != null ? slotMap[slotHash.toInt()] : null;
      if (slot == null) continue;

      final dmgHash = item.defaultDamageTypeHash;
      final element = dmgHash != null ? damageMap[dmgHash] : null;
      if (element == null) continue;

      final ammo = toAmmoType(
        (item.equippingBlock?['ammoType'] as num?)?.toInt(),
      );
      if (ammo == null) continue;

      final intrinsicPlug = findSocketPlug(item, itemTable, (plug) {
        final cat = plug.plug?['plugCategoryIdentifier'] as String? ?? '';
        return cat.contains('intrinsics');
      });
      if (intrinsicPlug == null) continue;

      final catalystPlug = findSocketPlug(item, itemTable, (plug) {
        return plug.displayProperties.name.endsWith('Catalyst');
      });

      final base = projectBase(item);
      result.add(
        ExoticWeaponRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          slot: slot,
          element: element,
          ammo: ammo,
          frame: intrinsicPlug.displayProperties.name,
          intrinsic: NamedDescription(
            name: intrinsicPlug.displayProperties.name,
            description: intrinsicPlug.displayProperties.description,
          ),
          catalyst: catalystPlug == null
              ? null
              : NamedDescription(
                  name: catalystPlug.displayProperties.name,
                  description: catalystPlug.displayProperties.description,
                ),
          flavorText: item.flavorText ?? '',
          perkColumns: _buildPerkColumns(item, itemTable, plugSets),
          itemTypeName: item.itemTypeDisplayName ?? '',
        ),
      );
    }
    return result;
  }
}

bool _isExoticWeapon(RawInventoryItem item) {
  final tier = item.inventory?['tierType'] as num?;
  return item.itemType == _itemTypeWeapon && tier?.toInt() == _tierExotic;
}

Map<int, WeaponSlotName> _buildSlotMap(RawTable slotTable) {
  final map = <int, WeaponSlotName>{};
  for (final v in slotTable.values) {
    final slot = RawEquipmentSlot.tryParse(v);
    if (slot == null) continue;
    final name = toWeaponSlot(slot.displayProperties.name);
    if (name != null) map[slot.hash] = name;
  }
  return map;
}

Map<int, ElementName> _buildDamageMap(RawTable damageTable) {
  final map = <int, ElementName>{};
  for (final v in damageTable.values) {
    final dt = RawDamageType.tryParse(v);
    if (dt == null) continue;
    final name = toElementName(dt.displayProperties.name);
    if (name != null) map[dt.hash] = name;
  }
  return map;
}

List<WeaponPerkColumn> _buildPerkColumns(
  RawInventoryItem item,
  RawTable itemTable,
  RawTable plugSets,
) {
  final indexes = getPerkSocketIndexes(item, _weaponPerksCategoryHash);
  final sockets = item.socketEntries;
  final columns = <WeaponPerkColumn>[];
  var colIdx = 0;

  for (final idx in indexes) {
    if (idx < 0 || idx >= sockets.length) continue;
    final socket = sockets[idx];
    if (isExcludedPerkSocket(socket, itemTable)) continue;
    final plugs = socketPlugHashes(socket, plugSets);
    if (plugs.curated.isEmpty && plugs.randomized.isEmpty) continue;
    columns.add(
      WeaponPerkColumn(
        column: colIdx,
        curated: plugs.curated,
        randomized: plugs.randomized,
      ),
    );
    colIdx++;
  }
  return columns;
}
