import 'stores.dart';

/// Raw Bungie table names used by MVP extractors.
const mvpRawTables = <String>[
  'DestinyInventoryItemDefinition',
  'DestinyStatDefinition',
  'DestinyPlugSetDefinition',
  'DestinyDamageTypeDefinition',
  'DestinyEquipmentSlotDefinition',
  'DestinySandboxPerkDefinition',
];

/// Hash-keyed map of Bungie definition objects (JSON-decoded).
typedef RawTable = Map<String, dynamic>;

typedef LoadRawTable = Future<RawTable> Function(String tableName);

/// One extractor projects raw tables into a single entity store.
abstract class EntityExtractor {
  MvpStoreName get store;

  Future<List<Object>> extract(LoadRawTable loadTable);
}

class ResolveResult<T> {
  const ResolveResult({required this.record, required this.confidence});

  final T record;

  /// 1 = exact normalized match; lower values are weaker matches.
  final double confidence;
}

sealed class PerkLegality {
  const PerkLegality();
}

class PerkLegal extends PerkLegality {
  const PerkLegal({required this.column, required this.curated});

  final int column;
  final bool curated;
}

class PerkIllegal extends PerkLegality {
  const PerkIllegal(this.reason);
  final String reason;
}

class FragmentCountCheck {
  const FragmentCountCheck({
    required this.legal,
    required this.capacity,
    required this.requested,
  });

  final bool legal;
  final int capacity;
  final int requested;
}

/// Errors for entity cache IO / lifecycle.
class EntityCacheException implements Exception {
  EntityCacheException(this.message);
  final String message;

  @override
  String toString() => 'EntityCacheException: $message';
}
