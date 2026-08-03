/// Stable domain failure code strings.
///
/// Values match TypeScript pure hard-gate / resolve / equip codes used by
/// evaluators (`destinyBuildConstraints`, `resolveVariant`, `equipReady`).
/// CRUD/HTTP-only codes are intentionally omitted from this P0 surface.
abstract final class DomainFailureCodes {
  static const tooManyExotics = 'TOO_MANY_EXOTICS';
  static const illegalSubclassKit = 'ILLEGAL_SUBCLASS_KIT';
  static const modEnergyExceeded = 'MOD_ENERGY_EXCEEDED';
  static const exoticAbilityMismatch = 'EXOTIC_ABILITY_MISMATCH';
  static const noSynergy = 'NO_SYNERGY';
  static const slotConflict = 'SLOT_CONFLICT';
  static const pairArmorMismatch = 'PAIR_ARMOR_MISMATCH';
  static const variantEmpty = 'VARIANT_EMPTY';
  static const defaultVariantIncomplete = 'DEFAULT_VARIANT_INCOMPLETE';
  static const notEquipReady = 'NOT_EQUIP_READY';

  /// Required synergy link unsatisfied on default save (DBR-SYN-010a / BR-VAR-050).
  static const requiredLinkUnsatisfied = 'REQUIRED_LINK_UNSATISFIED';

  /// Soft-path code used alongside exotic ability hard blocks in TS (not a hard save block alone).
  static const exoticAbilityPinProposed = 'EXOTIC_ABILITY_PIN_PROPOSED';

  /// Weapon/Armor set save/attach below ≥2 filled items (DBR-CMP-008 / BR-SLOT-011).
  static const setMinItems = 'SET_MIN_ITEMS';

  /// Mod set save/attach with mods on fewer than two armor pieces (DBR-CMP-009 / BR-SLOT-012).
  static const modSetMinSlots = 'MOD_SET_MIN_SLOTS';

  /// Pair missing exotic weapon or exotic armor (DBR-CMP-010 Pair path / BR-SLOT-014).
  static const pairIncomplete = 'PAIR_INCOMPLETE';

  /// Set fails package save floors and cannot be attached (BR-ATT-006 / DAC-SET-003).
  static const setNotAttachable = 'SET_NOT_ATTACHABLE';

  /// Core pure hard-gate codes (DART-003 surface).
  static const List<String> pureHardGateCodes = [
    tooManyExotics,
    illegalSubclassKit,
    modEnergyExceeded,
    exoticAbilityMismatch,
    noSynergy,
  ];
}
