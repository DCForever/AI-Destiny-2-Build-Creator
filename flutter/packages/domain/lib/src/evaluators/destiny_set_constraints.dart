/// Pure Destiny constraints for Set composition (UI + server).
///
/// Port of TypeScript `src/lib/sets/destinySetConstraints.ts`.
/// Slot legality + item fitness + set-wide exotic exclusivity (BR-SLOT-008/009,
/// DBR-CMP-007 kit hygiene). No IO.
library;

import '../models/equipment.dart';

/// Item kind used for set composition checks.
enum SetItemKind {
  weapon('weapon'),
  armor('armor'),
  mod('mod'),
  exoticWeapon('exotic_weapon'),
  exoticArmor('exotic_armor'),
  unknown('unknown');

  const SetItemKind(this.wireName);
  final String wireName;
}

/// Minimal item identity for constraint checks (catalog or entity cache).
class SetItemMeta {
  const SetItemMeta({
    required this.kind,
    this.equipmentSlot,
    this.isExotic,
    this.name,
    this.slotCategory,
    this.energyCost,
  });

  final SetItemKind kind;

  /// Equipment bucket from catalog/manifest:
  /// Kinetic | Energy | Power | Helmet | Gauntlets | Chest | Legs | ClassItem
  final String? equipmentSlot;

  /// True when rarity is Exotic (weapons/armor).
  final bool? isExotic;

  /// Optional display name for error messages.
  final String? name;

  /// Mods: helmet | arms | chest | legs | classItem | general | tuning
  final String? slotCategory;

  /// Mods: armor energy cost.
  final int? energyCost;
}

/// Result of a set composition constraint check.
class SetConstraintResult {
  const SetConstraintResult._({required this.ok, this.reasons = const []});

  const SetConstraintResult.ok() : this._(ok: true);

  SetConstraintResult.fail(List<String> reasons)
      : this._(ok: false, reasons: List.unmodifiable(reasons));

  final bool ok;
  final List<String> reasons;
}

/// Active occupant used for exotic exclusivity checks.
class SetOccupant {
  const SetOccupant({required this.slot, required this.meta});

  final String slot;
  final SetItemMeta meta;
}

/// Concrete fill targets offered for a set type (product slotsForSetType).
List<String> slotsForSetType(SetType type) {
  switch (type) {
    case SetType.weapon:
      return EquipmentSlot.weaponSlots.map((s) => s.wireName).toList();
    case SetType.armor:
      return EquipmentSlot.armorSlots.map((s) => s.wireName).toList();
    case SetType.pair:
      return EquipmentSlot.pairSlots.map((s) => s.wireName).toList();
    case SetType.fashion:
      return FashionSlot.values.map((s) => s.wireName).toList();
    case SetType.mod:
      return EquipmentSlot.armorSlots.map((s) => s.wireName).toList();
  }
}

/// Whether [slot] is a valid write key for [type].
bool isSlotValidForSetType(SetType type, String slot) {
  final s = slot.trim();
  if (s.isEmpty) return false;
  switch (type) {
    case SetType.weapon:
    case SetType.armor:
    case SetType.pair:
    case SetType.fashion:
      return slotsForSetType(type).contains(s);
    case SetType.mod:
      if (s == 'mod' || s.startsWith('mod:')) return true;
      if (EquipmentSlot.armorSlots.any((a) => a.wireName == s)) return true;
      final colon = s.indexOf(':');
      if (colon > 0) {
        final piece = s.substring(0, colon);
        final hashPart = s.substring(colon + 1);
        final hash = int.tryParse(hashPart);
        if (hash != null &&
            hash > 0 &&
            EquipmentSlot.armorSlots.any((a) => a.wireName == piece)) {
          return true;
        }
      }
      return false;
  }
}

/// Map set slot wire name → catalog equipment bucket label.
String? setSlotToCatalogBucket(String slot) {
  const map = {
    'primary': 'Kinetic',
    'special': 'Energy',
    'heavy': 'Power',
    'helmet': 'Helmet',
    'arms': 'Gauntlets',
    'chest': 'Chest',
    'legs': 'Legs',
    'class_item': 'ClassItem',
  };
  return map[slot];
}

/// Armor piece group for a mod-set item slot (`helmet:hash` or bare armor).
String? modSetArmorSlotOf(String slot) {
  final s = slot.trim();
  if (EquipmentSlot.armorSlots.any((a) => a.wireName == s)) return s;
  final colon = s.indexOf(':');
  if (colon > 0) {
    final piece = s.substring(0, colon);
    if (EquipmentSlot.armorSlots.any((a) => a.wireName == piece)) {
      return piece;
    }
  }
  return null;
}

bool isLegacyModSetSlot(String slot) {
  final s = slot.trim();
  return s == 'mod' || s.startsWith('mod:');
}

