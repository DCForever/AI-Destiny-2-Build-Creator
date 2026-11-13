import '../models/equipment.dart';
import 'fill_in_inventory.dart';
import 'fill_in_requirement.dart';
import 'fill_in_result.dart';
import 'fill_in_similar_weapon.dart';

/// One slot's Fill In preview: current build label → proposed substitute.
///
/// Pure / read-only — never mutates inventory or Bungie state. Hosts persist
/// applied diffs via the Fill In store and update the app build copy.
class FillInSlotDiff {
  const FillInSlotDiff({
    required this.slot,
    required this.currentLabel,
    required this.isHeld,
    this.substituteLabel,
    this.substituteInstanceId,
    this.substituteItemHash,
    this.heldInstanceId,
    this.heldItemHash,
  });

  final EquipmentSlot slot;

  /// Display name currently on the build for this slot.
  final String currentLabel;

  /// True when inventory already holds a matching copy of [currentLabel].
  final bool isHeld;

  /// Proposed substitute display name (null when none / already held as-is).
  final String? substituteLabel;

  final String? substituteInstanceId;
  final int? substituteItemHash;

  /// Held matching instance when [isHeld] (for Apply to character pins).
  final String? heldInstanceId;
  final int? heldItemHash;

  /// True when Apply to build would change the slot label.
  bool get wouldSubstitute =>
      substituteLabel != null &&
      substituteLabel!.trim().isNotEmpty &&
      substituteLabel!.trim().toLowerCase() != currentLabel.trim().toLowerCase();

  /// Instance to equip after Fill In apply (substitute or held match).
  String? get applyInstanceId =>
      wouldSubstitute ? substituteInstanceId : heldInstanceId;

  int? get applyItemHash => wouldSubstitute ? substituteItemHash : heldItemHash;

  String get applyLabel => wouldSubstitute
      ? (substituteLabel ?? currentLabel)
      : currentLabel;
}

/// Build current→substitute diffs from a Fill In match + inventory.
///
/// - Held slots: keep current label; pin the held instance for equip.
/// - Missing weapon slots: use [suggestSimilarWeapon] when a need is given.
/// - Missing armor slots: pick a held copy in the same slot + class
///   (prefer same [FillInSlotRequirement.armorSetHash] when set).
List<FillInSlotDiff> planFillInSubstitutes({
  required FillInBuildResult match,
  required FillInBuildRequirement requirement,
  required Iterable<FillInInventoryItem> inventory,
  required Map<EquipmentSlot, String> currentLabels,
  FillInWeaponNeed? weaponNeed,
}) {
  final inv = inventory.toList(growable: false);
  final needBySlot = <EquipmentSlot, FillInSlotRequirement>{
    for (final s in requirement.slots) s.slot: s,
  };
  final diffs = <FillInSlotDiff>[];

  for (final slotMatch in match.slots) {
    final slot = slotMatch.slot;
    final current = (currentLabels[slot] ?? '').trim();
    final need = needBySlot[slot];

    if (slotMatch.isHeld) {
      final held = _findHeldMatch(
        inventory: inv,
        guardianClass: requirement.guardianClass,
        need: need,
        currentLabel: current,
      );
      diffs.add(
        FillInSlotDiff(
          slot: slot,
          currentLabel: current.isEmpty ? slot.wireName : current,
          isHeld: true,
          heldInstanceId: held?.instanceId,
          heldItemHash: held?.itemHash,
        ),
      );
      continue;
    }

    // Missing — propose a substitute when possible.
    if (_isWeaponSlot(slot)) {
      final similar = weaponNeed == null
          ? null
          : suggestSimilarWeapon(need: weaponNeed, heldWeapons: inv);
      final item = similar?.item;
      diffs.add(
        FillInSlotDiff(
          slot: slot,
          currentLabel: current.isEmpty ? slot.wireName : current,
          isHeld: false,
          substituteLabel: item?.name,
          substituteInstanceId: item?.instanceId,
          substituteItemHash: item?.itemHash,
        ),
      );
      continue;
    }

    final armorSub = _suggestArmorSubstitute(
      inventory: inv,
      guardianClass: requirement.guardianClass,
      need: need,
      slot: slot,
    );
    diffs.add(
      FillInSlotDiff(
        slot: slot,
        currentLabel: current.isEmpty ? slot.wireName : current,
        isHeld: false,
        substituteLabel: armorSub?.name,
        substituteInstanceId: armorSub?.instanceId,
        substituteItemHash: armorSub?.itemHash,
      ),
    );
  }

  return List<FillInSlotDiff>.unmodifiable(diffs);
}

FillInInventoryItem? _findHeldMatch({
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required FillInSlotRequirement? need,
  required String currentLabel,
}) {
  if (need == null) return null;
  final wantName = currentLabel.trim().toLowerCase();

  FillInInventoryItem? byName;
  FillInInventoryItem? byNeed;

  for (final item in inventory) {
    if (!_matchesNeed(item, guardianClass, need)) continue;
    byNeed ??= item;
    final name = (item.name ?? '').trim().toLowerCase();
    if (wantName.isNotEmpty && name == wantName) {
      byName = item;
      break;
    }
  }
  return byName ?? byNeed;
}

FillInInventoryItem? _suggestArmorSubstitute({
  required List<FillInInventoryItem> inventory,
  required GuardianClass guardianClass,
  required FillInSlotRequirement? need,
  required EquipmentSlot slot,
}) {
  FillInInventoryItem? sameSet;
  FillInInventoryItem? anySlot;

  for (final item in inventory) {
    if (item.slot != slot) continue;
    if (item.guardianClass != guardianClass) continue;
    if (_isWeaponSlot(item.slot)) continue;

    anySlot ??= item;
    if (need != null &&
        !need.isExotic &&
        need.armorSetHash != null &&
        item.armorSetHash == need.armorSetHash) {
      sameSet ??= item;
    }
    if (need != null &&
        need.isExotic &&
        need.exoticItemHash != null &&
        item.isExotic &&
        item.itemHash == need.exoticItemHash) {
      return item;
    }
  }
  return sameSet ?? anySlot;
}

bool _matchesNeed(
  FillInInventoryItem item,
  GuardianClass guardianClass,
  FillInSlotRequirement need,
) {
  if (_isWeaponSlot(need.slot) || need.slot == EquipmentSlot.exoticWeapon) {
    if (!_isWeaponSlot(item.slot)) return false;
    if (need.slot != EquipmentSlot.exoticWeapon && item.slot != need.slot) {
      return false;
    }
    if (need.exoticItemHash != null) {
      return item.itemHash == need.exoticItemHash;
    }
    return item.isExotic;
  }
  if (item.guardianClass != guardianClass) return false;
  if (item.slot != need.slot) return false;
  if (need.isExotic) {
    if (!item.isExotic) return false;
    if (need.exoticItemHash != null) {
      return item.itemHash == need.exoticItemHash;
    }
    return true;
  }
  if (item.isExotic) return false;
  if (need.armorSetHash != null) {
    return item.armorSetHash == need.armorSetHash;
  }
  return true;
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}
