/// Environment variable that points at the local Warlock matrix file.
const String warlockMatrixPathEnv = 'WARLOCK_MATRIX_PATH';

/// Path from [environment], or null when unset or blank.
String? warlockMatrixPathFromEnvironment(Map<String, String> environment) {
  final raw = environment[warlockMatrixPathEnv];
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

/// Resolve the Warlock matrix path with fixed precedence:
/// saved Settings path → [warlockMatrixPathEnv] → none.
///
/// Does not touch the matrix file. Blank/whitespace [savedSetting] is ignored
/// so the environment can still apply.
String? resolveWarlockMatrixPath({
  String? savedSetting,
  Map<String, String> environment = const <String, String>{},
}) {
  final saved = savedSetting?.trim();
  if (saved != null && saved.isNotEmpty) return saved;
  return warlockMatrixPathFromEnvironment(environment);
}
