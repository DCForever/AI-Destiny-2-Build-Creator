import 'dart:io';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_mobile_host/host_bootstrap.dart';
import 'package:destiny2_mobile_host/settings/settings_page.dart';
import 'package:destiny2_mobile_host/theme/flap_theme.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRefresh implements ManifestRefreshApi {
  _FakeRefresh(this.fixed, {this.throwOnRefresh = false});

  ManifestStatus fixed;
  final bool throwOnRefresh;
  int refreshCalls = 0;

  @override
  Future<bool> isStale() async => fixed.isStale;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async {
    refreshCalls += 1;
    if (throwOnRefresh) {
      throw StateError('refresh failed');
    }
    return fixed;
  }

  @override
  Future<ManifestStatus> status() async => fixed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MobileAppServices services;
  late _FakeRefresh refresh;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart040_settings_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    final db = AppDatabase.memory();
    refresh = _FakeRefresh(
      const ManifestStatus(
        cachedVersion: 'v1',
        remoteVersion: 'v2',
        isStale: true,
        entityCache: null,
      ),
    );
    services = await MobileHostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: refresh,
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows db path and manifest status fields', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SettingsPage(services: services),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('db_path')), findsOneWidget);
    expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
    expect(find.byKey(const Key('cached_version')), findsOneWidget);
    expect(find.text('v1'), findsOneWidget);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text('stale'), findsOneWidget);
    expect(find.textContaining('CLIENT_SECRET'), findsWidgets);
    expect(find.byKey(const Key('entity_cache_empty_warning')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('refresh_manifest')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('refresh_manifest')), findsOneWidget);

    // Matrix card is below the fold in ListView — scroll into view.
    await tester.scrollUntilVisible(
      find.byKey(const Key('surface_matrix_card')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('surface_matrix_card')), findsOneWidget);
    expect(find.byKey(const Key('surface_matrix_row_equip')), findsOneWidget);
    expect(find.byKey(const Key('surface_matrix_row_optimizer')), findsOneWidget);
  });

  testWidgets('Refresh manifest updates status and clears empty warning',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SettingsPage(services: services),
      ),
    );
    await tester.pumpAndSettle();

    refresh.fixed = const ManifestStatus(
      cachedVersion: 'v2',
      remoteVersion: 'v2',
      isStale: false,
      entityCache: EntityCacheMeta(
        manifestVersion: 'v2',
        builtAt: '2026-01-02T00:00:00.000Z',
        counts: {'weapons': 5},
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('refresh_manifest')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('refresh_manifest')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(refresh.refreshCalls, 1);
    await tester.scrollUntilVisible(
      find.byKey(const Key('manifest_refresh_message')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('manifest_refresh_message')), findsOneWidget);
    expect(find.textContaining('Manifest refreshed'), findsOneWidget);
    expect(find.byKey(const Key('entity_cache_empty_warning')), findsNothing);
    expect(find.textContaining('5 entities'), findsOneWidget);
  });
}
