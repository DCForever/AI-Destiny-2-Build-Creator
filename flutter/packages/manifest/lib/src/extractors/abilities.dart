import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

final _abilityCatRe =
    RegExp(r'\.(supers|grenades|melee|class_abilities|movement)$');

class AbilitiesExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.abilities;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final itemTable = await loadTable('DestinyInventoryItemDefinition');
    final result = <AbilityRecord>[];

    for (final item in iterItems(itemTable)) {
      if (!_isAbilityItem(item)) continue;
      final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
      final kind = _resolveKind(cat);
      if (kind == null) continue;
      final typeName = item.itemTypeDisplayName ?? '';
      final element = deriveElement(typeName, cat);
      final classType = toClassName(item.classType);
      final base = projectBase(item);
      result.add(
        AbilityRecord(
          hash: base.hash,
          name: base.name,
          searchName: base.searchName,
          icon: base.icon,
          description: item.displayProperties.description,
          kind: kind,
          classType: classType,
          element: element,
          // Full sandbox enrichment is deferred; empty lists keep hard path clean.
          subclassAffinities: const [],
          verbs: const [],
        ),
      );
    }
    return result;
  }
}

bool _isAbilityItem(RawInventoryItem item) {
  final cat = item.plug?['plugCategoryIdentifier'] as String? ?? '';
  return _abilityCatRe.hasMatch(cat);
}

AbilityKind? _resolveKind(String categoryId) {
  final match = _abilityCatRe.firstMatch(categoryId);
  if (match == null) return null;
  switch (match.group(1)) {
    case 'supers':
      return AbilityKind.superAbility;
    case 'grenades':
      return AbilityKind.grenade;
    case 'melee':
      return AbilityKind.melee;
    case 'class_abilities':
      return AbilityKind.classAbility;
    case 'movement':
      return AbilityKind.movement;
    default:
      return null;
  }
}
