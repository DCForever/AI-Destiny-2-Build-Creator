import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

final _aspectCategoryRe = RegExp(
  r'^(titan|hunter|warlock|shared)\.(arc|solar|void|stasis|strand|prismatic)\.aspects$',
);
const _aspectEnergyStatHash = 2223994109;

class AspectsExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.aspects;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final result = <AspectRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isAspectItem(item)) continue;
      final typeName = item.itemTypeDisplayName ?? '';
      final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
      final element = deriveElement(typeName, cat);
      final classType =
          toClassName(item.classType) ?? _classTypeFromCategory(cat);
      final base = projectBase(item);
      result.add(
        AspectRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          description: item.displayProperties.description,
          classType: classType,
          element: element,
          fragmentCapacity: _getFragmentCapacity(item),
        ),
      );
    }
    return result;
  }
}

bool _isAspectItem(RawInventoryItem item) {
  final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
  final typeName = item.itemTypeDisplayName ?? '';
  return _aspectCategoryRe.hasMatch(cat) || typeName.endsWith('Aspect');
}

int _getFragmentCapacity(RawInventoryItem item) {
  for (final stat in item.investmentStats) {
    if (stat.statTypeHash == _aspectEnergyStatHash) return stat.value;
  }
  return item.socketEntries.length;
}

DestinyClassName? _classTypeFromCategory(String categoryId) {
  final match = RegExp(r'^(titan|hunter|warlock)\.', caseSensitive: false)
      .firstMatch(categoryId);
  if (match == null) return null;
  switch (match.group(1)!.toLowerCase()) {
    case 'titan':
      return DestinyClassName.titan;
    case 'hunter':
      return DestinyClassName.hunter;
    case 'warlock':
      return DestinyClassName.warlock;
    default:
      return null;
  }
}
