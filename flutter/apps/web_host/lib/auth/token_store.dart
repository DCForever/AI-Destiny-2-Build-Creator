/// Secure-ish browser persistence for [BungieTokens] (DART-045).
///
/// Implementations MUST NOT write access/refresh tokens into SQLite/Drift.
/// Production uses origin-scoped `localStorage` (no OS keychain on web).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';

import 'token_codec.dart';

/// Persistence port for [BungieTokens].
abstract class TokenStore {
  Future<BungieTokens?> read();
  Future<void> write(BungieTokens tokens);
  Future<void> clear();
}

/// In-memory store for unit/component tests.
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

/// Default localStorage key for the web host OAuth payload.
const String kBungieTokenStorageKey = 'destiny2.bungie.oauth.tokens';

/// String key/value storage (localStorage or test double).
abstract class WebStringStorage {
  String? getItem(String key);
  void setItem(String key, String value);
  void removeItem(String key);
}

/// In-memory [WebStringStorage] for tests.
class MemoryWebStringStorage implements WebStringStorage {
  final Map<String, String> _data = {};

  @override
  String? getItem(String key) => _data[key];

  @override
  void setItem(String key, String value) => _data[key] = value;

  @override
  void removeItem(String key) => _data.remove(key);
}

/// Origin-scoped store backed by [WebStringStorage] (localStorage in browser).
///
/// **Not** SQLite. Tokens are origin-isolated; prefer HTTPS origins.
class LocalStorageTokenStore implements TokenStore {
  LocalStorageTokenStore({
    required WebStringStorage storage,
    this.storageKey = kBungieTokenStorageKey,
  }) : _storage = storage;

  final WebStringStorage _storage;
  final String storageKey;

  @override
  Future<BungieTokens?> read() async {
    return decodeBungieTokens(_storage.getItem(storageKey));
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    _storage.setItem(storageKey, encodeBungieTokens(tokens));
  }

  @override
  Future<void> clear() async {
    _storage.removeItem(storageKey);
  }
}
