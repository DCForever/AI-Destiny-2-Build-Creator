import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/loadouts/loadouts_controller.dart';
import 'package:destiny2_windows_host/loadouts/loadouts_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
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

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Object _fixtureProfile() => {
      'characters': {
        'data': {
          'char-titan': {
            'characterId': 'char-titan',
            'classType': 0,
            'light': 1820,
            'dateLastPlayed': '2026-07-23T12:00:00Z',
          },
          'char-hunter': {
            'characterId': 'char-hunter',
            'classType': 1,
            'light': 1810,
            'dateLastPlayed': '2026-07-24T12:00:00Z',
          },
        },
      },
      'characterLoadouts': {
        'data': {
          'char-titan': {
            'loadouts': [
              {
                'iconHash': 111,
                'colorHash': 222,
                'nameHash': 333,
                'items': [
                  {'itemInstanceId': '999', 'plugItemHashes': <int>[]},
                ],
              },
              {
                'iconHash': 0,
                'colorHash': 0,
                'nameHash': 0,
                'items': <Object>[],
              },
            ],
          },
          'char-hunter': {
            'loadouts': [
              {
                'iconHash': 0,
                'colorHash': 0,
                'nameHash': 0,
                'items': [
                  {'itemInstanceId': '111'},
                ],
              },
            ],
          },
        },
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;
  late MemoryTokenStore tokenStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart055_lo_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    tokenStore = MemoryTokenStore();

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: const [],
        version: 'fixture-lo-1',
      ),
      clientId: 'test-client',
      tokenStore: tokenStore,
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(
        characterLoadoutsProfile: _fixtureProfile(),
      ),
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

  testWidgets('signed-out shows gate', (tester) async {
    final controller = LoadoutsController(
      session: services.oauthSession,
      profileClient: services.profileClient,
      presentationTables: const LoadoutPresentationTables(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.dark),
        home: Scaffold(
          body: LoadoutsPage(
            services: services,
            controller: controller,
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('loadouts_signed_out')), findsOneWidget);
    expect(find.text(LoadoutsPage.signedOutText), findsOneWidget);
    controller.dispose();
  });

  testWidgets('signed-in lists non-empty loadouts and hides empty by default',
      (tester) async {
    await seedSignedIn(tokenStore);
    await services.oauthSession.restore();

    final tables = presentationTablesFromRaw(
      icons: {
        '111': {
          'iconImagePath': '/common/destiny2_content/icons/loadout_a.png',
        },
      },
      colors: {
        '222': {
          'colorImagePath': '/common/destiny2_content/icons/color_a.png',
        },
      },
      names: {
        '333': {'name': 'Pyre Onslaught'},
      },
    );

    final controller = LoadoutsController(
      session: services.oauthSession,
      profileClient: services.profileClient,
      presentationTables: tables,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.dark),
        home: Scaffold(
          body: LoadoutsPage(
            services: services,
            controller: controller,
          ),
        ),
      ),
    );
    await _pumpFrames(tester);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('loadouts_list')), findsOneWidget);
    expect(find.text('Pyre Onslaught'), findsOneWidget);
    // Hunter non-empty falls back to Loadout 1
    expect(find.text('Loadout 1'), findsOneWidget);
    // Empty titan slot hidden by default
    expect(find.text('Loadout 2'), findsNothing);

    // Show empty
    await tester.tap(find.byKey(const Key('loadouts_filter_hide_empty')));
    await _pumpFrames(tester);
    expect(find.text('Loadout 2'), findsOneWidget);

    // Class filter Titan only
    await tester.tap(find.byKey(const Key('loadouts_filter_class_Titan')));
    await _pumpFrames(tester);
    expect(find.text('Pyre Onslaught'), findsOneWidget);
    expect(find.text('Loadout 1'), findsNothing);

    controller.dispose();
  });
}
