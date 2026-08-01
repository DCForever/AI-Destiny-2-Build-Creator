import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

/// OS-backed secure store (`flutter_secure_storage` / Windows Credential Locker).
class SecureTokenStore implements TokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    this.storageKey = kBungieTokenStorageKey,
  }) : _storage = storage ?? const FlutterSecureStorage();

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
