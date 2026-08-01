import 'equipment.dart';

/// One equipment claim for a slot after expanding attachments / exotic pins.
///
/// Mirrors TS `SlotClaim` in `resolveVariant.ts`. No merge/conflict logic here.
class SlotClaim {
  const SlotClaim({
    required this.slot,
    required this.itemHash,
    required this.itemName,
    required this.source,
    this.setId,
    this.selectedPerks,
    this.instanceId,
  });

  final EquipmentSlot slot;
  final int itemHash;
  final String itemName;
  final ClaimSource source;
  final String? setId;
  final List<int>? selectedPerks;

  /// Null/absent instance pin ⇒ wishlist-capable claim (not equip-ready by itself).
  final String? instanceId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SlotClaim &&
        other.slot == slot &&
        other.itemHash == itemHash &&
        other.itemName == itemName &&
        other.source == source &&
        other.setId == setId &&
        _listEquals(other.selectedPerks, selectedPerks) &&
        other.instanceId == instanceId;
  }

  @override
  int get hashCode => Object.hash(
        slot,
        itemHash,
        itemName,
        source,
        setId,
        Object.hashAll(selectedPerks ?? const []),
        instanceId,
      );

  @override
  String toString() =>
      'SlotClaim(slot: ${slot.wireName}, itemHash: $itemHash, source: ${source.wireName})';
}

/// Expanded set item before conversion to [SlotClaim].
///
/// Mirrors TS `ExpandedSetItem`.
class ExpandedSetItem {
  const ExpandedSetItem({
    required this.slot,
    required this.itemHash,
    required this.itemName,
    required this.setId,
    required this.setType,
    this.selectedPerks,
    this.instanceId,
  });

  final EquipmentSlot slot;
  final int itemHash;
  final String itemName;
  final String setId;
  final SetType setType;
  final List<int>? selectedPerks;
  final String? instanceId;

  SlotClaim toSlotClaim() {
    return SlotClaim(
      slot: slot,
      itemHash: itemHash,
      itemName: itemName,
      source: setType == SetType.pair ? ClaimSource.pairSet : ClaimSource.set,
      setId: setId,
      selectedPerks: selectedPerks,
      instanceId: instanceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpandedSetItem &&
        other.slot == slot &&
        other.itemHash == itemHash &&
        other.itemName == itemName &&
        other.setId == setId &&
        other.setType == setType &&
        _listEquals(other.selectedPerks, selectedPerks) &&
        other.instanceId == instanceId;
  }

  @override
  int get hashCode => Object.hash(
        slot,
        itemHash,
        itemName,
        setId,
        setType,
        Object.hashAll(selectedPerks ?? const []),
        instanceId,
      );
}

/// Multiple claims on the same slot.
class SlotConflict {
  const SlotConflict({
    required this.slot,
    required this.claimants,
  });

  final EquipmentSlot slot;
  final List<SlotClaim> claimants;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SlotConflict &&
        other.slot == slot &&
        _claimListEquals(other.claimants, claimants);
  }

  @override
  int get hashCode => Object.hash(slot, Object.hashAll(claimants));
}

bool _listEquals(List<int>? a, List<int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _claimListEquals(List<SlotClaim> a, List<SlotClaim> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
