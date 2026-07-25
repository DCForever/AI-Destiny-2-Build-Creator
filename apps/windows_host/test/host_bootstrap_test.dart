import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRefresh implements ManifestRefreshApi {
  _FakeRefresh(this.fixed);

  final ManifestStatus fixed;

  @override
  Future<bool> isStale() async => fixed.isStale;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      fixed;

  @override
  Future<ManifestStatus> status() async => fixed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart023_bootstrap_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('open ensures layout, opens single DB, oauth session, dispose closes',
      () async {
    final root = StorageRoot(basePath: tempDir.path);
    final db = AppDatabase.file(root.appDbPath);
    final services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(
        const ManifestStatus(
          cachedVersion: null,
          remoteVersion: null,
          isStale: true,
          entityCache: null,
        ),
      ),
      clientId: 'test-client',
      tokenStore: MemoryTokenStore(),
      browserLauncher: FakeBrowserLauncher(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
    );

    expect(services.db, same(db));
    expect(services.offlineCatalog, isNotNull);
    expect(services.oauthSession, isNotNull);
    expect(services.oauthSession.hasRestored, isTrue);
    expect(services.oauthSession.isSignedIn, isFalse);
    expect(File(root.appDbPath).existsSync(), isTrue);
    expect(Directory(root.manifestDir).existsSync(), isTrue);
    expect(Directory(root.entitiesDir).existsSync(), isTrue);

    final tables = await services.db.listUserTableNames();
    expect(tables, contains('builds'));
    expect(services.isClosed, isFalse);

    await services.dispose();
    expect(services.isClosed, isTrue);

    // Second dispose is safe.
    await services.dispose();
  });

  test('open with temp path creates app.db when database not injected', () async {
    final root = StorageRoot(basePath: tempDir.path);
    final services = await HostBootstrap.open(
      storageRoot: root,
      manifestRefresh: _FakeRefresh(
        const ManifestStatus(
          cachedVersion: 'v-test',
          remoteVersion: 'v-test',
          isStale: false,
          entityCache: null,
        ),
      ),
      clientId: 'test-client',
      tokenStore: MemoryTokenStore(),
      browserLauncher: FakeBrowserLauncher(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
    );

    expect(File(root.appDbPath).existsSync(), isTrue);
    final names = await services.db.listUserTableNames();
    expect(names, isNotEmpty);
    await services.dispose();
  });
}
