import '../models/equipment.dart';
import 'fill_in_inventory.dart';
import 'fill_in_requirement.dart';

/// Fixed armor-slot walk for 2-piece + 2-piece Fill In (class item excluded).
///
/// Daniel, Nov 12, 2026 7:00 PM PT: first two possible slots for one set, then
/// the other two for the other — make the build possibly work, not optimize.
const List<EquipmentSlot> kFillInTwoPlusTwoSlotOrder = <EquipmentSlot>[
  EquipmentSlot.helmet,
  EquipmentSlot.arms,
  EquipmentSlot.chest,
  EquipmentSlot.legs,
];

/// Assign two legendary armor sets to helmet/arms/chest/legs for Fill In.
///
/// Walk [kFillInTwoPlusTwoSlotOrder]. Give [firstSetHash] to the first two
/// slots where a matching piece is held, then [secondSetHash] to the next two
/// remaining slots where a matching piece is held. Any still-unassigned slots
/// among the four receive leftover needs for sets that still want two pieces
/// (so [matchFillIn] can report them missing). Deterministic; no optimization.
List<FillInSlotRequirement> assignFillInTwoPlusTwoSlots({
  required int firstSetHash,
  required int secondSetHash,
  required GuardianClass guardianClass,
  required Iterable<FillInInventoryItem> inventory,
}) {
  final heldBySlot = <EquipmentSlot, Set<int>>{};
  for (final slot in kFillInTwoPlusTwoSlotOrder) {
    heldBySlot[slot] = <int>{};
  }
  for (final item in inventory) {
    if (item.isExotic) continue;
    if (item.guardianClass != guardianClass) continue;
    if (!kFillInTwoPlusTwoSlotOrder.contains(item.slot)) continue;
    final setHash = item.armorSetHash;
    if (setHash == null) continue;
    heldBySlot[item.slot]!.add(setHash);
  }

  final assigned = <EquipmentSlot, int>{};

  for (final slot in kFillInTwoPlusTwoSlotOrder) {
    if (assigned.values.where((h) => h == firstSetHash).length >= 2) break;
    if (heldBySlot[slot]!.contains(firstSetHash)) {
      assigned[slot] = firstSetHash;
    }
  }

  for (final slot in kFillInTwoPlusTwoSlotOrder) {
    if (assigned.containsKey(slot)) continue;
    if (assigned.values.where((h) => h == secondSetHash).length >= 2) break;
    if (heldBySlot[slot]!.contains(secondSetHash)) {
      assigned[slot] = secondSetHash;
    }
  }

  var needFirst = 2 - assigned.values.where((h) => h == firstSetHash).length;
  var needSecond = 2 - assigned.values.where((h) => h == secondSetHash).length;
  final plan = <EquipmentSlot, int>{...assigned};
  for (final slot in kFillInTwoPlusTwoSlotOrder) {
    if (plan.containsKey(slot)) continue;
    if (needFirst > 0) {
      plan[slot] = firstSetHash;
      needFirst -= 1;
    } else if (needSecond > 0) {
      plan[slot] = secondSetHash;
      needSecond -= 1;
    } else {
      // Should not happen for a true 2+2 (four slots, four needs).
      plan[slot] = firstSetHash;
    }
  }

  return [
    for (final slot in kFillInTwoPlusTwoSlotOrder)
      FillInSlotRequirement(
        slot: slot,
        isExotic: false,
        armorSetHash: plan[slot],
      ),
  ];
}
