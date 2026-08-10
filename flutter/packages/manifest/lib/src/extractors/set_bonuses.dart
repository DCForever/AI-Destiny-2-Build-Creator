import '../normalize.dart';
import '../raw/raw_types.dart';
import '../types/records.dart';
import '../types/services.dart';
import '../types/stores.dart';
import 'common.dart';

/// Extract Destiny equipable item sets (armor set bonuses) for Catalog / Sets.
///
/// Port of Next `setBonusesExtractor` (store `set-bonuses`).
class SetBonusesExtractor implements EntityExtractor {
  @override
  MvpStoreName get store => MvpStoreName.setBonuses;

  @override
  Future<List<Object>> extract(LoadRawTable loadTable) async {
    final setTable = await loadTable('DestinyEquipableItemSetDefinition');
    final sandboxPerks = await loadTable('DestinySandboxPerkDefinition');
    final result = <SetBonusCatalogRecord>[];

    for (final v in setTable.values) {
      final set = _parseItemSet(v);
      if (set == null) continue;
      if (set.redacted) continue;
      final name = set.displayProperties.name.trim();
      if (name.isEmpty) continue;

      final perks = <SetBonusCatalogPerk>[];
      for (final p in set.setPerks) {
        final sp = getRaw(sandboxPerks, p.sandboxPerkHash);
        Object? dpRaw;
        if (sp is Map) {
          dpRaw = Map<String, dynamic>.from(sp)['displayProperties'];
        }
        final spDp = RawDisplayProperties.from(dpRaw);
        perks.add(
          SetBonusCatalogPerk(
            requiredCount: p.requiredSetCount,
            name: spDp?.name ?? '',
            description: spDp?.description ?? '',
          ),
        );
      }

      result.add(
        SetBonusCatalogRecord(
          hash: set.hash,
          name: name,
          searchName: normalizeName(name),
          icon: set.displayProperties.icon,
          perks: perks,
          itemHashes: set.setItems,
        ),
      );
    }

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }
}

class _RawSetPerk {
  _RawSetPerk({required this.requiredSetCount, required this.sandboxPerkHash});
  final int requiredSetCount;
  final int sandboxPerkHash;
}

class _RawItemSet {
  _RawItemSet({
    required this.hash,
    required this.displayProperties,
    required this.setItems,
    required this.setPerks,
    this.redacted = false,
  });

  final int hash;
  final RawDisplayProperties displayProperties;
  final List<int> setItems;
  final List<_RawSetPerk> setPerks;
  final bool redacted;
}

_RawItemSet? _parseItemSet(Object? v) {
  if (v is! Map) return null;
  final m = Map<String, dynamic>.from(v);
  final hash = (m['hash'] as num?)?.toInt();
  final dp = RawDisplayProperties.from(m['displayProperties']);
  if (hash == null || dp == null) return null;
  final itemsRaw = m['setItems'];
  final perksRaw = m['setPerks'];
  if (itemsRaw is! List || perksRaw is! List) return null;

  final items = itemsRaw.map((e) => (e as num).toInt()).toList();
  final perks = <_RawSetPerk>[];
  for (final p in perksRaw) {
    if (p is! Map) continue;
    final pm = Map<String, dynamic>.from(p);
    final count = (pm['requiredSetCount'] as num?)?.toInt();
    final perkHash = (pm['sandboxPerkHash'] as num?)?.toInt();
    if (count == null || perkHash == null) continue;
    perks.add(_RawSetPerk(requiredSetCount: count, sandboxPerkHash: perkHash));
  }

  return _RawItemSet(
    hash: hash,
    displayProperties: dp,
    setItems: items,
    setPerks: perks,
    redacted: m['redacted'] as bool? ?? false,
  );
}

/// Family display names from a raw set-bonus table (picker without entity store).
List<String> setBonusFamilyNamesFromRawTable(RawTable setTable) {
  final names = <String>{};
  for (final v in setTable.values) {
    final set = _parseItemSet(v);
    if (set == null || set.redacted) continue;
    final name = set.displayProperties.name.trim();
    if (name.isNotEmpty) names.add(name);
  }
  final list = names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}
