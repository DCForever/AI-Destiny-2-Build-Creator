import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/token_codec.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

/// Mirrors [SecureTokenStore] corrupt/empty behavior without Credential Locker.
class InMemorySecureStore implements TokenStore {
  String? raw;
  int clearSecureOnlyCalls = 0;

  @override
  Future<BungieTokens?> read() async {
    if (raw == null || raw!.trim().isEmpty) return null;
    final decoded = decodeBungieTokens(raw);
    if (decoded == null) {
      throw const TokenStoreCorruptException();
    }
    return decoded;
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    raw = encodeBungieTokens(tokens);
  }

  @override
  Future<void> clear() async {
    raw = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    clearSecureOnlyCalls += 1;
    raw = null;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// Empty until written; then read-back returns different secrets (verify fail).
class MismatchReadBackStore implements TokenStore {
  bool _written = false;
  int clearSecureOnlyCalls = 0;

  @override
  Future<BungieTokens?> read() async {
    if (!_written) return null;
    return sampleTokens(
      access: 'other-access-SECRET',
      refresh: 'other-refresh-SECRET',
    );
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    _written = true;
  }

  @override
  Future<void> clear() async {
    _written = false;
  }

  @override
  Future<void> clearSecureOnly() async {
    clearSecureOnlyCalls += 1;
    _written = false;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

enum _ReadBackFailMode { nullValue, corrupt, throwIo }

/// Empty until written; then read-back fails per [mode] (rollback coverage).
class ScriptedFailReadBackStore implements TokenStore {
  ScriptedFailReadBackStore(this.mode);

  final _ReadBackFailMode mode;
  bool _written = false;
  int clearSecureOnlyCalls = 0;

  @override
  Future<BungieTokens?> read() async {
    if (!_written) return null;
    switch (mode) {
      case _ReadBackFailMode.nullValue:
        return null;
      case _ReadBackFailMode.corrupt:
        throw const TokenStoreCorruptException();
      case _ReadBackFailMode.throwIo:
        throw StateError('simulated secure-store I/O failure');
    }
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    _written = true;
  }

  @override
  Future<void> clear() async {
    _written = false;
  }

  @override
  Future<void> clearSecureOnly() async {
    clearSecureOnlyCalls += 1;
    _written = false;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
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

  group('FileTokenStore + DualTokenStore hardening', () {
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

    test('(a) save never creates the plaintext sidecar', () async {
      final dir = await Directory.systemTemp.createTemp('tok_no_sidecar_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final primary = InMemorySecureStore();
      final secondary = FileTokenStore(baseDir: dir.path);
      final reports = <String>[];
      final dual = DualTokenStore(
        primary: primary,
        secondary: secondary,
        report: reports.add,
      );
      final tokens = sampleTokens(access: 'save-acc-SECRET', refresh: 'save-ref-SECRET');
      await dual.write(tokens);

      final sidecar = File(p.join(dir.path, kBungieTokenFileName));
      expect(await sidecar.exists(), isFalse);
      expect((await primary.read())?.accessToken, 'save-acc-SECRET');
      expect(await secondary.read(), isNull);
    });

    test(
      '(b) migration happy path deletes sidecar only after verified read-back',
      () async {
        final dir = await Directory.systemTemp.createTemp('tok_mig_ok_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        final primary = InMemorySecureStore();
        final secondary = FileTokenStore(baseDir: dir.path);
        final tokens = sampleTokens(
          access: 'mig-acc-SECRET',
          refresh: 'mig-ref-SECRET',
        );
        await secondary.write(tokens);
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final reports = <String>[];
        final dual = DualTokenStore(
          primary: primary,
          secondary: secondary,
          report: reports.add,
        );
        final recovered = await dual.read();
        expect(recovered, isNotNull);
        expect(recovered!.accessToken, 'mig-acc-SECRET');
        expect(recovered.refreshToken, 'mig-ref-SECRET');
        expect((await primary.read())?.accessToken, 'mig-acc-SECRET');
        expect(await sidecar.exists(), isFalse);
        expect(
          reports.any((m) => m.contains('migrated tokens into secure store')),
          isTrue,
        );
      },
    );

    test(
      '(c)/(1) read-back mismatch clears Locker entry and keeps sidecar',
      () async {
        final dir = await Directory.systemTemp.createTemp('tok_mig_fail_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        final secondary = FileTokenStore(baseDir: dir.path);
        final tokens = sampleTokens(
          access: 'keep-acc-SECRET',
          refresh: 'keep-ref-SECRET',
        );
        await secondary.write(tokens);
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final primary = MismatchReadBackStore();
        final reports = <String>[];
        final dual = DualTokenStore(
          primary: primary,
          secondary: secondary,
          report: reports.add,
        );
        final recovered = await dual.read();
        expect(recovered, isNull);
        expect(await sidecar.exists(), isTrue);
        expect(await secondary.read(), isNotNull);
        // Skeptic fix 1: remove the just-written Locker payload.
        expect(primary.clearSecureOnlyCalls, 1);
        expect(await primary.read(), isNull);
        expect(
          reports.any(
            (m) => m.contains('verify failed') && m.contains('sidecar kept'),
          ),
          isTrue,
        );
        for (final msg in reports) {
          expect(msg.contains('keep-acc-SECRET'), isFalse);
          expect(msg.contains('keep-ref-SECRET'), isFalse);
        }
      },
    );

    for (final mode in _ReadBackFailMode.values) {
      test(
        'rollback: ${mode.name} read-back clears Locker and keeps sidecar',
        () async {
          final dir =
              await Directory.systemTemp.createTemp('tok_rb_${mode.name}_');
          addTearDown(() async {
            if (await dir.exists()) await dir.delete(recursive: true);
          });
          final secondary = FileTokenStore(baseDir: dir.path);
          await secondary.write(
            sampleTokens(
              access: 'rb-acc-SECRET-${mode.name}',
              refresh: 'rb-ref-SECRET-${mode.name}',
            ),
          );
          final sidecar = File(p.join(dir.path, kBungieTokenFileName));
          expect(await sidecar.exists(), isTrue);

          final primary = ScriptedFailReadBackStore(mode);
          final reports = <String>[];
          final dual = DualTokenStore(
            primary: primary,
            secondary: secondary,
            report: reports.add,
          );
          final recovered = await dual.read();
          expect(recovered, isNull);
          expect(primary.clearSecureOnlyCalls, 1);
          expect(await primary.read(), isNull);
          expect(await sidecar.exists(), isTrue);
          expect(await secondary.read(), isNotNull);
          expect(
            reports.any((m) => m.contains('sidecar kept')),
            isTrue,
          );
        },
      );
    }

    test(
      '(d) corrupt secure store is signed-out path — no plaintext fallback',
      () async {
        final dir = await Directory.systemTemp.createTemp('tok_corrupt_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        final primary = InMemorySecureStore()..raw = '{not-valid-json';
        final secondary = FileTokenStore(baseDir: dir.path);
        await secondary.write(
          sampleTokens(access: 'fallback-acc-SECRET', refresh: 'fallback-ref-SECRET'),
        );

        final dual = DualTokenStore(primary: primary, secondary: secondary);
        expect(
          () => dual.read(),
          throwsA(
            isA<TokenStoreCorruptException>().having(
              (e) => e.message,
              'message',
              'Sign-in data could not be read - please sign in again',
            ),
          ),
        );
        // Sidecar must remain (never used as fallback for corrupt primary).
        expect(
          await File(p.join(dir.path, kBungieTokenFileName)).exists(),
          isTrue,
        );
      },
    );

    test('(e) no secret values appear in logs/errors (redaction)', () async {
      const access = 'access-token-SECRET-redact-xyz';
      const refresh = 'refresh-token-SECRET-redact-uvw';
      final tokens = sampleTokens(access: access, refresh: refresh);

      expect(tokens.toString().contains(access), isFalse);
      expect(tokens.toString().contains(refresh), isFalse);
      expect(tokens.toString(), contains('[redacted]'));

      const corrupt = TokenStoreCorruptException();
      expect(corrupt.toString(), isNot(contains(access)));
      expect(corrupt.toString(), isNot(contains(refresh)));
      expect(
        corrupt.toString(),
        'Sign-in data could not be read - please sign in again',
      );

      final dir = await Directory.systemTemp.createTemp('tok_redact_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final reports = <String>[];
      final dual = DualTokenStore(
        primary: MismatchReadBackStore(),
        secondary: FileTokenStore(baseDir: dir.path),
        report: reports.add,
      );
      await FileTokenStore(baseDir: dir.path).write(tokens);
      await dual.read();
      final blob = reports.join('\n');
      expect(blob.contains(access), isFalse);
      expect(blob.contains(refresh), isFalse);
      expect(blob.contains('access-token-SECRET'), isFalse);
      expect(blob.contains('refresh-token-SECRET'), isFalse);
    });

    test(
      '(4) SecureTokenStore garbage FlutterSecureStorage throws corrupt',
      () async {
        final previous = FlutterSecureStoragePlatform.instance;
        addTearDown(() {
          FlutterSecureStoragePlatform.instance = previous;
        });
        final data = <String, String>{
          kBungieTokenStorageKey: '{not-valid-json-SECRET-should-not-leak}',
        };
        FlutterSecureStoragePlatform.instance =
            TestFlutterSecureStoragePlatform(data);
        final store = SecureTokenStore(storage: const FlutterSecureStorage());

        await expectLater(
          store.read(),
          throwsA(
            isA<TokenStoreCorruptException>().having(
              (e) => e.message,
              'message',
              'Sign-in data could not be read - please sign in again',
            ),
          ),
        );
        // Garbage remains in fake storage until clearSecureOnly / clear.
        expect(data[kBungieTokenStorageKey], isNotNull);
      },
    );

    test(
      '(5) oversized Locker write fails rather than silently truncating',
      () async {
        final previous = FlutterSecureStoragePlatform.instance;
        addTearDown(() {
          FlutterSecureStoragePlatform.instance = previous;
        });
        final data = <String, String>{};
        FlutterSecureStoragePlatform.instance =
            TestFlutterSecureStoragePlatform(data);
        final store = SecureTokenStore(storage: const FlutterSecureStorage());

        final oversized = sampleTokens(
          access: 'A' * 3000,
          refresh: 'R' * 3000,
        );
        final encodedLen =
            utf8.encode(encodeBungieTokens(oversized)).length;
        expect(encodedLen, greaterThan(kMaxSecureTokenPayloadBytes));

        await expectLater(
          store.write(oversized),
          throwsA(isA<TokenStoreOverflowException>()),
        );
        expect(data.containsKey(kBungieTokenStorageKey), isFalse);

        // Normal-sized payload still writes.
        await store.write(sampleTokens());
        expect(data.containsKey(kBungieTokenStorageKey), isTrue);
      },
    );
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
