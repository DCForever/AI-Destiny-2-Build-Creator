/// Session-scoped pending PKCE handoff across authorize redirect (DART-045).
library;

import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';

import 'token_store.dart';

/// Default sessionStorage key for pending OAuth handoff.
const String kBungiePendingAuthStorageKey = 'destiny2.bungie.oauth.pending';

/// Stores [OAuthPendingAuth] between authorize navigation and callback.
abstract class PendingAuthStore {
  Future<void> write(OAuthPendingAuth pending);
  Future<OAuthPendingAuth?> read();
  Future<void> clear();
}

/// In-memory pending store for tests.
class MemoryPendingAuthStore implements PendingAuthStore {
  OAuthPendingAuth? _pending;

  @override
  Future<void> write(OAuthPendingAuth pending) async {
    _pending = pending;
  }

  @override
  Future<OAuthPendingAuth?> read() async => _pending;

  @override
  Future<void> clear() async {
    _pending = null;
  }
}

/// sessionStorage-backed pending store (survives same-tab redirect).
class SessionStoragePendingAuthStore implements PendingAuthStore {
  SessionStoragePendingAuthStore({
    required WebStringStorage storage,
    this.storageKey = kBungiePendingAuthStorageKey,
  }) : _storage = storage;

  final WebStringStorage _storage;
  final String storageKey;

  @override
  Future<void> write(OAuthPendingAuth pending) async {
    final payload = jsonEncode(<String, Object?>{
      'state': pending.state,
      'code_verifier': pending.codeVerifier,
      'redirect_uri': pending.redirectUri,
      if (pending.createdAt != null)
        'created_at': pending.createdAt!.toUtc().toIso8601String(),
    });
    _storage.setItem(storageKey, payload);
  }

  @override
  Future<OAuthPendingAuth?> read() async {
    final raw = _storage.getItem(storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final state = map['state'];
      final verifier = map['code_verifier'];
      final redirect = map['redirect_uri'];
      if (state is! String ||
          state.isEmpty ||
          verifier is! String ||
          verifier.isEmpty ||
          redirect is! String ||
          redirect.isEmpty) {
        return null;
      }
      DateTime? createdAt;
      final createdRaw = map['created_at'];
      if (createdRaw is String) {
        createdAt = DateTime.tryParse(createdRaw)?.toUtc();
      }
      return OAuthPendingAuth(
        state: state,
        codeVerifier: verifier,
        redirectUri: redirect,
        createdAt: createdAt,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    _storage.removeItem(storageKey);
  }
}
