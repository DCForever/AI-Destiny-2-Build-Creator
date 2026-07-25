import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/app.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

class _FakeRefresh implements ManifestRefreshApi {
  @override
  Future<bool> isStale() async => false;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );

  @override
  Future<ManifestStatus> status() async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart055_nav_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    final tokenStore = MemoryTokenStore();

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: const [],
        version: 'fixture-nav-1',
      ),
      clientId: 'test-client',
      tokenStore: tokenStore,
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
      writeClient: MockBungieWriteClient(),
    );
  });

  tearDown(() async {
    await services.dispose();
    await tempDir.delete(recursive: true);
  });

  test('navLabels include Loadouts', () {
    expect(Destiny2WindowsApp.navLabels, contains('Loadouts'));
    expect(
      Destiny2WindowsApp.navLabels,
      containsAll([
        'Catalog',
        'Sets',
        'Synergies',
        'Builds',
        'Loadouts',
        'Settings',
      ]),
    );
  });

  testWidgets('NavigationRail shows Loadouts destination', (tester) async {
    await tester.pumpWidget(Destiny2WindowsApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('host_nav_rail')), findsOneWidget);
    expect(find.text('Loadouts'), findsWidgets);
    // IndexedStack keeps offstage children; use skipOffstage: false.
    expect(
      find.byKey(const Key('loadouts_page'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('selecting Loadouts keeps page mounted in stack', (tester) async {
    await tester.pumpWidget(Destiny2WindowsApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Destination index 4 = Loadouts
    await tester.tap(find.text('Loadouts').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('loadouts_title')), findsOneWidget);
    expect(find.text('In-Game Loadouts'), findsOneWidget);
  });
}
