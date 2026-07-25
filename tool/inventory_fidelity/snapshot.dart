// Inventory fidelity snapshot model + JSON parse (DART-054 / GAP-INV-05).
//
// Shape mirrors Next InventoryParseDiagnostics + Dart InventoryParseDiagnostics
// so operators can paste diagnostics from either host without a third model.

import 'dart:convert';

/// Portable count snapshot for one membership after one inventory sync.
class InventoryFidelitySnapshot {
  const InventoryFidelitySnapshot({
    this.source,
    this.capturedAt,
    this.membership,
    required this.raw,
    required this.parsed,
    required this.dropped,
    this.resolution,
  });

  /// Optional human label: `next` | `dart` | freeform.
  final String? source;

  /// Optional ISO-8601 capture time for dual-run notes.
  final String? capturedAt;

  final FidelityMembership? membership;
  final FidelityRawCounts raw;
  final FidelityParsedCounts parsed;
  final FidelityDroppedCounts dropped;
  final FidelityResolutionCounts? resolution;

  Map<String, Object?> toJson() => {
        if (source != null) 'source': source,
        if (capturedAt != null) 'capturedAt': capturedAt,
        if (membership != null) 'membership': membership!.toJson(),
        'raw': raw.toJson(),
        'parsed': parsed.toJson(),
        'dropped': dropped.toJson(),
        if (resolution != null) 'resolution': resolution!.toJson(),
      };

  static InventoryFidelitySnapshot fromJson(Map<String, Object?> json) {
    final membershipRaw = json['membership'];
    final resolutionRaw = json['resolution'];
    return InventoryFidelitySnapshot(
      source: json['source'] as String?,
      capturedAt: json['capturedAt'] as String?,
      membership: membershipRaw is Map
          ? FidelityMembership.fromJson(_asStringKeyed(membershipRaw))
          : null,
      raw: FidelityRawCounts.fromJson(
        _asStringKeyed(json['raw'] as Map? ?? const {}),
      ),
      parsed: FidelityParsedCounts.fromJson(
        _asStringKeyed(json['parsed'] as Map? ?? const {}),
      ),
      dropped: FidelityDroppedCounts.fromJson(
        _asStringKeyed(json['dropped'] as Map? ?? const {}),
      ),
      resolution: resolutionRaw is Map
          ? FidelityResolutionCounts.fromJson(_asStringKeyed(resolutionRaw))
          : null,
    );
  }

  /// Parse a JSON string; throws [FormatException] on invalid structure.
  static InventoryFidelitySnapshot parse(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      throw const FormatException(
        'Inventory fidelity snapshot root must be a JSON object',
      );
    }
    return fromJson(_asStringKeyed(decoded));
  }
}

class FidelityMembership {
  const FidelityMembership({
    required this.membershipType,
    required this.membershipId,
    this.displayName,
  });

  final int membershipType;
  final String membershipId;
  final String? displayName;

  Map<String, Object?> toJson() => {
        'membershipType': membershipType,
        'membershipId': membershipId,
        if (displayName != null) 'displayName': displayName,
      };

  static FidelityMembership fromJson(Map<String, Object?> json) {
    final type = json['membershipType'];
    final id = json['membershipId'];
    if (type is! num || id is! String || id.isEmpty) {
      throw const FormatException(
        'membership requires membershipType (number) and membershipId (string)',
      );
    }
    return FidelityMembership(
      membershipType: type.toInt(),
      membershipId: id,
      displayName: json['displayName'] as String?,
    );
  }

  /// Stable identity key for same-membership dual-run checks.
  String get identityKey => '$membershipType:$membershipId';
}

class FidelityRawCounts {
  const FidelityRawCounts({
    this.total = 0,
    this.vault = 0,
    this.characterInventoriesTotal = 0,
    this.characterEquipmentTotal = 0,
  });

  final int total;
  final int vault;
  final int characterInventoriesTotal;
  final int characterEquipmentTotal;