/// Whether a mod may sit on this armor piece (string categories from set meta).
///
/// `general` / `tuning` (and null) are allowed on any armor slot.
/// Kept private so it does not clash with manifest's ModSlotCategory helper.
bool _isModLegalForArmorSlot(String armorSlot, String? slotCategory) {
  if (slotCategory == null || slotCategory.isEmpty) return true;
  final cat = slotCategory.trim().toLowerCase();
  if (cat == 'general' || cat == 'tuning') return true;
  // Accept both classItem and class_item forms.
  final normalized = cat == 'classitem' ? 'class_item' : cat;
  final expected = switch (armorSlot) {
    'helmet' => 'helmet',
    'arms' => 'arms',
    'chest' => 'chest',
    'legs' => 'legs',
    'class_item' => 'class_item',
    _ => null,
  };
  if (expected == null) return true;
  return normalized == expected ||
      (expected == 'class_item' && (cat == 'classitem' || cat == 'class_item'));
}

/// Hard rules: legal set slot + item kind/bucket/exotic fit for that slot.
/// Fashion is intentionally permissive (manual cosmetics).
SetConstraintResult assertSetItemAllowed(
  SetType setType,
  String slot,
  SetItemMeta meta,
) {
  final reasons = <String>[];

  if (!isSlotValidForSetType(setType, slot)) {
    reasons.add('Slot "$slot" is not valid for a ${setType.wireName} set');
    return SetConstraintResult.fail(reasons);
  }

  if (setType == SetType.fashion) {
    return const SetConstraintResult.ok();
  }

  if (setType == SetType.weapon) {
    if (meta.kind == SetItemKind.armor ||
        meta.kind == SetItemKind.exoticArmor ||
        meta.kind == SetItemKind.mod) {
      reasons.add('Weapon sets only accept weapons');
    } else {
      final expected = setSlotToCatalogBucket(slot);
      final got = meta.equipmentSlot;
      if (expected != null && got != null && got.isNotEmpty && got != expected) {
        reasons.add(
          'This slot requires a $expected weapon (got $got)',
        );
      }
    }
  } else if (setType == SetType.armor) {
    if (meta.kind == SetItemKind.weapon ||
        meta.kind == SetItemKind.exoticWeapon ||
        meta.kind == SetItemKind.mod) {
      reasons.add('Armor sets only accept armor');
    } else {
      final expected = setSlotToCatalogBucket(slot);
      final got = meta.equipmentSlot;
      if (expected != null && got != null && got.isNotEmpty && got != expected) {
        reasons.add(
          'This slot requires $expected armor (got $got)',
        );
      }
    }
  } else if (setType == SetType.pair) {
    if (slot == 'exotic_weapon' || slot.contains('weapon')) {
      if (!isExoticWeaponMeta(meta)) {
        reasons.add('Pair exotic weapon slot requires an exotic weapon');
      }
    } else if (!isExoticArmorMeta(meta)) {
      reasons.add('Pair exotic armor slot requires exotic armor');
    }
  } else if (setType == SetType.mod) {
    if (meta.kind != SetItemKind.mod && meta.kind != SetItemKind.unknown) {
      reasons.add('Mod sets only accept armor / combat mods');
    } else if (meta.kind == SetItemKind.mod || meta.slotCategory != null) {
      final armorSlot = modSetArmorSlotOf(slot);
      if (armorSlot != null && meta.slotCategory != null) {
        if (!_isModLegalForArmorSlot(armorSlot, meta.slotCategory)) {
          reasons.add(
            'This mod (${meta.slotCategory}) is not legal for $armorSlot',
          );
        }
      } else if (armorSlot == null && !isLegacyModSetSlot(slot)) {
        reasons.add(
          'Mod sets require an armor piece slot (helmet, arms, chest, legs, class item)',
        );
      }
    }
  }

  if (reasons.isNotEmpty) return SetConstraintResult.fail(reasons);
  return const SetConstraintResult.ok();
}

/// Set-wide exotic exclusivity so attaching a set to a build does not
/// immediately dual-exotic (DBR-CMP-007-aligned kit hygiene).
///
/// - **Weapon sets**: at most one exotic weapon across all slots
/// - **Armor sets**: at most one exotic armor (incl. class item) across slots
/// - **Pair**: already 0–1 exotic weapon + 0–1 exotic armor by slot model
/// - Replace of the slot that already holds the exotic is allowed
///   (pass [otherItems] excluding the slot being filled/replaced).
SetConstraintResult assertSetExoticExclusivity({
  required SetType setType,
  required List<SetOccupant> otherItems,
  required SetOccupant candidate,
}) {
  if (setType == SetType.weapon) {
    if (!isExoticWeaponMeta(candidate.meta)) {
      return const SetConstraintResult.ok();
    }
    SetOccupant? existing;
    for (final o in otherItems) {
      if (isExoticWeaponMeta(o.meta)) {
        existing = o;
        break;
      }
    }
    if (existing == null) return const SetConstraintResult.ok();
    final label = (existing.meta.name?.trim().isNotEmpty ?? false)
        ? existing.meta.name!.trim()
        : existing.slot;
    return SetConstraintResult.fail([
      'This weapon set already has an exotic ($label). Destiny allows only one '
          'exotic weapon — remove or replace that piece first.',
    ]);
  }

  if (setType == SetType.armor) {
    if (!isExoticArmorMeta(candidate.meta)) {
      return const SetConstraintResult.ok();
    }
    SetOccupant? existing;
    for (final o in otherItems) {
      if (isExoticArmorMeta(o.meta)) {
        existing = o;
        break;
      }
    }
    if (existing == null) return const SetConstraintResult.ok();
    final label = (existing.meta.name?.trim().isNotEmpty ?? false)
        ? existing.meta.name!.trim()
        : existing.slot;
    return SetConstraintResult.fail([
      'This armor set already has an exotic ($label). Destiny allows only one '
          'exotic armor — remove or replace that piece first.',
    ]);
  }

  return const SetConstraintResult.ok();
}

