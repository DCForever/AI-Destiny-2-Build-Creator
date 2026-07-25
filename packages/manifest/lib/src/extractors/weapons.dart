import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

const _itemTypeWeapon = 3;
const _tierLegendary = 5;
const _weaponPerksCategoryHash = 4241085061;

class WeaponsExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.weapons;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final slotTable = await loadTable('DestinyEquipmentSlotDefinition');
    final damageTable = await loadTable('DestinyDamageTypeDefinition');
    final plugSets = await loadTable('DestinyPlugSetDefinition');

    final slotMap = _buildSlotMap(slotTable);
    final damageMap = _buildDamageMap(damageTable);
    final result = <WeaponRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isLegendaryWeapon(item)) continue;

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

      final framePlug = findSocketPlug(
        item,
        itemTable,
        isLegendaryWeaponFramePlug,
      );
      if (framePlug == null) continue;

      final base = projectBase(item);
      result.add(
        WeaponRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          slot: slot,
          element: element,
          ammo: ammo,
          frame: framePlug.displayProperties.name,
          itemTypeName: item.itemTypeDisplayName ?? '',
          originTraitHashes: _collectOriginHashes(item, itemTable, plugSets),
          perkColumns: _buildPerkColumns(item, itemTable, plugSets),
        ),
      );
    }
    return result;
  }
}

bool _isLegendaryWeapon(RawInventoryItem item) {
  final tier = item.inventory?['tierType'] as num?;
  return item.itemType == _itemTypeWeapon && tier?.toInt() == _tierLegendary;
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

List<Hash> _collectOriginHashes(
  RawInventoryItem item,
  RawTable itemTable,
  RawTable plugSets,
) {
  final hashes = <Hash>[];
  for (final socket in item.socketEntries) {
    if (!isOriginSocket(socket, itemTable)) continue;
    hashes.addAll(socketPlugHashes(socket, plugSets).curated);
  }
  return hashes.toSet().toList();
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
