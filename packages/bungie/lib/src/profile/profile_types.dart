// Profile / inventory DTOs for Bungie GetProfile parse (DART-024).

/// Destiny platform membership resolved from Bungie account linkage.
class DestinyMembership {
  const DestinyMembership({
    required this.membershipType,
    required this.membershipId,
    required this.displayName,
  });

  final int membershipType;
  final String membershipId;
  final String displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DestinyMembership &&
        other.membershipType == membershipType &&
        other.membershipId == membershipId &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(membershipType, membershipId, displayName);
}

/// Inventory location string (product: vault | character | equipped).
typedef InventoryLocation = String;

/// Per-socket capture from components 305/310 (simplified storage shape).
class RawSocketCapture {
  const RawSocketCapture({
    required this.socketIndex,
    required this.equippedPlugHash,
    this.reusablePlugHashes = const [],
  });

  final int socketIndex;
  final int equippedPlugHash;
  final List<int> reusablePlugHashes;

  Map<String, Object?> toJsonMap() => {
        'socketIndex': socketIndex,
        'equippedPlugHash': equippedPlugHash,
        'reusablePlugHashes': reusablePlugHashes,
      };
}

/// One parsed inventory instance before Drift normalize.
class RawInventoryItem {
  const RawInventoryItem({
    required this.instanceId,
    required this.itemHash,
    required this.bucketHash,
    required this.location,
    this.characterId,
    this.power = 0,
    this.plugHashes = const [],
    this.isMasterwork = false,
    this.isCrafted = false,
    this.statValues,
    this.gearTier,
    this.socketCapture,
  });

  final String instanceId;
  final int itemHash;
  final int bucketHash;
  final InventoryLocation location;
  final String? characterId;
  final int power;
  final List<int> plugHashes;
  final bool isMasterwork;
  final bool isCrafted;
  final Map<String, Object?>? statValues;
  final int? gearTier;
  final List<RawSocketCapture>? socketCapture;

  RawInventoryItem copyWith({int? bucketHash}) {
    return RawInventoryItem(
      instanceId: instanceId,
      itemHash: itemHash,
      bucketHash: bucketHash ?? this.bucketHash,
      location: location,
      characterId: characterId,
      power: power,
      plugHashes: plugHashes,
      isMasterwork: isMasterwork,
      isCrafted: isCrafted,
      statValues: statValues,
      gearTier: gearTier,
      socketCapture: socketCapture,
    );
  }
}

/// Parse diagnostics for inventory import (product InventoryParseDiagnostics).
class InventoryParseDiagnostics {
  InventoryParseDiagnostics({
    required this.membership,
    required this.raw,
    required this.parsed,
    required this.dropped,
    this.resolution,
  });

  final DestinyMembership membership;
  final InventoryRawCounts raw;
  final InventoryParsedCounts parsed;
  final InventoryDroppedCounts dropped;
  InventoryResolutionCounts? resolution;
}

class InventoryRawCounts {
  InventoryRawCounts({
    this.vault = 0,
    Map<String, int>? characterInventories,
    this.characterInventoriesTotal = 0,
    Map<String, int>? characterEquipment,
    this.characterEquipmentTotal = 0,
    this.total = 0,
  })  : characterInventories = characterInventories ?? {},
        characterEquipment = characterEquipment ?? {};

  int vault;
  final Map<String, int> characterInventories;
  int characterInventoriesTotal;
  final Map<String, int> characterEquipment;
  int characterEquipmentTotal;
  int total;
}

class InventoryParsedCounts {
  InventoryParsedCounts({
    this.total = 0,
    this.equipmentTotal = 0,
    this.subclassTotal = 0,
    Map<String, int>? byLocation,
    Map<String, int>? byBucket,
  })  : byLocation = byLocation ??
            {
              'vault': 0,
              'character': 0,
              'equipped': 0,
            },
        byBucket = byBucket ?? {};

  int total;
  int equipmentTotal;
  int subclassTotal;
  final Map<String, int> byLocation;
  final Map<String, int> byBucket;
}

class InventoryDroppedCounts {
  InventoryDroppedCounts({
    this.total = 0,
    this.invalidShape = 0,
    this.unknownBucket = 0,
    this.missingInstanceId = 0,
    Map<String, int>? unknownBuckets,
  }) : unknownBuckets = unknownBuckets ?? {};

  int total;
  int invalidShape;
  int unknownBucket;
  int missingInstanceId;
  final Map<String, int> unknownBuckets;
}

class InventoryResolutionCounts {
  const InventoryResolutionCounts({
    required this.resolvedFromTransfer,
    required this.droppedNonEquipment,
    required this.storedTotal,
    required this.storedEquipment,
  });

  final int resolvedFromTransfer;
  final int droppedNonEquipment;
  final int storedTotal;
  final int storedEquipment;
}

class FullInventoryParseResult {
  const FullInventoryParseResult({
    required this.items,
    required this.diagnostics,
  });

  final List<RawInventoryItem> items;
  final InventoryParseDiagnostics diagnostics;
}
