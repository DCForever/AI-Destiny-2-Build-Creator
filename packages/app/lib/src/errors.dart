/// Typed failures for application use cases (DART-027 / DART-028).
enum UseCaseErrorCode {
  invalidArgument('INVALID_ARGUMENT'),
  notFound('NOT_FOUND'),
  duplicateSetName('DUPLICATE_SET_NAME'),
  setInUse('SET_IN_USE'),
  invalidSetType('INVALID_SET_TYPE'),
  invalidSynergyType('INVALID_SYNERGY_TYPE'),
  invalidSynergyLinkKind('INVALID_SYNERGY_LINK_KIND'),
  designationImmutable('DESIGNATION_IMMUTABLE'),
  invalidAttachmentMode('INVALID_ATTACHMENT_MODE'),
  fashionLimit('FASHION_LIMIT'),
  setTypeMismatch('SET_TYPE_MISMATCH'),

  /// Hard-gate codes (wire names match [DomainFailureCodes] / product API).
  noSynergy('NO_SYNERGY'),
  illegalSubclassKit('ILLEGAL_SUBCLASS_KIT'),
  exoticAbilityMismatch('EXOTIC_ABILITY_MISMATCH'),
  tooManyExotics('TOO_MANY_EXOTICS'),
  modEnergyExceeded('MOD_ENERGY_EXCEEDED'),
  slotConflict('SLOT_CONFLICT'),
  pairArmorMismatch('PAIR_ARMOR_MISMATCH'),
  variantEmpty('VARIANT_EMPTY'),
  defaultVariantIncomplete('DEFAULT_VARIANT_INCOMPLETE'),

  /// Optimizer materialize / apply (DART-035).
  invalidCombination('INVALID_COMBINATION'),
  instanceNotOwned('INSTANCE_NOT_OWNED'),
  exoticLimit('EXOTIC_LIMIT'),

  /// DBR-ID-008: identity change requires Confirm in-place or Fork (DART-064).
  identityConfirmRequired('IDENTITY_CONFIRM_REQUIRED');

  const UseCaseErrorCode(this.wireName);
  final String wireName;

  /// Map a domain hard-block code string to a use-case code when known.
  static UseCaseErrorCode? fromDomainCode(String code) {
    for (final v in UseCaseErrorCode.values) {
      if (v.wireName == code) return v;
    }
    return null;
  }
}

/// Application-layer exception (not HTTP). Hosts map to UI messages later.
class UseCaseException implements Exception {
  UseCaseException(
    this.code,
    this.message, {
    this.details = const {},
  });

  final UseCaseErrorCode code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'UseCaseException(${code.wireName}): $message';
}