/// Slot fit + set-wide exotic exclusivity.
SetConstraintResult assertSetCompositionAllowed(
  SetType setType,
  String slot,
  SetItemMeta meta, [
  List<SetOccupant> otherItems = const [],
]) {
  final fit = assertSetItemAllowed(setType, slot, meta);
  if (!fit.ok) return fit;
  return assertSetExoticExclusivity(
    setType: setType,
    otherItems: otherItems,
    candidate: SetOccupant(slot: slot, meta: meta),
  );
}

/// Whether this set already holds an exotic of the given kind (for catalog filters).
SetOccupant? setAlreadyHasExotic(
  SetType setType,
  List<SetOccupant> otherItems,
  String kind, // 'weapon' | 'armor'
) {
  if (kind == 'weapon' && setType == SetType.weapon) {
    for (final o in otherItems) {
      if (isExoticWeaponMeta(o.meta)) return o;
    }
  }
  if (kind == 'armor' && setType == SetType.armor) {
    for (final o in otherItems) {
      if (isExoticArmorMeta(o.meta)) return o;
    }
  }
  return null;
}

bool isExoticWeaponMeta(SetItemMeta meta) {
  if (meta.kind == SetItemKind.exoticWeapon) return true;
  if (meta.kind == SetItemKind.weapon || meta.kind == SetItemKind.unknown) {
    return meta.isExotic == true;
  }
  return false;
}

bool isExoticArmorMeta(SetItemMeta meta) {
  if (meta.kind == SetItemKind.exoticArmor) return true;
  if (meta.kind == SetItemKind.armor || meta.kind == SetItemKind.unknown) {
    return meta.isExotic == true;
  }
  return false;
}

/// Map entity-cache store names to set item kind.
SetItemKind kindFromEntityStore(String? store) {
  switch (store) {
    case 'weapons':
      return SetItemKind.weapon;
    case 'exotic-weapons':
      return SetItemKind.exoticWeapon;
    case 'exotic-armor':
      return SetItemKind.exoticArmor;
    case 'mods':
      return SetItemKind.mod;
    default:
      return SetItemKind.unknown;
  }
}

/// Build meta from a catalog pick (client fill path).
///
/// [kind] is `'weapons'`, `'armor'`, or null (defaults to weapons).
SetItemMeta setItemMetaFromCatalog({
  required bool isExotic,
  String? slot,
  String? kind,
  String? name,
}) {
  if (kind == 'armor') {
    return SetItemMeta(
      kind: isExotic ? SetItemKind.exoticArmor : SetItemKind.armor,
      equipmentSlot: slot,
      isExotic: isExotic,
      name: name,
    );
  }
  return SetItemMeta(
    kind: isExotic ? SetItemKind.exoticWeapon : SetItemKind.weapon,
    equipmentSlot: slot,
    isExotic: isExotic,
    name: name,
  );
}

/// Meta for manifest exotic / mod pickers.
SetItemMeta setItemMetaFromManifestCategory(
  String category, {
  String? slotCategory,
  int? energyCost,
  String? name,
}) {
  if (category == 'exotic-weapons') {
    return SetItemMeta(
      kind: SetItemKind.exoticWeapon,
      isExotic: true,
      name: name,
    );
  }
  if (category == 'exotic-armor') {
    return SetItemMeta(
      kind: SetItemKind.exoticArmor,
      isExotic: true,
      name: name,
    );
  }
  return SetItemMeta(
    kind: SetItemKind.mod,
    slotCategory: slotCategory,
    energyCost: energyCost,
    name: name,
  );
}

/// Whether catalog filter should hide additional exotics for this fill.
///
/// When the target slot already holds the only exotic, replace is allowed so
/// exotics remain visible. Otherwise, if the set already has an exotic of the
/// relevant kind, hide further exotics (DAC-DST-009 / BR-UI-001).
bool shouldExcludeExoticFromSetCatalog({
  required SetType setType,
  required String targetSlot,
  required List<SetOccupant> otherItemsIncludingTarget,
}) {
  final kind = switch (setType) {
    SetType.weapon => 'weapon',
    SetType.armor => 'armor',
    _ => null,
  };
  if (kind == null) return false;

  final withoutTarget = [
    for (final o in otherItemsIncludingTarget)
      if (o.slot != targetSlot) o,
  ];
  final hit = setAlreadyHasExotic(setType, withoutTarget, kind);
  return hit != null;
}
