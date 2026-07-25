import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PKCE code challenge method — S256 only (RFC 7636).
const String kPkceMethodS256 = 'S256';

/// High-entropy PKCE verifier + S256 challenge pair.
class PkcePair {
  const PkcePair({
    required this.codeVerifier,
    required this.codeChallenge,
    this.method = kPkceMethodS256,
  });

  /// Cryptographically random unreserved string (43–128 chars).
  final String codeVerifier;

  /// BASE64URL(SHA256(ASCII(codeVerifier))) without padding.
  final String codeChallenge;

  /// Always [kPkceMethodS256] for this package.
  final String method;
}

/// Generates a PKCE pair using [Random.secure] (or [random] for tests).
///
/// Verifier length defaults to 64 characters from the unreserved set
/// `A-Z a-z 0-9 -._~` (RFC 7636 §4.1).
PkcePair generatePkcePair({
  Random? random,
  int verifierLength = 64,
}) {
  if (verifierLength < 43 || verifierLength > 128) {
    throw ArgumentError.value(
      verifierLength,
      'verifierLength',
      'PKCE code_verifier length must be 43–128',
    );
  }
  final rng = random ?? Random.secure();
  final verifier = _randomUnreserved(rng, verifierLength);
  final challenge = s256CodeChallenge(verifier);
  return PkcePair(codeVerifier: verifier, codeChallenge: challenge);
}

/// Computes S256 `code_challenge` for an existing verifier.
String s256CodeChallenge(String codeVerifier) {
  final digest = sha256.convert(utf8.encode(codeVerifier));
  return _base64UrlNoPad(Uint8List.fromList(digest.bytes));
}

const String _unreserved =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

String _randomUnreserved(Random rng, int length) {
  final buf = StringBuffer();
  for (var i = 0; i < length; i++) {
    buf.write(_unreserved[rng.nextInt(_unreserved.length)]);
  }
  return buf.toString();
}

String _base64UrlNoPad(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}
