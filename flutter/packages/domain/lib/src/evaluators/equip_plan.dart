/// Pure equip step planner (transfer → equip → artifact → fashion).
///
/// Mirrors TypeScript `src/lib/builds/equipPlan.ts`.
/// No network / write execution (see bungie `executeEquipPlan`).
library;

import '../models/equipment.dart';
import '../models/failure_codes.dart';
import '../models/slot_claim.dart';
import 'equip_ready.dart';

/// Kind of a planned Bungie write step.
enum EquipStepKind {
  transfer('transfer'),
  equip('equip'),
  artifact('artifact'),
  fashion('fashion');

  const EquipStepKind(this.wireName);
  final String wireName;

  static EquipStepKind? tryParse(String wire) {
    for (final v in EquipStepKind.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// One planned equip/write step (pure; not yet executed).
class PlannedEquipStep {
  const PlannedEquipStep({
    required this.id,
    required this.kind,
    this.slot,
    this.itemHash,
    this.instanceId,
    this.transferToVault,
    this.artifactConfig,
  });

  final String id;
  final EquipStepKind kind;
  final String? slot;
  final int? itemHash;
  final String? instanceId;

  /// For transfer: true = character → vault; false = vault → character.
  final bool? transferToVault;

  /// Artifact unlock hashes when [kind] is [EquipStepKind.artifact].
  final List<int>? artifactConfig;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannedEquipStep &&
        other.id == id &&
        other.kind == kind &&
        other.slot == slot &&
        other.itemHash == itemHash &&
        other.instanceId == instanceId &&
        other.transferToVault == transferToVault &&
        _intListEquals(other.artifactConfig, artifactConfig);
  }

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        slot,
        itemHash,
        instanceId,
        transferToVault,
        Object.hashAll(artifactConfig ?? const []),
      );

  @override
  String toString() => 'PlannedEquipStep($id, ${kind.wireName})';
}

/// Inventory row input for equip planning (location-aware).
///
/// Location strings match product: `vault` | `character` | `equipped`.
class EquipInventoryItem {
  const EquipInventoryItem({
    required this.instanceId,
    required this.itemHash,
    required this.location,
    this.characterId,
  });

  final String instanceId;
  final int itemHash;
  final String location;
  final String? characterId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquipInventoryItem &&
        other.instanceId == instanceId &&
        other.itemHash == itemHash &&
        other.location == location &&
        other.characterId == characterId;
  }

  @override
  int get hashCode =>
      Object.hash(instanceId, itemHash, location, characterId);
}

/// Seasonal artifact pin for planning (optional).
class EquipPlanArtifact {
  const EquipPlanArtifact({
    required this.hash,
    this.name = '',
    this.config = const [],
  });

  final int hash;
  final String name;
  final List<int> config;
}

/// One fashion slot piece for planning.
class EquipPlanFashionPiece {
  const EquipPlanFashionPiece({
    required this.itemHash,
    this.itemName = '',
  });

  final int itemHash;
  final String itemName;
}

/// Fashion set slots keyed by fashion wire slot name (e.g. `ghost`).
class EquipPlanFashion {
  const EquipPlanFashion({
    required this.setId,
    this.slots = const {},
  });

  final String setId;
  final Map<String, EquipPlanFashionPiece> slots;
}

/// Input to [planEquipSteps].
class EquipPlanInput {
  const EquipPlanInput({
    required this.equipment,
    required this.inventory,
    required this.characterId,
    this.artifact,
    this.fashion,
  });

  /// Applied combat claims (wishlist without instanceId are skipped).
  final Map<EquipmentSlot, SlotClaim> equipment;

  final List<EquipInventoryItem> inventory;
  final String characterId;
  final EquipPlanArtifact? artifact;
  final EquipPlanFashion? fashion;
}

Map<String, EquipInventoryItem> _inventoryByInstance(
  List<EquipInventoryItem> items,
) {
  final map = <String, EquipInventoryItem>{};
  for (final item in items) {
    map[item.instanceId] = item;
  }
  return map;
}

