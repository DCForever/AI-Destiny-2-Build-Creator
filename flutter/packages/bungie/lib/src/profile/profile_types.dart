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

/// Guardian class wire names (product / domain Titan|Hunter|Warlock).
const Map<int, String> kDestinyClassTypeNames = {
  0: 'Titan',
  1: 'Hunter',
  2: 'Warlock',
};

/// One Destiny character for equip character pick (profile component 200).
///
/// [classType] uses product wire names: Titan, Hunter, Warlock.
class CharacterSummary {
  const CharacterSummary({
    required this.characterId,
    required this.classType,
    required this.light,
    this.emblemPath,
    this.dateLastPlayed = '',
  });

  final String characterId;

  /// Titan | Hunter | Warlock
  final String classType;
  final int light;
  final String? emblemPath;
  final String dateLastPlayed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharacterSummary &&
        other.characterId == characterId &&
        other.classType == classType &&
        other.light == light &&
        other.emblemPath == emblemPath &&
        other.dateLastPlayed == dateLastPlayed;
  }

  @override
  int get hashCode => Object.hash(
        characterId,
        classType,
        light,
        emblemPath,
        dateLastPlayed,
      );
}

/// Inventory location string (product: vault | character | equipped).
typedef InventoryLocation = String;

/// Per-socket capture from components 305/310 (simplified storage shape).
class RawSocketCapture {
  const RawSocketCapture({
    required this.socketIndex,
    required this.equippedPlugHash,
    this.reusablePlugHashes = const [],
    this.isEnabled = true,
    this.isVisible = true,
  });

  final int socketIndex;

  /// Equipped plug hash from 305; may be 0 when the socket is empty/unlocked.
  final int equippedPlugHash;
  final List<int> reusablePlugHashes;

  /// DestinyItemSocketState.isEnabled (305). False ⇒ locked/disabled socket.
  final bool isEnabled;

  /// DestinyItemSocketState.isVisible (305). False ⇒ hidden socket.
  final bool isVisible;

  Map<String, Object?> toJsonMap() => {
        'socketIndex': socketIndex,
        'equippedPlugHash': equippedPlugHash,
        'reusablePlugHashes': reusablePlugHashes,
        'isEnabled': isEnabled,
        'isVisible': isVisible,
      };
}

/// One parsed inventory instance before Drift normalize.
/// Destiny ItemState bit: Locked (SetItemLockState).
const int kDestinyItemStateLocked = 1;

/// DestinyTransferStatus: item may be moved with TransferItem.
const int kDestinyTransferStatusCanTransfer = 0;

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
    this.tierType,
    this.socketCapture,
    this.isLocked = false,
    this.isTransferable = true,
    this.energyCapacity,
    this.energyUsed,
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

  /// Armor instance gearTier when present (exotic armor often == 6).
  final int? gearTier;

  /// Definition `inventory.tierType` when known (exotic weapons/armor == 6).
  final int? tierType;
  final List<RawSocketCapture>? socketCapture;

  /// Destiny ItemState Locked bit from the profile item component.
  final bool isLocked;

  /// False when DestinyTransferStatus is not CanTransfer.
  final bool isTransferable;

  /// Armor energy capacity from instance component 300 (`energy.energyCapacity`).
  /// Null when the instance has no energy block (not armor / not present).
  final int? energyCapacity;

  /// Armor energy used from instance component 300 (`energy.energyUsed`).
  final int? energyUsed;

  /// Exotic via instance gearTier or definition tierType.
  bool get isExotic =>
      gearTier == 6 || tierType == 6;

  RawInventoryItem copyWith({int? bucketHash, int? tierType}) {
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
      tierType: tierType ?? this.tierType,
      socketCapture: socketCapture,
      isLocked: isLocked,
      isTransferable: isTransferable,
      energyCapacity: energyCapacity,
      energyUsed: energyUsed,
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
    this.inventorySectionsComplete = true,
  });

  final DestinyMembership membership;
  final InventoryRawCounts raw;
  final InventoryParsedCounts parsed;
  final InventoryDroppedCounts dropped;
  InventoryResolutionCounts? resolution;

  /// False when any of profileInventory / characterInventories /
  /// characterEquipment lacked a `data` object (privacy / partial profile).
  final bool inventorySectionsComplete;
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
    this.profilePlugSetPlugHashes = const {},
    this.characterPlugSetPlugHashes = const {},
  });

  final List<RawInventoryItem> items;
  final InventoryParseDiagnostics diagnostics;

  /// Profile plug sets (104) where canInsert == true and enabled == true.
  final Set<int> profilePlugSetPlugHashes;

  /// Character plug sets (105) keyed by characterId (same canInsert/enabled).
  final Map<String, Set<int>> characterPlugSetPlugHashes;

  /// Union of profile + all characters (legacy helpers / tests).
  Set<int> get unlockedPlugSetPlugHashes => {
        ...profilePlugSetPlugHashes,
        for (final set in characterPlugSetPlugHashes.values) ...set,
      };

  /// Profile (104) + one character's (105) unlocked plug hashes.
  Set<int> unlockedPlugSetPlugHashesForCharacter(String characterId) => {
        ...profilePlugSetPlugHashes,
        ...?characterPlugSetPlugHashes[characterId],
      };
}
