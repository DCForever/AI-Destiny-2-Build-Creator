import 'records.dart';

/// MVP entity store names (DART-017). Product has a larger set; later slices expand.
enum MvpStoreName {
  weapons('weapons'),
  exoticArmor('exotic-armor'),
  aspects('aspects'),
  fragments('fragments'),
  abilities('abilities'),
  mods('mods');

  const MvpStoreName(this.fileStem);
  final String fileStem;

  static MvpStoreName? tryParse(String value) {
    for (final v in values) {
      if (v.fileStem == value || v.name == value) return v;
    }
    return null;
  }

  static const List<MvpStoreName> all = values;
}

/// Metadata sidecar written alongside the stores.
class EntityCacheMeta {
  const EntityCacheMeta({
    required this.manifestVersion,
    required this.builtAt,
    required this.counts,
  });

  final String manifestVersion;
  final String builtAt;
  final Map<String, int> counts;

  Map<String, dynamic> toJson() => {
        'manifestVersion': manifestVersion,
        'builtAt': builtAt,
        'counts': counts,
      };

  factory EntityCacheMeta.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['counts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      for (final e in rawCounts.entries) {
        counts[e.key.toString()] = (e.value as num).toInt();
      }
    }
    return EntityCacheMeta(
      manifestVersion: json['manifestVersion'] as String? ?? '',
      builtAt: json['builtAt'] as String? ?? '',
      counts: counts,
    );
  }
}

/// Typed decode for MVP stores from JSON list.
List<T> decodeStoreList<T>(
  MvpStoreName store,
  List<dynamic> json,
  T Function(Map<String, dynamic>) fromJson,
) {
  return json
      .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

List<dynamic> encodeStoreRecords(MvpStoreName store, List<Object> records) {
  return records.map((r) {
    if (r is ExoticArmorRecord) return r.toJson();
    if (r is WeaponRecord) return r.toJson();
    if (r is AspectRecord) return r.toJson();
    if (r is FragmentRecord) return r.toJson();
    if (r is AbilityRecord) return r.toJson();
    if (r is ModRecord) return r.toJson();
    throw ArgumentError('Unknown record type for $store: ${r.runtimeType}');
  }).toList();
}
