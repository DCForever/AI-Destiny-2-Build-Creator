import 'equipment.dart';
import 'slot_claim.dart';

/// Resolved equipment map for a variant plus any multi-claim conflicts.
///
/// Mirrors TS `ResolvedVariantEquipment`. Pure shape only — no resolve logic.
class ResolvedVariantEquipment {
  const ResolvedVariantEquipment({
    this.equipment = const {},
    this.conflicts = const [],
  });

  /// First-writer (or applied) claim per slot. Partial by design.
  final Map<EquipmentSlot, SlotClaim> equipment;

  final List<SlotConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;

  SlotClaim? claimFor(EquipmentSlot slot) => equipment[slot];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResolvedVariantEquipment) return false;
    if (other.equipment.length != equipment.length) return false;
    for (final e in equipment.entries) {
      if (other.equipment[e.key] != e.value) return false;
    }
    if (other.conflicts.length != conflicts.length) return false;
    for (var i = 0; i < conflicts.length; i++) {
      if (other.conflicts[i] != conflicts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(
          equipment.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAll(conflicts),
      );
}
