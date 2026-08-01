import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

const _itemTypeArmor = 2;
const _tierExotic = 6;

class ExoticArmorExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.exoticArmor;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final slotTable = await loadTable('DestinyEquipmentSlotDefinition');
    final slotMap = _buildSlotMap(slotTable);
    final result = <ExoticArmorRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isExoticArmor(item)) continue;
      final slot = _resolveArmorSlot(item, slotMap);
      if (slot == null) continue;
      final classType = toClassName(item.classType);
      if (classType == null) continue;
      final intrinsicPlug = findSocketPlug(item, itemTable, (plug) {
        final cat = plug.plug?['plugCategoryIdentifier'] as String? ?? '';
        return cat.contains('intrinsics') ||
            plug.itemTypeDisplayName == 'Intrinsic';
      });
      if (intrinsicPlug == null) continue;
      final archetypePlug = findSocketPlug(item, itemTable, (plug) {
        final cat = plug.plug?['plugCategoryIdentifier'] as String? ?? '';
        final typeName = plug.itemTypeDisplayName ?? '';
        return cat.contains('armor_archetypes') ||
            typeName.contains('Archetype');
      });
      final base = projectBase(item);
      result.add(
        ExoticArmorRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          classType: classType,
          slot: slot,
          intrinsic: NamedDescription(
            name: intrinsicPlug.displayProperties.name,
            description: intrinsicPlug.displayProperties.description,
          ),
          archetype: archetypePlug?.displayProperties.name,
          flavorText: item.flavorText ?? '',
        ),
      );
    }
    return result;
  }
}

bool _isExoticArmor(RawInventoryItem item) {
  final tier = item.inventory?['tierType'] as num?;
  return item.itemType == _itemTypeArmor && tier?.toInt() == _tierExotic;
}

Map<int, ArmorSlotName> _buildSlotMap(RawTable slotTable) {
  final map = <int, ArmorSlotName>{};
  for (final v in slotTable.values) {
    final slot = RawEquipmentSlot.tryParse(v);
    if (slot == null) continue;
    final name = toArmorSlot(slot.displayProperties.name);
    if (name != null) map[slot.hash] = name;
  }
  return map;
}

ArmorSlotName? _resolveArmorSlot(
  RawInventoryItem item,
  Map<int, ArmorSlotName> slotMap,
) {
  final h = item.equippingBlock?['equipmentSlotTypeHash'] as num?;
  if (h == null) return null;
  return slotMap[h.toInt()];
}
