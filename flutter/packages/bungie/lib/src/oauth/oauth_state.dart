import 'dart:math';

/// Generates a cryptographically random OAuth CSRF `state` parameter.
///
/// Default length 32 from URL-safe unreserved characters.
String generateOAuthState({
  Random? random,
  int length = 32,
}) {
  if (length < 16) {
    throw ArgumentError.value(
      length,
      'length',
      'OAuth state length must be at least 16',
    );
  }
  final rng = random ?? Random.secure();
  const alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  final buf = StringBuffer();
  for (var i = 0; i < length; i++) {
    buf.write(alphabet[rng.nextInt(alphabet.length)]);
  }
  return buf.toString();
}

/// Validates callback `state` against the value issued at authorize time.
///
/// Returns `true` only when both strings are non-empty and equal under a
/// length-aware constant-time comparison (for equal lengths).
bool validateOAuthState({
  required String expected,
  required String actual,
}) {
  if (expected.isEmpty || actual.isEmpty) return false;
  if (expected.length != actual.length) return false;
  var diff = 0;
  for (var i = 0; i < expected.length; i++) {
    diff |= expected.codeUnitAt(i) ^ actual.codeUnitAt(i);
  }
  return diff == 0;
}
