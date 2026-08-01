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

/// Full product download set (parity with TS `RAW_TABLES`).
///
/// [BungieManifestService.ensureCurrent] downloads these; MVP extractors only
/// load the subset in [mvpRawTables].
const downloadRawTables = <String>[
  'DestinyInventoryItemDefinition',
  'DestinyStatDefinition',
  'DestinyPlugSetDefinition',
  'DestinySocketTypeDefinition',
  'DestinySocketCategoryDefinition',
  'DestinyDamageTypeDefinition',
  'DestinyInventoryBucketDefinition',
  'DestinyClassDefinition',
  'DestinySandboxPerkDefinition',
  'DestinyArtifactDefinition',
  'DestinyEquipmentSlotDefinition',
  'DestinyEquipableItemSetDefinition',
  'DestinyLoadoutIconDefinition',
  'DestinyLoadoutColorDefinition',
  'DestinyLoadoutNameDefinition',
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

/// Errors for manifest download / status / refresh.
class ManifestServiceException implements Exception {
  ManifestServiceException(this.message);
  final String message;

  @override
  String toString() => 'ManifestServiceException: $message';
}

/// Settings / status snapshot for a Windows host (DART-018).
class ManifestStatus {
  const ManifestStatus({
    required this.cachedVersion,
    required this.remoteVersion,
    required this.isStale,
    required this.entityCache,
  });

  /// Version currently on disk, null if never downloaded.
  final String? cachedVersion;

  /// Latest version reported by Bungie, null if the check failed / no key.
  final String? remoteVersion;

  final bool isStale;

  /// Entity cache meta for [cachedVersion], if present.
  final EntityCacheMeta? entityCache;

  Map<String, dynamic> toJson() => {
        'cachedVersion': cachedVersion,
        'remoteVersion': remoteVersion,
        'isStale': isStale,
        'entityCache': entityCache?.toJson(),
      };
}

/// Stale rule (product parity — see research.md).
bool computeIsStale(String? cachedVersion, String? remoteVersion) {
  if (cachedVersion == null) return true;
  if (remoteVersion == null) return false;
  return cachedVersion != remoteVersion;
}

/// Injected HTTP GET for Bungie manifest calls (tests mock this).
typedef ManifestHttpGet = Future<ManifestHttpResponse> Function(
  Uri uri, {
  Map<String, String>? headers,
});

class ManifestHttpResponse {
  const ManifestHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

/// Parsed Bungie Destiny2/Manifest metadata.
class ManifestMetadata {
  const ManifestMetadata({
    required this.version,
    required this.tablePaths,
  });

  final String version;

  /// Relative paths keyed by raw table name (English component content).
  final Map<String, String> tablePaths;
}
