/// Exotic class item that only functions on the Prismatic subclass.
const String solipsismExoticName = 'Solipsism';

/// Subclass key used by the community matrix for Prismatic.
const String prismaticSubclassKey = 'prismatic';

/// Subclass keys the matrix treats as known.
const Set<String> warlockMatrixSubclassKeys = <String>{
  'arc',
  'prismatic',
  'solar',
  'stasis',
  'strand',
  'void',
};

/// True only for a recognized subclass key, compared case-insensitively.
bool isKnownWarlockSubclass(String subclassKey) {
  return warlockMatrixSubclassKeys.contains(subclassKey.trim().toLowerCase());
}

/// True when Solipsism is paired with a known subclass other than Prismatic.
///
/// An empty or unrecognized subclass is not this mismatch.
bool isSolipsismNotPrismatic({
  required String exoticName,
  required String subclassKey,
}) {
  if (!isKnownWarlockSubclass(subclassKey)) return false;
  if (!_sameName(exoticName, solipsismExoticName)) return false;
  return !_sameName(subclassKey, prismaticSubclassKey);
}

bool _sameName(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}
