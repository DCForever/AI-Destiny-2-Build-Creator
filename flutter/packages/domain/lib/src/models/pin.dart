import 'equipment.dart';

/// Pin kind for an applied combat slot claim (TS `PinStatusKind`).
enum PinStatusKind {
  wishlist('wishlist'),
  pinned('pinned'),
  stale('stale');

  const PinStatusKind(this.wireName);
  final String wireName;
}

/// Why a pin is stale (TS `PinStatus.reason`).
enum PinStaleReason {
  instanceMissing('instance_missing'),
  hashMismatch('hash_mismatch');

  const PinStaleReason(this.wireName);
  final String wireName;
}

/// Per-slot pin evaluation result shape (no evaluation logic here).
class PinStatus {
  const PinStatus({
    required this.slot,
    required this.status,
    this.instanceId,
    this.reason,
  });

  final EquipmentSlot slot;
  final PinStatusKind status;
  final String? instanceId;
  final PinStaleReason? reason;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PinStatus &&
        other.slot == slot &&
        other.status == status &&
        other.instanceId == instanceId &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(slot, status, instanceId, reason);
}

/// Aggregate equip-ready result shape (TS `EquipReadyResult`).
///
/// Evaluation lives in DART-006; this type only carries the result.
class EquipReadyResult {
  const EquipReadyResult({
    required this.equipReady,
    this.pinStatuses = const [],
  });

  final bool equipReady;
  final List<PinStatus> pinStatuses;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EquipReadyResult) return false;
    if (other.equipReady != equipReady) return false;
    if (other.pinStatuses.length != pinStatuses.length) return false;
    for (var i = 0; i < pinStatuses.length; i++) {
      if (other.pinStatuses[i] != pinStatuses[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(equipReady, Object.hashAll(pinStatuses));
}
