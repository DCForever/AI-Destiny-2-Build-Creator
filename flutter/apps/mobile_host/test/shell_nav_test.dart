import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_mobile_host/app.dart';
import 'package:destiny2_mobile_host/builds/builds_controller.dart';
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
  late BuildsController controller;

  setUp(() async {
    db = AppDatabase.memory();
    services = MobileAppServices(
      storageRoot: StorageRoot(basePath: '/tmp/dart040_shell'),
      db: db,
      manifestRefresh: _FakeRefresh(),
    );
    controller = BuildsController(db: db);
  });

  tearDown(() async {
    controller.dispose();
    await services.dispose();
  });

  testWidgets('bottom nav switches Builds and Settings', (tester) async {
    await tester.pumpWidget(
      Destiny2MobileApp(
        services: services,
        buildsController: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile_shell')), findsOneWidget);
    expect(find.byKey(const Key('mobile_bottom_nav')), findsOneWidget);
    expect(find.byKey(const Key('builds_list_page')), findsOneWidget);
    expect(find.text('Builds'), findsWidgets);

    // Settings destination.
    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('db_path')), findsOneWidget);
    expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);

    // Back to Builds.
    await tester.tap(find.byKey(const Key('nav_builds')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('builds_list_page')), findsOneWidget);
    expect(find.byKey(const Key('builds_empty')), findsOneWidget);
    expect(find.textContaining('Tap + to create'), findsOneWidget);
  });

  testWidgets('bottom nav matches published surface matrix destinations',
      (tester) async {
    // Matrix single source of truth: only build + settings are bottomNav.
    expect(kMobileBottomNavKeys, ['build', 'settings']);
    expect(
      kMobileSurfaceMatrix.where((e) => e.bottomNav).map((e) => e.key),
      kMobileBottomNavKeys,
    );

    await tester.pumpWidget(
      Destiny2MobileApp(
        services: services,
        buildsController: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav_builds')), findsOneWidget);
    expect(find.byKey(const Key('nav_settings')), findsOneWidget);
    // No catalog / equip / loadouts destinations in shell.
    expect(find.byKey(const Key('nav_catalog')), findsNothing);
    expect(find.byKey(const Key('nav_equip')), findsNothing);
    expect(find.byKey(const Key('nav_loadouts')), findsNothing);

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('surface_matrix_card')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('surface_matrix_card')), findsOneWidget);
    expect(find.byKey(const Key('surface_matrix_row_equip')), findsOneWidget);
    expect(find.textContaining('N/A'), findsWidgets);
  });
}
