/// Set package minimum occupancy (DBR-CMP-008–010, BR-SLOT-011–014).
///
/// - Weapon / Armor: ≥2 occupied domain slots on save/attach
/// - Mod: mods on ≥2 distinct armor pieces ([modSetArmorSlotOf])
/// - Pair: both exotic weapon and exotic armor
/// - Fashion: no combat min (always ok)
///
/// Individual slots may stay empty while filling (BR-SLOT-005); set-level
/// floors apply on package save and attach (BR-ATT-006). Under-min packages
/// (including empty scaffolds) fail [setWouldPassSaveRules].
library;

import '../models/equipment.dart';
import '../models/failure_codes.dart';
import 'destiny_set_constraints.dart';

/// Minimal row for occupancy counting (active callers omit soft-removed).
class SetOccupancyItem {
  const SetOccupancyItem({
    required this.slot,
    this.removedAt,
  });

  final String slot;

  /// Soft-removed rows are ignored when [removedAt] is non-null.
  final String? removedAt;
}

/// Result of evaluating package minimum occupancy.
class SetOccupancyResult {
  const SetOccupancyResult._({
    required this.ok,
    required this.empty,
    required this.count,
    required this.required,
    required this.setType,
    this.code,
    this.message,
  });

  factory SetOccupancyResult.pass({
    required bool empty,
    required int count,
    required int required,
    required SetType setType,
  }) {
    return SetOccupancyResult._(
      ok: true,
      empty: empty,
      count: count,
      required: required,
      setType: setType,
    );
  }

  factory SetOccupancyResult.fail({
    required bool empty,
    required int count,
    required int required,
    required SetType setType,
    required String code,
    required String message,
  }) {
    return SetOccupancyResult._(
      ok: false,
      empty: empty,
      count: count,
      required: required,
      setType: setType,
      code: code,
      message: message,
    );
  }

  final bool ok;
  final bool empty;
  final int count;
  final int required;
  final SetType setType;

  /// [DomainFailureCodes.setMinItems], [modSetMinSlots], or [pairIncomplete].
  final String? code;
  final String? message;
}

List<SetOccupancyItem> _activeItems(Iterable<SetOccupancyItem> items) {
  return [
    for (final i in items)
      if (i.removedAt == null) i,
  ];
}

/// Count filled domain slots for weapon/armor (unique occupied domain slots).
int countWeaponOrArmorItems(
  SetType setType,
  Iterable<SetOccupancyItem> items,
) {
  assert(setType == SetType.weapon || setType == SetType.armor);
  final domain = setType == SetType.weapon
      ? EquipmentSlot.weaponSlots.map((s) => s.wireName).toSet()
      : EquipmentSlot.armorSlots.map((s) => s.wireName).toSet();
  final occupied = <String>{};
  for (final item in _activeItems(items)) {
    if (domain.contains(item.slot)) {
      occupied.add(item.slot);
    }
  }
  return occupied.length;
}

/// Distinct armor pieces that have ≥1 mod plug.
///
/// Preferred keys `helmet:hash`; bare armor slots count; legacy `mod`/`mod:hash`
/// without piece map count as a single synthetic piece (still one piece).
int countModPieces(Iterable<SetOccupancyItem> items) {
  final pieces = <String>{};
  var hasLegacy = false;
  for (final item in _activeItems(items)) {
    final armor = modSetArmorSlotOf(item.slot);
    if (armor != null) {
      pieces.add(armor);
      continue;
    }
    if (isLegacyModSetSlot(item.slot)) {
      hasLegacy = true;
    }
  }
  if (hasLegacy) pieces.add('__legacy_mod__');
  return pieces.length;
}

/// Pair exotic weapon / exotic armor occupancy.
({bool exoticWeapon, bool exoticArmor, int count}) countPairSlots(
  Iterable<SetOccupancyItem> items,
) {
  var exoticWeapon = false;
  var exoticArmor = false;
  for (final item in _activeItems(items)) {
    if (item.slot == EquipmentSlot.exoticWeapon.wireName) {
      exoticWeapon = true;
    }
    if (item.slot == EquipmentSlot.exoticArmor.wireName) {
      exoticArmor = true;
    }
  }
  return (
    exoticWeapon: exoticWeapon,
    exoticArmor: exoticArmor,
    count: (exoticWeapon ? 1 : 0) + (exoticArmor ? 1 : 0),
  );
}

