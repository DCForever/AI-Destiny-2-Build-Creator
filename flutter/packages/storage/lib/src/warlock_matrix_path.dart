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
