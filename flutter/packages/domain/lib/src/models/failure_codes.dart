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

  /// Core pure hard-gate codes (DART-003 surface).
  static const List<String> pureHardGateCodes = [
    tooManyExotics,
    illegalSubclassKit,
    modEnergyExceeded,
    exoticAbilityMismatch,
    noSynergy,
  ];
}