  Map<String, Object?> toJson() => {
        'total': total,
        'vault': vault,
        'characterInventoriesTotal': characterInventoriesTotal,
        'characterEquipmentTotal': characterEquipmentTotal,
      };

  static FidelityRawCounts fromJson(Map<String, Object?> json) {
    return FidelityRawCounts(
      total: _int(json, 'total'),
      vault: _int(json, 'vault'),
      characterInventoriesTotal: _int(json, 'characterInventoriesTotal'),
      characterEquipmentTotal: _int(json, 'characterEquipmentTotal'),
    );
  }
}

class FidelityParsedCounts {
  const FidelityParsedCounts({
    this.total = 0,
    this.equipmentTotal = 0,
    this.subclassTotal = 0,
    this.byLocation = const {},
    this.byBucket = const {},
  });

  final int total;
  final int equipmentTotal;
  final int subclassTotal;
  final Map<String, int> byLocation;
  final Map<String, int> byBucket;

  Map<String, Object?> toJson() => {
        'total': total,
        'equipmentTotal': equipmentTotal,
        'subclassTotal': subclassTotal,
        'byLocation': byLocation,
        'byBucket': byBucket,
      };

  static FidelityParsedCounts fromJson(Map<String, Object?> json) {
    return FidelityParsedCounts(
      total: _int(json, 'total'),
      equipmentTotal: _int(json, 'equipmentTotal'),
      subclassTotal: _int(json, 'subclassTotal'),
      byLocation: _intMap(json['byLocation']),
      byBucket: _intMap(json['byBucket']),
    );
  }
}

class FidelityDroppedCounts {
  const FidelityDroppedCounts({
    this.total = 0,
    this.invalidShape = 0,
    this.unknownBucket = 0,
    this.missingInstanceId = 0,
  });

  final int total;
  final int invalidShape;
  final int unknownBucket;
  final int missingInstanceId;

  Map<String, Object?> toJson() => {
        'total': total,
        'invalidShape': invalidShape,
        'unknownBucket': unknownBucket,
        'missingInstanceId': missingInstanceId,
      };

  static FidelityDroppedCounts fromJson(Map<String, Object?> json) {
    return FidelityDroppedCounts(
      total: _int(json, 'total'),
      invalidShape: _int(json, 'invalidShape'),
      unknownBucket: _int(json, 'unknownBucket'),
      missingInstanceId: _int(json, 'missingInstanceId'),
    );
  }
}

class FidelityResolutionCounts {
  const FidelityResolutionCounts({
    this.resolvedFromTransfer = 0,
    this.droppedNonEquipment = 0,
    this.storedTotal = 0,
    this.storedEquipment = 0,
  });

  final int resolvedFromTransfer;
  final int droppedNonEquipment;
  final int storedTotal;
  final int storedEquipment;

  Map<String, Object?> toJson() => {
        'resolvedFromTransfer': resolvedFromTransfer,
        'droppedNonEquipment': droppedNonEquipment,
        'storedTotal': storedTotal,
        'storedEquipment': storedEquipment,
      };

  static FidelityResolutionCounts fromJson(Map<String, Object?> json) {
    return FidelityResolutionCounts(
      resolvedFromTransfer: _int(json, 'resolvedFromTransfer'),
      droppedNonEquipment: _int(json, 'droppedNonEquipment'),
      storedTotal: _int(json, 'storedTotal'),
      storedEquipment: _int(json, 'storedEquipment'),
    );
  }
}

Map<String, Object?> _asStringKeyed(Map map) {
  return map.map((k, v) => MapEntry(k.toString(), v));
}

int _int(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

Map<String, int> _intMap(Object? raw) {
  if (raw is! Map) return {};
  final out = <String, int>{};
  for (final e in raw.entries) {
    final v = e.value;
    if (v is num) {
      out[e.key.toString()] = v.toInt();
    } else if (v is String) {
      out[e.key.toString()] = int.tryParse(v) ?? 0;
    }
  }
  return out;
}
