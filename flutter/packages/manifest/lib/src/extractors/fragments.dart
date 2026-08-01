import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

final _fragmentTypeRe = RegExp(r'Fragment$');
final _fragmentCatRe = RegExp(r'\.fragments$');

/// Legacy six armor stats used by fragment investment stats in product fixtures.
const _armorStatHashes = <int>{
  2996146975, // Mobility / Weapons (hash reuse across eras)
  392767087, // Resilience / Health
  1943323491, // Recovery / Class
  1735777505, // Discipline / Grenade
  144602215, // Intellect / Super
  4244567560, // Strength
};

class FragmentsExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.fragments;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final statTable = await loadTable('DestinyStatDefinition');
    final statNameMap = _buildStatNameMap(statTable);
    final result = <FragmentRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isFragmentItem(item)) continue;
      final typeName = item.itemTypeDisplayName ?? '';
      final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
      final element = deriveElement(typeName, cat);
      final base = projectBase(item);
      result.add(
        FragmentRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          description: item.displayProperties.description,
          element: element,
          statModifiers: _buildStatModifiers(item, statNameMap),
        ),
      );
    }
    return result;
  }
}

bool _isFragmentItem(RawInventoryItem item) {
  final typeName = item.itemTypeDisplayName ?? '';
  final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
  return _fragmentTypeRe.hasMatch(typeName) || _fragmentCatRe.hasMatch(cat);
}

Map<int, String> _buildStatNameMap(RawTable statTable) {
  final map = <int, String>{};
  for (final v in statTable.values) {
    final stat = RawStatDef.tryParse(v);
    if (stat == null || stat.displayProperties.name.trim().isEmpty) continue;
    if (_armorStatHashes.contains(stat.hash)) {
      map[stat.hash] = stat.displayProperties.name;
    }
  }
  return map;
}

Map<String, int> _buildStatModifiers(
  RawInventoryItem item,
  Map<int, String> statNameMap,
) {
  final mods = <String, int>{};
  for (final stat in item.investmentStats) {
    if (stat.isConditionallyActive) continue;
    final name = statNameMap[stat.statTypeHash];
    if (name != null && stat.value != 0) mods[name] = stat.value;
  }
  return mods;
}
