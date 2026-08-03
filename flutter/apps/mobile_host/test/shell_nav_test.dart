import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_mobile_host/app.dart';
import 'package:destiny2_mobile_host/host_bootstrap.dart';
import 'package:destiny2_mobile_host/surface_matrix.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRefresh implements ManifestRefreshApi {
  @override
  Future<bool> isStale() async => true;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      status();

  @override
  Future<ManifestStatus> status() async => const ManifestStatus(
        cachedVersion: 'local',
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MobileAppServices services;

  setUp(() async {
    db = AppDatabase.memory();
    services = MobileAppServices(
      storageRoot: StorageRoot(basePath: '/tmp/dart_shell_settings'),
      db: db,
      manifestRefresh: _FakeRefresh(),
    );
  });

  tearDown(() async {
    await services.dispose();
  });

  testWidgets('Settings-only shell shows Settings page without bottom nav',
      (tester) async {
    await tester.pumpWidget(
      Destiny2MobileApp(services: services),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile_shell')), findsOneWidget);
    // SettingsPage and its Scaffold both use settings_page key historically.
    expect(find.byKey(const Key('settings_page')), findsWidgets);
    expect(find.byKey(const Key('db_path')), findsOneWidget);
    expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);

    // Single-destination baseline: no Material NavigationBar (≥2 required).
    expect(find.byKey(const Key('mobile_bottom_nav')), findsNothing);
    expect(find.byKey(const Key('nav_builds')), findsNothing);
    expect(find.byKey(const Key('nav_catalog')), findsNothing);
    expect(find.byKey(const Key('builds_list_page')), findsNothing);
  });

  testWidgets('surface matrix marks Settings as sole bottomNav destination',
      (tester) async {
    expect(kMobileBottomNavKeys, ['settings']);
    expect(
      kMobileSurfaceMatrix.where((e) => e.bottomNav).map((e) => e.key),
      kMobileBottomNavKeys,
    );

    await tester.pumpWidget(
      Destiny2MobileApp(services: services),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('surface_matrix_card')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('surface_matrix_card')), findsOneWidget);
  });
}
