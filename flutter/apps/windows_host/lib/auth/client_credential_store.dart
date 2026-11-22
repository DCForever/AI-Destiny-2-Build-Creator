import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Windows Credential Manager target for the optional Confidential app
/// credential (plan b2). Separate from token storage.
const String kBungieOauthClientCredentialKey = 'destiny2.bungie.oauth.client';

/// Persists the optional Confidential Bungie app credential.
///
/// Implementations MUST NOT log the value. Empty / missing means Public+PKCE.
abstract class ClientCredentialStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();

  /// Removes any stored credential (same as [clear]). Prefer this name from UI.
  Future<void> forget();

  Future<bool> get hasCredential;
}

/// In-memory store for unit/widget tests.
class MemoryClientCredentialStore implements ClientCredentialStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _value = null;
      return;
    }
    _value = trimmed;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }

  @override
  Future<void> forget() => clear();

  @override
  Future<bool> get hasCredential async =>
      _value != null && _value!.isNotEmpty;
}

/// OS-backed store (`flutter_secure_storage` / Windows Credential Manager).
class SecureClientCredentialStore implements ClientCredentialStore {
  SecureClientCredentialStore({
    FlutterSecureStorage? storage,
    this.storageKey = kBungieOauthClientCredentialKey,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              wOptions: WindowsOptions(),
            );

  final FlutterSecureStorage _storage;
  final String storageKey;

  @override
  Future<String?> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw;
  }

  @override
  Future<void> write(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(key: storageKey, value: trimmed);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: storageKey);
  }

  @override
  Future<void> forget() => clear();

  @override
  Future<bool> get hasCredential async {
    final v = await read();
    return v != null && v.isNotEmpty;
  }
}
