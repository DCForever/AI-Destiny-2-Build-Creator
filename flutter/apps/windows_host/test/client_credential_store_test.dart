import 'package:destiny2_windows_host/auth/client_credential_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientCredentialStore forget API', () {
    test('forget removes stored credential (Memory)', () async {
      final store = MemoryClientCredentialStore();
      await store.write('FAKE-BUNGIE-APP-CREDENTIAL-store-test');
      expect(await store.hasCredential, isTrue);

      await store.forget();
      expect(await store.hasCredential, isFalse);
      expect(await store.read(), isNull);
    });

    test('forget is idempotent when empty', () async {
      final store = MemoryClientCredentialStore();
      await store.forget();
      expect(await store.hasCredential, isFalse);
    });

    test('storage key is stable destiny2.bungie.oauth.client', () {
      expect(
        kBungieOauthClientCredentialKey,
        'destiny2.bungie.oauth.client',
      );
    });
  });
}
