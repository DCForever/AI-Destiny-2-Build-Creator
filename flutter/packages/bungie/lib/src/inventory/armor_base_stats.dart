// Next parity: `src/lib/inventory/instances/armorBaseStats.ts` (BR-SET-011 / DBR-STAT-008).

/// EoF six armor stat display names (order matches product `ARMOR_STAT_NAMES`).
const List<String> kArmorBaseStatNames = [
  'Health',
  'Melee',
  'Grenade',
  'Super',
  'Class',
  'Weapons',
];

/// Bungie stat hashes → Armor 3.0 display names (EoF).
///
/// Kept private so it does not clash with [kArmorStatHashToName] in inventory_parse.
const Map<int, String> _armorStatHashToName = {
  392767087: 'Health',
  4244567218: 'Melee',
  1735777505: 'Grenade',
  144602215: 'Super',
  1943323491: 'Class',
  2996146975: 'Weapons',
};

/// One investment stat on a plug definition.
class PlugInvestmentStat {
  const PlugInvestmentStat({
    required this.statTypeHash,
    required this.value,
    this.isConditionallyActive = false,
  });

  final int statTypeHash;
  final int value;
  final bool isConditionallyActive;
}

/// Minimal plug definition fields for base-roll extraction.
class PlugStatSource {
  const PlugStatSource({
    this.plugCategoryIdentifier,
    this.investmentStats = const [],
  });

  final String? plugCategoryIdentifier;
  final List<PlugInvestmentStat> investmentStats;
}

/// Armor 3.0 rolled stats live on invisible plugs with category `armor_stats`
/// (DIM "base" / white bar). Sum those investments for the piece's base roll.
///
/// Excludes equipped armor mods, masterwork, tuning, archetype labels, cosmetics.
/// Returns null when no `armor_stats` plugs are present among [plugHashes].
/// Soft metadata only — never auto-applies build edits.
Map<String, int>? computeArmorBaseStatsFromPlugs(
  Iterable<int>? plugHashes,
  PlugStatSource? Function(int hash) resolvePlug,
) {
  if (plugHashes == null) return null;
  final hashes = plugHashes.where((h) => h != 0).toList(growable: false);
  if (hashes.isEmpty) return null;

  final base = <String, int>{};
  var sawRollPlug = false;

  for (final hash in hashes) {
    final plug = resolvePlug(hash);
    if (plug == null) continue;
    final cat = plug.plugCategoryIdentifier ?? '';
    if (!cat.contains('armor_stats')) continue;
    sawRollPlug = true;
    for (final stat in plug.investmentStats) {
      if (stat.isConditionallyActive) continue;
      if (stat.value == 0) continue;
      final name = _armorStatHashToName[stat.statTypeHash];
      if (name == null) continue;
      base[name] = (base[name] ?? 0) + stat.value;
    }
  }

  if (!sawRollPlug) return null;

  // Ensure all six keys exist when we found roll plugs (missing = 0).
  for (final name in kArmorBaseStatNames) {
    base.putIfAbsent(name, () => 0);
  }
  return base;
}

/// Build [PlugStatSource] from DestinyInventoryItemDefinition-shaped JSON.
PlugStatSource? plugStatSourceFromItemDef(Object? raw) {
  if (raw is! Map) return null;
  final plug = raw['plug'];
  String? category;
  if (plug is Map) {
    final cat = plug['plugCategoryIdentifier'];
    if (cat is String && cat.isNotEmpty) category = cat;
  }

  final investments = <PlugInvestmentStat>[];
  final invRaw = raw['investmentStats'];
  if (invRaw is List) {
    for (final e in invRaw) {
      if (e is! Map) continue;
      final hash = e['statTypeHash'];
      final value = e['value'];
      final h = hash is int
          ? hash
          : hash is num
              ? hash.toInt()
              : null;
      final v = value is int
          ? value
          : value is num
              ? value.toInt()
              : null;
      if (h == null || v == null) continue;
      final conditional = e['isConditionallyActive'] == true;
      investments.add(
        PlugInvestmentStat(
          statTypeHash: h,
          value: v,
          isConditionallyActive: conditional,
        ),
      );
    }
  }

  if (category == null && investments.isEmpty) return null;
  return PlugStatSource(
    plugCategoryIdentifier: category,
    investmentStats: investments,
  );
}

/// Resolve plug stats from a DestinyInventoryItemDefinition table map.
PlugStatSource? resolvePlugStatFromItemDefs(
  Map<dynamic, dynamic> inventoryItemDefinitionTable,
  int plugHash,
) {
  final raw = _tableEntry(inventoryItemDefinitionTable, plugHash);
  return plugStatSourceFromItemDef(raw);
}

/// Build a resolver from an in-memory hash → [PlugStatSource] map (tests).
PlugStatSource? Function(int hash) plugStatResolverFromMap(
  Map<int, PlugStatSource> byHash,
) {
  return (hash) => byHash[hash];
}

Object? _tableEntry(Map<dynamic, dynamic> table, int hash) {
  if (table.containsKey(hash)) return table[hash];
  final asString = '$hash';
  if (table.containsKey(asString)) return table[asString];
  return null;
}
