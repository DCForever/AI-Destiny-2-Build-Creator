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
  late MobileAppServices services;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart040_settings_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    final db = AppDatabase.memory();
    services = await MobileHostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(
        const ManifestStatus(
          cachedVersion: 'v1',
          remoteVersion: 'v2',
          isStale: true,
          entityCache: null,
        ),
      ),
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('shows db path and manifest status fields', (tester) async {
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
}
