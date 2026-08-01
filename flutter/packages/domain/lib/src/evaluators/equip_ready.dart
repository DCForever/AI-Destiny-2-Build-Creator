/// Pure equipReady / wishlist vs owned-pin gates.
///
/// Mirrors TypeScript `src/lib/builds/equipReady.ts`.
/// No inventory DB load or equip execution (callers pass a pin index).
library;

import '../models/equipment.dart';
import '../models/failure_codes.dart';
import '../models/pin.dart';
import '../models/resolved_variant.dart';
import '../models/slot_claim.dart';

/// One owned inventory row used to build a pin index (pure input DTO).
class InventoryPinItem {
  const InventoryPinItem({
    required this.instanceId,
    required this.itemHash,
  });

  final String instanceId;
  final int itemHash;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryPinItem &&
        other.instanceId == instanceId &&
        other.itemHash == itemHash;
  }

  @override
  int get hashCode => Object.hash(instanceId, itemHash);
}

/// instanceId → itemHash lookup for equip-ready evaluation.
typedef InventoryPinIndex = Map<String, int>;

/// Domain failure for equip-ready assert.
///
/// Codes match product API codes so adapters can map to HTTP later.
class EquipReadyException implements Exception {
  const EquipReadyException(
    this.message, {
    required this.code,
    this.details,
  });

  final String code;
  final String message;
  final Map<String, Object?>? details;

  @override
  String toString() => 'EquipReadyException($code: $message)';
}

/// Build a pure inventory pin index from owned instance rows.
InventoryPinIndex buildInventoryPinIndex(List<InventoryPinItem> items) {
  final map = <String, int>{};
  for (final item in items) {
    map[item.instanceId] = item.itemHash;
  }
  return map;
}

PinStatus _statusForClaim(SlotClaim claim, InventoryPinIndex inventory) {
  final instanceId = claim.instanceId;
  if (instanceId == null || instanceId.isEmpty) {
    return PinStatus(slot: claim.slot, status: PinStatusKind.wishlist);
  }
  final ownedHash = inventory[instanceId];
  if (ownedHash == null) {
    return PinStatus(
      slot: claim.slot,
      status: PinStatusKind.stale,
      instanceId: instanceId,
      reason: PinStaleReason.instanceMissing,
    );
  }
  if (ownedHash != claim.itemHash) {
    return PinStatus(
      slot: claim.slot,
      status: PinStatusKind.stale,
      instanceId: instanceId,
      reason: PinStaleReason.hashMismatch,
    );
  }
  return PinStatus(
    slot: claim.slot,
    status: PinStatusKind.pinned,
    instanceId: instanceId,
  );
}

/// Evaluate equip-ready over applied combat slots only (empty gaps ignored).
EquipReadyResult computeEquipReady(
  ResolvedVariantEquipment resolved,
  InventoryPinIndex inventory,
) {
  final pinStatuses = <PinStatus>[];
  for (final slot in EquipmentSlot.combatSlots) {
    final claim = resolved.equipment[slot];
    if (claim == null) continue;
    pinStatuses.add(_statusForClaim(claim, inventory));
  }
  final equipReady = pinStatuses.isNotEmpty &&
      pinStatuses.every((s) => s.status == PinStatusKind.pinned);
  return EquipReadyResult(equipReady: equipReady, pinStatuses: pinStatuses);
}

/// Throw [EquipReadyException] when the variant is not equip-ready.
void assertEquipReady(EquipReadyResult result) {
  if (result.equipReady) return;
  throw EquipReadyException(
    'Variant is not equip-ready: applied slots need non-stale owned instance pins',
    code: DomainFailureCodes.notEquipReady,
    details: {
      'pinStatuses': [
        for (final s in result.pinStatuses)
          {
            'slot': s.slot.wireName,
            'status': s.status.wireName,
            if (s.instanceId != null) 'instanceId': s.instanceId,
            if (s.reason != null) 'reason': s.reason!.wireName,
          },
      ],
      'allowed': false,
    },
  );
}
