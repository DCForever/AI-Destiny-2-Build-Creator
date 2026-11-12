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
    tempDir = await Directory.systemTemp.createTemp('dart_shell_catalog_');
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

  test('navLabels are Catalog, Sets, Warlocks, Builds (mockup), and Settings',
      () {
    expect(Destiny2WindowsApp.navLabels, [
      'Catalog',
      'Sets',
      'Warlocks',
      'Builds (mockup)',
      'Settings',
    ]);
    expect(Destiny2WindowsApp.catalogNavIndex, 0);
    expect(Destiny2WindowsApp.setsNavIndex, 1);
    expect(Destiny2WindowsApp.warlockBuildsNavIndex, 2);
    expect(Destiny2WindowsApp.buildsMockNavIndex, 3);
    expect(Destiny2WindowsApp.settingsNavIndex, 4);
  });

  testWidgets(
      'NavigationRail shows Catalog, Sets, Warlocks, Builds (mockup), Settings',
      (
    tester,
  ) async {
    // Wide surface avoids Catalog filter-bar overflow when Catalog is on stage.
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(Destiny2WindowsApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('host_nav_rail')), findsOneWidget);
    expect(find.text('Catalog'), findsWidgets);
    expect(find.text('Sets'), findsWidgets);
    expect(find.text('Warlocks'), findsWidgets);
    expect(find.text('Builds (mockup)'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.byKey(const Key('catalog_page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sets_library_page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('warlock_builds_page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('builds_mock_page_host'), skipOffstage: false),
      findsOneWidget,
    );

    expect(find.text('Loadouts'), findsNothing);
    expect(find.text('Build'), findsNothing);
    expect(find.text('Synergy'), findsNothing);
  });
}
