import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/builds/builds_library_controller.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BuildsLibraryController controller;

  setUp(() async {
    db = AppDatabase.memory();
    final store = MemoryTokenStore();
    final session = WindowsOAuthSession(
      clientId: 'test',
      redirectUri: kDefaultWindowsRedirectUri,
      tokenStore: store,
      oauthClient: BungieOAuthClient(
        clientId: 'test',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
      browserLauncher: FakeBrowserLauncher(),
    );
    await session.restore();
    final inventory = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
    );
    controller = BuildsLibraryController(
      db: db,
      session: session,
      inventorySync: inventory,
    );
    await controller.refresh();
  });

  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  Future<void> seedBuild() async {
    final uid = controller.userId!;
    final detail = await createUserBuild(
      db,
      uid,
      const CreateBuildCommand(
        id: 'b-finish',
        name: 'Walkthrough Build',
        className: GuardianClass.titan,
        synergyTypes: [
          SynergyTypeDesignation(type: SynergyType('solar')),
        ],
      ),
    );
    await controller.refresh();
    await controller.selectBuild(detail.build.id);
  }

  test('oneTapCreateCategory creates empty armor set and attaches', () async {
    await seedBuild();
    expect(controller.finishGaps?.complete, isFalse);

    final err = await controller.oneTapCreateCategory(FinishCategory.armor);
    expect(err, isNull);
    expect(controller.finishMessage, contains('Created'));
    expect(controller.finishGaps, isNotNull);
    final armor = controller.finishGaps!.gaps
        .firstWhere((g) => g.category == FinishCategory.armor);
    expect(armor.status, isNot(FinishGapStatus.needsSet));
    expect(armor.coveringSetId, isNotNull);
    expect(armor.coveringMode, AttachmentMode.live);
  });

  test('captureCategory with no claims returns NOTHING_TO_CREATE', () async {
    await seedBuild();
    // Without resolved pins (no covering set yet), capture has nothing to snapshot.
    final err = await controller.captureCategory(FinishCategory.armor);
    expect(err, 'NOTHING_TO_CREATE');
  });

  test('fillFinishSlot upserts covering set item', () async {
    await seedBuild();
    await controller.oneTapCreateCategory(FinishCategory.armor);
    final setId = controller.finishGaps!.gaps
        .firstWhere((g) => g.category == FinishCategory.armor)
        .coveringSetId!;

    final err = await controller.fillFinishSlot(
      setId: setId,
      slot: 'helmet',
      itemHash: 42,
      itemName: 'Test Helm',
      instanceId: 'h-1',
    );
    expect(err, isNull);
    final items = await listActiveSetItems(db, setId);
    expect(items.any((i) => i.slot == 'helmet' && i.itemHash == 42), isTrue);
  });
}
