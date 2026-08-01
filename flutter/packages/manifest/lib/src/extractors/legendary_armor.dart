import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

const _itemTypeArmor = 2;
const _tierLegendary = 5;

/// Extract legendary armor definitions for catalog browse (DART-062).
///
/// Tier-5 armor with resolvable slot + class. Archetype plug is optional.
/// Set-bonus enrichment is intentionally out of scope (see spec A3).
class LegendaryArmorExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.legendaryArmor;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final slotTable = await loadTable('DestinyEquipmentSlotDefinition');
    final slotMap = _buildSlotMap(slotTable);
    final result = <LegendaryArmorRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isLegendaryArmor(item)) continue;
      final slot = _resolveArmorSlot(item, slotMap);
      if (slot == null) continue;
      final classType = toClassName(item.classType);
      if (classType == null) continue;

      final archetypePlug = findSocketPlug(item, itemTable, (plug) {
        final cat = plug.plug?['plugCategoryIdentifier'] as String? ?? '';
        final typeName = plug.itemTypeDisplayName ?? '';
        return cat.contains('armor_archetypes') ||
            typeName.contains('Archetype');
      });

      final base = projectBase(item);
      result.add(
        LegendaryArmorRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          classType: classType,
          slot: slot,
          archetype: archetypePlug?.displayProperties.name,
        ),
      );
    }
    return result;
  }
}

bool _isLegendaryArmor(RawInventoryItem item) {
  final tier = item.inventory?['tierType'] as num?;
  return item.itemType == _itemTypeArmor && tier?.toInt() == _tierLegendary;
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
