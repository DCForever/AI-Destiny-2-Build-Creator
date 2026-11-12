import 'solipsism_flag.dart';

/// One community Warlock build from the local matrix file.
class WarlockMatrixBuild {
  const WarlockMatrixBuild({
    required this.exoticName,
    required this.subclassKey,
    required this.name,
    this.creator,
    this.dimLink,
    this.isWeaponExotic = false,
  });

  /// Exotic key the build is filed under.
  final String exoticName;

  /// Matrix subclass key (`solar`, `prismatic`, …).
  final String subclassKey;

  /// Build title from the matrix.
  final String name;

  /// Optional author label.
  final String? creator;

  /// Optional `dim.gg/…` share URL from the matrix `dim` field.
  final String? dimLink;

  /// True when the row came from `weapons.cells` (exotic weapon filing).
  final bool isWeaponExotic;

  /// False when [subclassKey] is empty or not one of the six known keys.
  bool get subclassRecognized => isKnownWarlockSubclass(subclassKey);

  /// Solipsism paired with a known subclass other than Prismatic.
  ///
  /// Unresolved subclasses are not reported as this mismatch.
  bool get solipsismNotPrismatic =>
      subclassRecognized &&
      isSolipsismNotPrismatic(
        exoticName: exoticName,
        subclassKey: subclassKey,
      );
}

/// Title-case label for a matrix subclass key.
String warlockSubclassLabel(String subclassKey) {
  final trimmed = subclassKey.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}
