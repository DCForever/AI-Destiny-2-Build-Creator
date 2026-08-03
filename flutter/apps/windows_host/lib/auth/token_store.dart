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
  Future<void> clear();
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
}

/// Default secure-storage key for the Windows host OAuth payload.
const String kBungieTokenStorageKey = 'destiny2.bungie.oauth.tokens';

/// Sidecar filename under application-support (fallback if Credential Locker fails).
const String kBungieTokenFileName = 'oauth_session.tokens.json';

/// OS-backed secure store (`flutter_secure_storage` / Windows Credential Locker).
class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    this.storageKey = kBungieTokenStorageKey,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              // Explicit Windows options: keep credentials across process
              // restarts of the same application identity.
              wOptions: WindowsOptions(),
            );

  final FlutterSecureStorage _storage;
  final String storageKey;

  @override
  Future<BungieTokens?> read() async {
    final raw = await _storage.read(key: storageKey);
    return decodeBungieTokens(raw);
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    await _storage.write(key: storageKey, value: encodeBungieTokens(tokens));
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: storageKey);
  }
}

/// File fallback under [baseDir] (typically application-support).
///
/// Used when Windows Credential Locker is flaky across `flutter run` rebuilds.
/// Still local-only (not SQLite library tables). Prefer [DualTokenStore].
class FileTokenStore implements TokenStore {
  FileTokenStore({
    required String baseDir,
    this.fileName = kBungieTokenFileName,
  }) : _file = File(p.join(baseDir, fileName));

  final File _file;
  final String fileName;

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
}

/// Writes to both secure + file stores; reads secure first, then file.
///
/// Survives Credential Manager miss on cold start while still preferring OS
/// secure storage when available.
class DualTokenStore implements TokenStore {
  DualTokenStore({
    required TokenStore primary,
    required TokenStore secondary,
  })  : _primary = primary,
        _secondary = secondary;

  final TokenStore _primary;
  final TokenStore _secondary;

  @override
  Future<BungieTokens?> read() async {
    try {
      final fromPrimary = await _primary.read();
      if (fromPrimary != null) {
        // Heal secondary if primary is the only copy.
        try {
          await _secondary.write(fromPrimary);
        } catch (_) {}
        return fromPrimary;
      }
    } catch (e) {
      // ignore: avoid_print
      print('OAuth: primary token read failed: $e');
    }
    try {
      final fromSecondary = await _secondary.read();
      if (fromSecondary != null) {
        // Promote back into primary when possible.
        try {
          await _primary.write(fromSecondary);
        } catch (_) {}
        // ignore: avoid_print
        print('OAuth: restored tokens from secondary file store');
        return fromSecondary;
      }
    } catch (e) {
      // ignore: avoid_print
      print('OAuth: secondary token read failed: $e');
    }
    return null;
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    Object? primaryError;
    try {
      await _primary.write(tokens);
    } catch (e) {
      primaryError = e;
      // ignore: avoid_print
      print('OAuth: primary token write failed: $e');
    }
    try {
      await _secondary.write(tokens);
    } catch (e) {
      // ignore: avoid_print
      print('OAuth: secondary token write failed: $e');
      if (primaryError != null) {
        throw StateError(
          'Token persistence failed (primary=$primaryError secondary=$e)',
        );
      }
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _primary.clear();
    } catch (_) {}
    try {
      await _secondary.clear();
    } catch (_) {}
  }
}
