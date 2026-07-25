/// Typed failures for application use cases (DART-027).
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
  setTypeMismatch('SET_TYPE_MISMATCH');

  const UseCaseErrorCode(this.wireName);
  final String wireName;
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
