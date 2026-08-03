import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_mobile_host/builds/builds_controller.dart';
import 'package:destiny2_mobile_host/builds/builds_list_page.dart';
import 'package:destiny2_mobile_host/host_bootstrap.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
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
        cachedVersion: null,
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
      storageRoot: StorageRoot(basePath: '/tmp/dart040_unused'),
      db: db,
      manifestRefresh: _FakeRefresh(),
    );
    controller = BuildsController(db: db);
  });

  tearDown(() async {
    controller.dispose();
    await services.dispose();
  });

  Future<void> seedBuild() async {
    final user = await ensureUser(
      db,
      bungieMembershipId: kLocalLibraryMembershipId,
      membershipType: 0,
      displayName: 'Local library',
    );
    await createUserBuild(
      db,
      user.id,
      const CreateBuildCommand(
        id: 'build-mobile-1',
        name: 'Arc Hunter',
        className: GuardianClass.hunter,
        subclass: SubclassKit(name: 'Arcstrider'),
        synergyTypes: [
          SynergyTypeDesignation(
            type: SynergyType('melee'),
            subType: 'Base',
          ),
        ],
      ),
      now: fixedNow('2026-07-25T12:00:00.000Z'),
      newId: sequentialIds('m'),
    );
  }

  Future<void> pumpBuildsList(WidgetTester tester) async {
    // Page-level pump: shell is Settings-only during UX rebuild.
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => BuildsListPage(controller: controller),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty builds list shows empty state', (tester) async {
    await pumpBuildsList(tester);

    expect(find.byKey(const Key('builds_empty')), findsOneWidget);
    expect(find.byKey(const Key('builds_list')), findsNothing);
  });

  testWidgets('seeded builds list and Focus Swap detail', (tester) async {
    await seedBuild();

    await pumpBuildsList(tester);

    expect(find.byKey(const Key('builds_list')), findsOneWidget);
    expect(find.byKey(const Key('build_row_build-mobile-1')), findsOneWidget);
    expect(find.text('Arc Hunter'), findsOneWidget);

    // Focus Swap: open detail — list page not dual-visible with detail body.
    await tester.tap(find.byKey(const Key('build_row_build-mobile-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('build_detail_page')), findsOneWidget);
    expect(find.byKey(const Key('build_detail_body')), findsOneWidget);
    expect(find.byKey(const Key('detail_name')), findsOneWidget);
    expect(find.text('Arc Hunter'), findsWidgets);

    // List route should not be co-visible as dual-pane (only detail scaffold).
    expect(find.byKey(const Key('builds_list')), findsNothing);

    // Back → list again.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('builds_list')), findsOneWidget);
    expect(find.byKey(const Key('build_detail_page')), findsNothing);
  });
}
