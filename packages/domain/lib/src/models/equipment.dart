/// Equipment slots, set types, and claim sources — wire names match TypeScript.
library;

/// Combat + pair equipment slots used by resolve/claims (TS `EquipmentSlot`).
enum EquipmentSlot {
  primary('primary'),
  special('special'),
  heavy('heavy'),
  helmet('helmet'),
  arms('arms'),
  chest('chest'),
  legs('legs'),
  classItem('class_item'),
  exoticWeapon('exotic_weapon'),
  exoticArmor('exotic_armor');

  const EquipmentSlot(this.wireName);
  final String wireName;

  static EquipmentSlot? tryParse(String wire) {
    for (final v in EquipmentSlot.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }

  static const List<EquipmentSlot> weaponSlots = [
    EquipmentSlot.primary,
    EquipmentSlot.special,
    EquipmentSlot.heavy,
  ];

  static const List<EquipmentSlot> armorSlots = [
    EquipmentSlot.helmet,
    EquipmentSlot.arms,
    EquipmentSlot.chest,
    EquipmentSlot.legs,
    EquipmentSlot.classItem,
  ];

  static const List<EquipmentSlot> pairSlots = [
    EquipmentSlot.exoticWeapon,
    EquipmentSlot.exoticArmor,
  ];

  /// Combat slots considered by equip-ready evaluation (weapons + armor).
  static const List<EquipmentSlot> combatSlots = [
    EquipmentSlot.primary,
    EquipmentSlot.special,
    EquipmentSlot.heavy,
    EquipmentSlot.helmet,
    EquipmentSlot.arms,
    EquipmentSlot.chest,
    EquipmentSlot.legs,
    EquipmentSlot.classItem,
  ];
}

/// Fashion-only slots (not combat claims).
enum FashionSlot {
  shaderOrnament('shader_ornament'),
  ghost('ghost'),
  sparrow('sparrow'),
  ship('ship'),
  emblem('emblem'),
  finisher('finisher');

  const FashionSlot(this.wireName);
  final String wireName;
}

/// Product set types (TS `SetType`).
enum SetType {
  weapon('weapon'),
  armor('armor'),
  mod('mod'),
  pair('pair'),
  fashion('fashion');

  const SetType(this.wireName);
  final String wireName;

  static SetType? tryParse(String wire) {
    for (final v in SetType.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Provenance of a [SlotClaim] (TS `SlotClaim.source`).
enum ClaimSource {
  set('set'),
  buildExoticArmor('build_exotic_armor'),
  variantExoticWeapon('variant_exotic_weapon'),
  pairSet('pair_set');

  const ClaimSource(this.wireName);
  final String wireName;

  static ClaimSource? tryParse(String wire) {
    for (final v in ClaimSource.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Attachment mode for variant ↔ set links.
enum AttachmentMode {
  live('live'),
  snapshot('snapshot');

  const AttachmentMode(this.wireName);
  final String wireName;
}

/// Guardian class identity on a build.
enum GuardianClass {
  titan('Titan'),
  hunter('Hunter'),
  warlock('Warlock');

  const GuardianClass(this.wireName);
  final String wireName;

  static GuardianClass? tryParse(String wire) {
    for (final v in GuardianClass.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}
