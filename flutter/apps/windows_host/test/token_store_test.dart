import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/token_codec.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

BungieTokens sampleTokens({
  String access = 'access-token-SECRET-aaa',
  String refresh = 'refresh-token-SECRET-bbb',
  String membership = 'memb-999',
}) {
  final now = DateTime.utc(2026, 7, 24, 12);
  return BungieTokens(
    accessToken: access,
    refreshToken: refresh,
    expiresAt: now.add(const Duration(hours: 1)),
    refreshExpiresAt: now.add(const Duration(days: 90)),
    bungieMembershipId: membership,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('token codec', () {
    test('round-trips BungieTokens', () {
      final tokens = sampleTokens();
      final encoded = encodeBungieTokens(tokens);
      final decoded = decodeBungieTokens(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.accessToken, tokens.accessToken);
      expect(decoded.refreshToken, tokens.refreshToken);
      expect(decoded.bungieMembershipId, tokens.bungieMembershipId);
      expect(decoded.expiresAt.toUtc(), tokens.expiresAt.toUtc());
      expect(decoded.refreshExpiresAt.toUtc(), tokens.refreshExpiresAt.toUtc());
    });

    test('corrupt JSON returns null', () {
      expect(decodeBungieTokens('{not json'), isNull);
      expect(decodeBungieTokens('{"access_token":"x"}'), isNull);
      expect(decodeBungieTokens(null), isNull);
      expect(decodeBungieTokens(''), isNull);
    });

    test('empty refresh_token still decodes (Bungie Public clients)', () {
      final tokens = sampleTokens(refresh: '');
      final encoded = encodeBungieTokens(tokens);
      final decoded = decodeBungieTokens(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.accessToken, tokens.accessToken);
      expect(decoded.refreshToken, isEmpty);
      expect(decoded.bungieMembershipId, tokens.bungieMembershipId);
    });

    test('omitted refresh_token key still decodes', () {
      final now = DateTime.utc(2026, 7, 24, 12);
      final raw = jsonEncode({
        'access_token': 'acc-only',
        'expires_at': now.add(const Duration(hours: 1)).toIso8601String(),
        'refresh_expires_at':
            now.add(const Duration(hours: 1)).toIso8601String(),
        'membership_id': 'm-only',
      });
      final decoded = decodeBungieTokens(raw);
      expect(decoded, isNotNull);
      expect(decoded!.accessToken, 'acc-only');
      expect(decoded.refreshToken, isEmpty);
      expect(decoded.bungieMembershipId, 'm-only');
    });
  });

  group('FileTokenStore + DualTokenStore', () {
    test('file store round-trips under temp dir', () async {
      final dir = await Directory.systemTemp.createTemp('tok_file_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final store = FileTokenStore(baseDir: dir.path);
      final tokens = sampleTokens();
      await store.write(tokens);
      final read = await store.read();
      expect(read, isNotNull);
      expect(read!.accessToken, tokens.accessToken);
      expect(read.refreshToken, tokens.refreshToken);
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('dual store recovers from empty primary via secondary', () async {
      final dir = await Directory.systemTemp.createTemp('tok_dual_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final primary = MemoryTokenStore();
      final secondary = FileTokenStore(baseDir: dir.path);
      final dual = DualTokenStore(primary: primary, secondary: secondary);
      final tokens = sampleTokens(access: 'dual-acc', refresh: 'dual-ref');
      await dual.write(tokens);
      // Simulate Credential Manager miss after process restart.
      await primary.clear();
      expect(await primary.read(), isNull);
      final recovered = await dual.read();
      expect(recovered, isNotNull);
      expect(recovered!.accessToken, 'dual-acc');
      expect(recovered.refreshToken, 'dual-ref');
      // Healed primary.
      expect((await primary.read())?.accessToken, 'dual-acc');
    });
  });

  group('MemoryTokenStore US1', () {
    test('write/read/clear', () async {
      final store = MemoryTokenStore();
      expect(await store.read(), isNull);

      final tokens = sampleTokens();
      await store.write(tokens);
      final loaded = await store.read();
      expect(loaded, isNotNull);
      expect(loaded!.accessToken, tokens.accessToken);
      expect(loaded.refreshToken, tokens.refreshToken);
      expect(loaded.bungieMembershipId, tokens.bungieMembershipId);

      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('tokens not in SQLite plaintext', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart023_token_sqlite_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('secure MemoryTokenStore write leaves app.db free of token strings',
        () async {
      final root = StorageRoot(basePath: tempDir.path);
      await root.ensureLayout();
      final db = AppDatabase.file(root.appDbPath);
      await db.customSelect('SELECT 1').get();

      const access = 'access-token-SECRET-sqlite-guard-xyz';
      const refresh = 'refresh-token-SECRET-sqlite-guard-uvw';
      final store = MemoryTokenStore();
      await store.write(
        sampleTokens(access: access, refresh: refresh),
      );

      // Touch DB after token write (as host would keep DB open).
      await db.customSelect('SELECT 1').get();
      await db.close();

      final bytes = await File(root.appDbPath).readAsBytes();
      final asString = String.fromCharCodes(bytes);
      expect(asString.contains(access), isFalse);
      expect(asString.contains(refresh), isFalse);
      expect(asString.contains('access-token-SECRET'), isFalse);
      expect(asString.contains('refresh-token-SECRET'), isFalse);

      // Store still has tokens (not in SQLite).
      final loaded = await store.read();
      expect(loaded!.accessToken, access);
      expect(loaded.refreshToken, refresh);
    });
  });
}
