/// Exotic class item that only functions on the Prismatic subclass.
const String solipsismExoticName = 'Solipsism';

/// Subclass key used by the community matrix for Prismatic.
const String prismaticSubclassKey = 'prismatic';

/// True when [exoticName] is Solipsism and [subclassKey] is not Prismatic.
///
/// Comparison is case-insensitive. Empty strings are not a match.
bool isSolipsismNotPrismatic({
  required String exoticName,
  required String subclassKey,
}) {
  if (!_sameName(exoticName, solipsismExoticName)) return false;
  return !_sameName(subclassKey, prismaticSubclassKey);
}

bool _sameName(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}