Map<int, EquipInventoryItem> _inventoryByHash(List<EquipInventoryItem> items) {
  final map = <int, EquipInventoryItem>{};
  for (final item in items) {
    map.putIfAbsent(item.itemHash, () => item);
  }
  return map;
}

bool _needsTransfer(EquipInventoryItem item, String characterId) {
  if (item.location == 'vault') return true;
  if (item.characterId != null && item.characterId != characterId) {
    return true;
  }
  return false;
}

void _appendTransfers(
  List<PlannedEquipStep> steps,
  String slot,
  EquipInventoryItem item,
  String characterId,
) {
  final onOtherCharacter = (item.location == 'character' ||
          item.location == 'equipped') &&
      item.characterId != null &&
      item.characterId != characterId;

  if (onOtherCharacter) {
    steps.add(
      PlannedEquipStep(
        id: 'transfer-$slot-to-vault',
        kind: EquipStepKind.transfer,
        slot: slot,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        transferToVault: true,
      ),
    );
    steps.add(
      PlannedEquipStep(
        id: 'transfer-$slot-from-vault',
        kind: EquipStepKind.transfer,
        slot: slot,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        transferToVault: false,
      ),
    );
    return;
  }

  if (item.location == 'vault') {
    steps.add(
      PlannedEquipStep(
        id: 'transfer-$slot',
        kind: EquipStepKind.transfer,
        slot: slot,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        transferToVault: false,
      ),
    );
  }
}

/// Pure planner: transfer → equip combat pins → artifact → fashion
/// (omit empty fashion slots / null artifact).
///
/// Throws [EquipReadyException] with [DomainFailureCodes.notEquipReady] when a
/// combat pin has an instanceId missing from inventory.
List<PlannedEquipStep> planEquipSteps(EquipPlanInput input) {
  final steps = <PlannedEquipStep>[];
  final byInstance = _inventoryByInstance(input.inventory);
  final byHash = _inventoryByHash(input.inventory);

  for (final slot in EquipmentSlot.combatSlots) {
    final claim = input.equipment[slot];
    final instanceId = claim?.instanceId;
    if (claim == null || instanceId == null || instanceId.isEmpty) continue;

    final item = byInstance[instanceId];
    if (item == null) {
      throw EquipReadyException(
        'Combat pin instance missing from inventory for slot ${slot.wireName}',
        code: DomainFailureCodes.notEquipReady,
        details: {
          'slot': slot.wireName,
          'instanceId': instanceId,
          'reason': 'instance_missing',
          'allowed': false,
        },
      );
    }

    final slotWire = slot.wireName;
    if (_needsTransfer(item, input.characterId)) {
      _appendTransfers(steps, slotWire, item, input.characterId);
    }

    steps.add(
      PlannedEquipStep(
        id: 'equip-$slotWire',
        kind: EquipStepKind.equip,
        slot: slotWire,
        itemHash: claim.itemHash,
        instanceId: claim.instanceId,
      ),
    );
  }

  final artifact = input.artifact;
  if (artifact != null) {
    steps.add(
      PlannedEquipStep(
        id: 'artifact',
        kind: EquipStepKind.artifact,
        itemHash: artifact.hash,
        artifactConfig: List<int>.from(artifact.config),
      ),
    );
  }

  final fashion = input.fashion;
  if (fashion != null) {
    for (final entry in fashion.slots.entries) {
      final piece = entry.value;
      final owned = byHash[piece.itemHash];
      steps.add(
        PlannedEquipStep(
          id: 'fashion-${entry.key}',
          kind: EquipStepKind.fashion,
          slot: entry.key,
          itemHash: piece.itemHash,
          instanceId: owned?.instanceId,
        ),
      );
    }
  }

  return steps;
}

bool _intListEquals(List<int>? a, List<int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
