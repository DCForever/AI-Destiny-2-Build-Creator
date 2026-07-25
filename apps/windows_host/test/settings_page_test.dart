import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:destiny2_windows_host/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

class _FakeRefresh implements ManifestRefreshApi {
  _FakeRefresh(this._status, {this.throwOnStatus = false});

  ManifestStatus _status;
  final bool throwOnStatus;

  void setStatus(ManifestStatus status) => _status = status;

  @override
  Future<bool> isStale() async => _status.isStale;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      _status;

  @override
  Future<ManifestStatus> status() async {
    if (throwOnStatus) {
      throw StateError('status failed');
    }
    return _status;
  }
}

/// Drain microtasks + frames without waiting on infinite animations.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

WindowsOAuthSession _emptySession() {
  return WindowsOAuthSession(
    clientId: 'test-client',
    redirectUri: kDefaultWindowsRedirectUri,
    tokenStore: MemoryTokenStore(),
    oauthClient: BungieOAuthClient(
      clientId: 'test-client',
      redirectUri: kDefaultWindowsRedirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
    browserLauncher: FakeBrowserLauncher(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late _FakeRefresh refresh;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart023_settings_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    refresh = _FakeRefresh(
      const ManifestStatus(
        cachedVersion: 'v1',
        remoteVersion: 'v2',
        isStale: true,
        entityCache: EntityCacheMeta(
          manifestVersion: 'v1',
          builtAt: '2026-01-01T00:00:00.000Z',
          counts: {'weapons': 3, 'mods': 2},
        ),
      ),
    );
    final session = _emptySession();
    await session.restore();
    services = await HostBootstrap.open(
      storageRoot: root,
      database: AppDatabase.memory(),
      manifestRefresh: refresh,
      clientId: 'test-client',
      tokenStore: MemoryTokenStore(),
      browserLauncher: FakeBrowserLauncher(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
      profileClient: FakeProfileClient(),
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows OAuth card + inventory sync + manifest status',
      (tester) async {
    // Tall surface so ListView builds account + inventory + manifest sections.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(services: services)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('oauth_account_card')), findsOneWidget);
    expect(find.byKey(const Key('oauth_sign_in')), findsOneWidget);
    expect(find.byKey(const Key('no_oauth_note')), findsNothing);
    expect(find.byKey(const Key('inventory_sync_card')), findsOneWidget);
    expect(find.byKey(const Key('inventory_sync_signed_out')), findsOneWidget);
    expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
    expect(find.byKey(const Key('cached_version')), findsOneWidget);
    expect(find.text('v1'), findsWidgets);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text('stale'), findsOneWidget);
    expect(find.byKey(const Key('entity_cache')), findsOneWidget);
    expect(find.textContaining('5 entities'), findsOneWidget);
  });

  testWidgets('missing cached version shows none without crash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    refresh.setStatus(
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(services: services)),
    );
    await _pumpFrames(tester);

    expect(find.text('none'), findsWidgets);
    expect(find.text('unknown'), findsOneWidget);
    expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
  });

  testWidgets('status error surfaces message', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Reuse the single open DB (second NativeDatabase.memory can hang on some hosts).
    final session = _emptySession();
    await session.restore();
    final profile = FakeProfileClient();
    final errServices = AppServices(
      storageRoot: services.storageRoot,
      db: services.db,
      manifestRefresh: _FakeRefresh(
        const ManifestStatus(
          cachedVersion: null,
          remoteVersion: null,
          isStale: true,
          entityCache: null,
        ),
        throwOnStatus: true,
      ),
      offlineCatalog: OfflineCatalog(storageRoot: services.storageRoot),
      oauthSession: session,
      profileClient: profile,
      inventorySync: InventorySyncController(
        db: services.db,
        session: session,
        profileClient: profile,
      ),
      writeClient: createMockWriteClient(),
    );

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(services: errServices)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('status_error')), findsOneWidget);
    expect(find.byKey(const Key('status_error_text')), findsOneWidget);
    // Do not dispose errServices — it shares services.db closed in tearDown.
  });
}