/// Evaluate whether a set meets package minimum occupancy for save/attach.
///
/// Fashion always passes (DBR-CMP-010). Other types require their floors —
/// empty scaffolds and partial packages both fail (BR-SLOT-011–014).
SetOccupancyResult evaluateSetMinimumOccupancy(
  SetType setType,
  Iterable<SetOccupancyItem> items,
) {
  final active = _activeItems(items);

  if (setType == SetType.fashion) {
    return SetOccupancyResult.pass(
      empty: active.isEmpty,
      count: active.length,
      required: 0,
      setType: setType,
    );
  }

  if (setType == SetType.weapon || setType == SetType.armor) {
    final count = countWeaponOrArmorItems(setType, active);
    const required = 2;
    if (count < required) {
      final label = setType == SetType.weapon ? 'Weapon' : 'Armor';
      return SetOccupancyResult.fail(
        empty: count == 0,
        count: count,
        required: required,
        setType: setType,
        code: DomainFailureCodes.setMinItems,
        message:
            '$label set needs at least $required items (has $count)',
      );
    }
    return SetOccupancyResult.pass(
      empty: false,
      count: count,
      required: required,
      setType: setType,
    );
  }

  if (setType == SetType.mod) {
    final count = countModPieces(active);
    const required = 2;
    if (count < required) {
      return SetOccupancyResult.fail(
        empty: count == 0,
        count: count,
        required: required,
        setType: setType,
        code: DomainFailureCodes.modSetMinSlots,
        message:
            'Mod set needs mods on at least $required armor pieces (has $count)',
      );
    }
    return SetOccupancyResult.pass(
      empty: false,
      count: count,
      required: required,
      setType: setType,
    );
  }

  // pair
  final pair = countPairSlots(active);
  const required = 2;
  if (!pair.exoticWeapon || !pair.exoticArmor) {
    return SetOccupancyResult.fail(
      empty: pair.count == 0,
      count: pair.count,
      required: required,
      setType: setType,
      code: DomainFailureCodes.pairIncomplete,
      message: 'Pair set needs both an exotic weapon and an exotic armor',
    );
  }
  return SetOccupancyResult.pass(
    empty: false,
    count: pair.count,
    required: required,
    setType: setType,
  );
}

/// True when the package meets save/attach floors (DBR-CMP-008–010).
bool setWouldPassSaveRules(
  SetType setType,
  Iterable<SetOccupancyItem> items,
) {
  return evaluateSetMinimumOccupancy(setType, items).ok;
}

/// Plain-language message for occupancy failure codes.
String formatSetOccupancyMessage({
  required String code,
  SetType? setType,
  int? count,
  int? required,
  String? fallbackMessage,
}) {
  if (fallbackMessage != null && fallbackMessage.trim().isNotEmpty) {
    return fallbackMessage.trim();
  }
  switch (code) {
    case DomainFailureCodes.setMinItems:
      final label = setType == SetType.armor
          ? 'Armor'
          : setType == SetType.weapon
              ? 'Weapon'
              : 'Weapon/Armor';
      final need = required ?? 2;
      final has = count;
      if (has != null) {
        return '$label set needs at least $need items (has $has). '
            'Add more pieces before saving or attaching.';
      }
      return '$label set needs at least $need items before saving or attaching.';
    case DomainFailureCodes.modSetMinSlots:
      final need = required ?? 2;
      final has = count;
      if (has != null) {
        return 'Mod set needs mods on at least $need armor pieces (has $has). '
            'Spread mods across pieces before saving or attaching.';
      }
      return 'Mod set needs mods on at least $need armor pieces '
          'before saving or attaching.';
    case DomainFailureCodes.pairIncomplete:
      return 'Pair set needs both an exotic weapon and an exotic armor '
          'before saving or attaching.';
    case DomainFailureCodes.setNotAttachable:
      return 'This set does not meet package minimums and cannot be attached.';
    default:
      return 'Set does not meet package minimum occupancy.';
  }
}
