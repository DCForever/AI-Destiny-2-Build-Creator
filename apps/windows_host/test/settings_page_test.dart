import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Drain microtasks + a frame without waiting on infinite animations.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late _FakeRefresh refresh;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart019_settings_');
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
    services = await HostBootstrap.open(
      storageRoot: root,
      database: AppDatabase.memory(),
      manifestRefresh: refresh,
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows cached, remote, stale, entity cache; no OAuth chrome',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(services: services)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
    expect(find.byKey(const Key('cached_version')), findsOneWidget);
    expect(find.text('v1'), findsWidgets);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text('stale'), findsOneWidget);
    expect(find.byKey(const Key('entity_cache')), findsOneWidget);
    expect(find.textContaining('5 entities'), findsOneWidget);
    expect(find.byKey(const Key('no_oauth_note')), findsOneWidget);
    expect(find.textContaining('OAuth'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('missing cached version shows none without crash', (tester) async {
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
    // Reuse the single open DB (second NativeDatabase.memory can hang on some hosts).
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
