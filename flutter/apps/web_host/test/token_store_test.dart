import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_web_host/auth/pending_auth_store.dart';
import 'package:destiny2_web_host/auth/token_codec.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:test/test.dart';

BungieTokens _sampleTokens() {
  final now = DateTime.utc(2026, 7, 25, 12);
  return BungieTokens(
    accessToken: 'access-token-value-xyz',
    refreshToken: 'refresh-token-value-abc',
    expiresAt: now.add(const Duration(hours: 1)),
    refreshExpiresAt: now.add(const Duration(days: 90)),
    bungieMembershipId: 'M123',
  );
}

void main() {
  group('MemoryTokenStore US1', () {
    test('write then read round-trips membership and tokens', () async {
      final store = MemoryTokenStore();
      final tokens = _sampleTokens();
      await store.write(tokens);
      final read = await store.read();
      expect(read, isNotNull);
      expect(read!.accessToken, tokens.accessToken);
      expect(read.refreshToken, tokens.refreshToken);
      expect(read.bungieMembershipId, 'M123');
      expect(read.expiresAt, tokens.expiresAt);
      expect(read.refreshExpiresAt, tokens.refreshExpiresAt);
    });

    test('clear empties store', () async {
      final store = MemoryTokenStore();
      await store.write(_sampleTokens());
      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('LocalStorageTokenStore US1', () {
    test('round-trip via WebStringStorage (not SQLite)', () async {
      final memory = MemoryWebStringStorage();
      final store = LocalStorageTokenStore(storage: memory);
      final tokens = _sampleTokens();
      await store.write(tokens);

      expect(memory.getItem(kBungieTokenStorageKey), isNotNull);
      expect(
        memory.getItem(kBungieTokenStorageKey)!.contains('access-token-value'),
        isTrue,
      );

      final read = await store.read();
      expect(read!.bungieMembershipId, 'M123');
      expect(read.accessToken, tokens.accessToken);

      await store.clear();
      expect(await store.read(), isNull);
      expect(memory.getItem(kBungieTokenStorageKey), isNull);
    });

    test('corrupt JSON yields null', () async {
      final memory = MemoryWebStringStorage();
      memory.setItem(kBungieTokenStorageKey, '{not-json');
      final store = LocalStorageTokenStore(storage: memory);
      expect(await store.read(), isNull);
    });
  });

  group('token_codec', () {
    test('encode/decode stable', () {
      final tokens = _sampleTokens();
      final raw = encodeBungieTokens(tokens);
      final decoded = decodeBungieTokens(raw);
      expect(decoded!.accessToken, tokens.accessToken);
      expect(decoded.bungieMembershipId, 'M123');
    });
  });

  group('PendingAuthStore', () {
    test('session storage pending round-trip', () async {
      final memory = MemoryWebStringStorage();
      final store = SessionStoragePendingAuthStore(storage: memory);
      final pending = OAuthPendingAuth(
        state: 'state-1',
        codeVerifier: 'verifier-1' * 4,
        redirectUri: 'https://127.0.0.1:8080/auth/callback',
        createdAt: DateTime.utc(2026, 7, 25),
      );
      await store.write(pending);
      final read = await store.read();
      expect(read!.state, 'state-1');
      expect(read.codeVerifier, pending.codeVerifier);
      expect(read.redirectUri, pending.redirectUri);
      await store.clear();
      expect(await store.read(), isNull);
    });
  });
}
