import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

import 'token_codec.dart';

/// Secure persistence port for [BungieTokens] (DART-023).
///
/// Implementations MUST NOT write access/refresh tokens into SQLite plaintext.
abstract class TokenStore {
  Future<BungieTokens?> read();
  Future<void> write(BungieTokens tokens);

  /// Clears Credential Locker / primary **and** any legacy sidecar.
  ///
  /// Use for explicit sign-out. Prefer [clearSecureOnly] when recovering from
  /// a corrupt Locker so a migrate-able sidecar is preserved.
  Future<void> clear();

  /// Clears Credential Locker / primary only; never deletes the legacy sidecar.
  Future<void> clearSecureOnly();
}

/// Thrown when the secure store has a payload that cannot be parsed.
///
/// Message is intentionally non-secret and safe for logs / UI.
class TokenStoreCorruptException implements Exception {
  const TokenStoreCorruptException([
    this.message =
        'Sign-in data could not be read - please sign in again',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the encoded payload exceeds Windows Credential Manager limits.
///
/// Message is intentionally non-secret and safe for logs / UI.
class TokenStoreOverflowException implements Exception {
  const TokenStoreOverflowException([
    this.message = 'Sign-in data is too large to store securely',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// In-memory store for unit/widget tests.
class MemoryTokenStore implements TokenStore {
  BungieTokens? _tokens;

  @override
  Future<BungieTokens?> read() async => _tokens;

  @override
  Future<void> write(BungieTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    _tokens = null;
  }
}

/// Default secure-storage key for the Windows host OAuth payload.
///
/// Fixed launch-independent name used as the Windows Credential Locker /
/// Credential Manager target for every build/launch method.
const String kBungieTokenStorageKey = 'destiny2.bungie.oauth.tokens';

/// Legacy plaintext sidecar filename (migration source only — never written).
const String kBungieTokenFileName = 'oauth_session.tokens.json';

/// Windows `CRED_MAX_CREDENTIAL_BLOB_SIZE` (5 × 512). Refuse oversized writes
/// rather than risking silent truncation in Credential Manager.
const int kMaxSecureTokenPayloadBytes = 2560;

/// OS-backed secure store (`flutter_secure_storage` / Windows Credential Locker).
class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    this.storageKey = kBungieTokenStorageKey,
    this.maxPayloadBytes = kMaxSecureTokenPayloadBytes,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              // Explicit Windows options: keep credentials across process
              // restarts of the same application identity.
              wOptions: WindowsOptions(),
            );

  final FlutterSecureStorage _storage;
  final String storageKey;
  final int maxPayloadBytes;

  @override
  Future<BungieTokens?> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = decodeBungieTokens(raw);
    if (decoded == null) {
      throw const TokenStoreCorruptException();
    }
    return decoded;
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    final encoded = encodeBungieTokens(tokens);
    final byteLength = utf8.encode(encoded).length;
    if (byteLength > maxPayloadBytes) {
      throw const TokenStoreOverflowException();
    }
    await _storage.write(key: storageKey, value: encoded);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: storageKey);
  }

  @override
  Future<void> clearSecureOnly() async {
    await _storage.delete(key: storageKey);
  }
}

/// Legacy file store under [baseDir] (application-support).
///
/// Kept only so [DualTokenStore] can one-time migrate into Credential Locker.
/// New writes must not create this file.
class FileTokenStore implements TokenStore {
  FileTokenStore({
    required String baseDir,
    this.fileName = kBungieTokenFileName,
  }) : _file = File(p.join(baseDir, fileName));

  final File _file;
  final String fileName;

  /// Exact sidecar path — the only file [DualTokenStore] may delete.
  String get absolutePath => _file.absolute.path;

  @override
  Future<BungieTokens?> read() async {
    try {
      if (!await _file.exists()) return null;
      return decodeBungieTokens(await _file.readAsString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(encodeBungieTokens(tokens), flush: true);
  }

  @override
  Future<void> clear() async {
    try {
      if (await _file.exists()) {
        await _file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> clearSecureOnly() async {
    // File store is never the Credential Locker.
  }
}

/// Credential Locker is the only live store; legacy sidecar is migrate-only.
///
/// - [write] / normal [read] never create or heal the plaintext sidecar.
/// - One-time migration: empty secure store + existing sidecar → write secure,
///   read-back verify, then delete only that sidecar path.
/// - Failed verify clears the just-written Locker entry and keeps the sidecar.
/// - Corrupt secure payload → [TokenStoreCorruptException] (no plaintext
///   fallback).
class DualTokenStore implements TokenStore {
  DualTokenStore({
    required TokenStore primary,
    required TokenStore secondary,
    void Function(String message)? report,
  })  : _primary = primary,
        _secondary = secondary,
        _report = report ?? _defaultReport;

  final TokenStore _primary;
  final TokenStore _secondary;
  final void Function(String message) _report;

  static void _defaultReport(String message) {
    // ignore: avoid_print
    print(message);
  }

  @override
  Future<BungieTokens?> read() async {
    try {
      final fromPrimary = await _primary.read();
      if (fromPrimary != null) return fromPrimary;
    } on TokenStoreCorruptException {
      // Fail closed — never fall back to plaintext.
      rethrow;
    } catch (_) {
      _report('OAuth: secure token read failed');
      return null;
    }
    return _migrateFromSidecarIfPresent();
  }

  /// Empty secure store + legacy sidecar → promote, verify, then delete sidecar.
  Future<BungieTokens?> _migrateFromSidecarIfPresent() async {
    BungieTokens? fromSidecar;
    try {
      fromSidecar = await _secondary.read();
    } catch (_) {
      _report('OAuth: legacy token sidecar read failed');
      return null;
    }
    if (fromSidecar == null) return null;

    try {
      await _primary.write(fromSidecar);
    } catch (_) {
      _report('OAuth: token migration write failed — sidecar kept');
      return null;
    }

    BungieTokens? readBack;
    try {
      readBack = await _primary.read();
    } on TokenStoreCorruptException {
      await _rollbackPrimaryKeepSidecar(
        'OAuth: token migration read-back corrupt — sidecar kept',
      );
      return null;
    } catch (_) {
      await _rollbackPrimaryKeepSidecar(
        'OAuth: token migration read-back failed — sidecar kept',
      );
      return null;
    }

    if (readBack == null || !_tokensMatch(fromSidecar, readBack)) {
      await _rollbackPrimaryKeepSidecar(
        'OAuth: token migration verify failed — sidecar kept',
      );
      return null;
    }

    try {
      await _secondary.clear();
    } catch (_) {
      _report('OAuth: token migration sidecar delete failed');
      // Secure store is good; still return tokens.
    }
    _report('OAuth: migrated tokens into secure store');
    return readBack;
  }

  /// Drop the just-written Locker payload; never touch the sidecar.
  Future<void> _rollbackPrimaryKeepSidecar(String message) async {
    try {
      await _primary.clearSecureOnly();
    } catch (_) {}
    _report(message);
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    // Secure store only — never recreate the plaintext sidecar.
    await _primary.write(tokens);
  }

  @override
  Future<void> clear() async {
    try {
      await _primary.clear();
    } catch (_) {}
    // Explicit sign-out may remove the legacy sidecar at its exact path only.
    try {
      await _secondary.clear();
    } catch (_) {}
  }

  @override
  Future<void> clearSecureOnly() async {
    try {
      await _primary.clearSecureOnly();
    } catch (_) {}
  }
}

bool _tokensMatch(BungieTokens a, BungieTokens b) {
  return a.accessToken == b.accessToken &&
      a.refreshToken == b.refreshToken &&
      a.bungieMembershipId == b.bungieMembershipId &&
      a.expiresAt.toUtc().isAtSameMomentAs(b.expiresAt.toUtc()) &&
      a.refreshExpiresAt.toUtc().isAtSameMomentAs(b.refreshExpiresAt.toUtc());
}
