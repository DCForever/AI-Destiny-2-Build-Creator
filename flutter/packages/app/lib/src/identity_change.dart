/// Pure identity-field change detection for DBR-ID-008 (DART-064).
///
/// Port of product `identityFieldsChanged` + `isIdentityExoticArmorChange`
/// (class-item → class-item non-identity when modes are known).
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// Confirm in-place or fork a new build when identity fields change.
enum IdentityAction {
  confirm('confirm'),
  fork('fork');

  const IdentityAction(this.wireName);
  final String wireName;

  static IdentityAction? tryParse(String? raw) {
    if (raw == null) return null;
    final t = raw.trim().toLowerCase();
    for (final v in values) {
      if (v.wireName == t) return v;
    }
    return null;
  }
}

/// Exotic armor identity mode (product `ExoticArmorIdentityMode`).
enum ExoticArmorIdentityMode {
  classic,
  classItemIntent,
}

/// Whether [slot] is an exotic class item (product `isExoticClassItemSlot`).
bool isExoticClassItemSlot(String? slot) {
  if (slot == null) return false;
  final t = slot.trim().toLowerCase();
  return t == 'classitem' || t == 'class_item' || t == 'class item';
}

/// Derive identity mode from catalog slot + hash. Unset hash → classic.
ExoticArmorIdentityMode modeFromArmorSlot(String? slot, int? hash) {
  if (hash == null) return ExoticArmorIdentityMode.classic;
  return isExoticClassItemSlot(slot)
      ? ExoticArmorIdentityMode.classItemIntent
      : ExoticArmorIdentityMode.classic;
}

/// Whether an exoticArmorHash change requires identity confirm/fork.
///
/// Class-item → class-item swaps do not; classic swaps and mode flips do.
bool isIdentityExoticArmorChange({
  required int? existingHash,
  required int? nextHash,
  required ExoticArmorIdentityMode existingMode,
  required ExoticArmorIdentityMode nextMode,
}) {
  if (existingHash == nextHash) return false;
  if (existingMode == ExoticArmorIdentityMode.classItemIntent &&
      nextMode == ExoticArmorIdentityMode.classItemIntent) {
    return false;
  }
  return true;
}

String _sortedDesignationKey(List<SynergyTypeDesignation> rows) {
  final keys = [
    for (final d in rows)
      '${d.type.wireName.trim()}|${(d.subType ?? '').trim()}',
  ]..sort();
  return keys.join(';');
}

/// Detect which identity fields change between stored build and next values.
///
/// Returns empty when no identity confirm is required.
///
/// [existingExoticArmorSlot] / [nextExoticArmorSlot] are optional catalog slots
/// (e.g. `ClassItem`). When unknown, any exotic armor hash change is treated
/// as classic identity-affecting (safe default).
///
/// Subclass identity is **tree name only** (DBR-ID-008a / DBR-SUB-001).
/// Aspect/fragment/ability kit diffs are variant composition (DBR-ID-008b,
/// DBR-ID-010) and never raise IDENTITY_CONFIRM_REQUIRED.
List<String> detectIdentityFieldChanges({
  required List<SynergyTypeDesignation> existingSynergyTypes,
  required List<SynergyTypeDesignation>? nextSynergyTypes,
  required int? existingExoticArmorHash,
  required int? nextExoticArmorHash,
  bool setExoticArmor = false,
  String? existingExoticArmorSlot,
  String? nextExoticArmorSlot,
  required int? existingExoticWeaponHash,
  required int? nextExoticWeaponHash,
  bool setExoticWeapon = false,
  required String? existingPinnedSuper,
  required String? nextPinnedSuper,
  bool setPinnedSuper = false,
  required SubclassKit existingSubclass,
  SubclassKit? nextSubclass,
}) {
  final fields = <String>[];

  if (nextSynergyTypes != null) {
    final next = _sortedDesignationKey(nextSynergyTypes);
    final prev = _sortedDesignationKey(existingSynergyTypes);
    if (next != prev) fields.add('synergyTypes');
  }

  if (setExoticArmor) {
    final existingMode =
        modeFromArmorSlot(existingExoticArmorSlot, existingExoticArmorHash);
    final nextMode = modeFromArmorSlot(nextExoticArmorSlot, nextExoticArmorHash);
    if (isIdentityExoticArmorChange(
      existingHash: existingExoticArmorHash,
      nextHash: nextExoticArmorHash,
      existingMode: existingMode,
      nextMode: nextMode,
    )) {
      fields.add('exoticArmorHash');
    }
  }

  if (setExoticWeapon && nextExoticWeaponHash != existingExoticWeaponHash) {
    fields.add('exoticWeaponHash');
  }

  if (setPinnedSuper) {
    final a = existingPinnedSuper?.trim() ?? '';
    final b = nextPinnedSuper?.trim() ?? '';
    if (a != b) fields.add('pinnedSuper');
  }

  // DBR-ID-008a: only subclass **tree** change is identity (not kit picks).
  if (nextSubclass != null &&
      !subclassTreeNameEqual(existingSubclass.name, nextSubclass.name)) {
    fields.add('subclass');
  }

  return fields;
}
