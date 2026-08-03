import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_card.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_material_theme.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InventoryBusyLock lock;

  setUp(() {
    db = AppDatabase.memory();
    lock = InventoryBusyLock();
    defaultInventoryBusyLock.clearForTests();
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  Future<WindowsOAuthSession> signedInSession(MemoryTokenStore store) async {
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    return session;
  }

  test('sync alone does not apply kits; Confirm applies', () async {
    final store = MemoryTokenStore();
    final session = await signedInSession(store);
    final user = await ensureUser(
      db,
      bungieMembershipId: 'bungie-net-99',
      membershipType: 3,
      displayName: 'T',
    );

    final better = ArmorCombination(
      pieces: [
        for (final s in EquipmentSlot.armorSlots)
          ArmorOptimizePiece(
            slot: s,
            itemHash: 100 + s.index,
            instanceId: 'i-${s.wireName}',
            isExotic: false,
            itemName: 'Piece ${s.wireName}',
          ),
      ],
      estimatedStats: const {ArmorStatName.melee: 99},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 99,
      meetsSoftThresholds: true,
    );
    final suggestion = ImprovementSuggestion(
      armorSetId: 'armor-set',
      armorSetName: 'My Armor',
      buildIds: const ['b1'],
      hasImprovement: true,
      betterCombination: better,
    );

    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
      lock: lock,
      improvementSuggestionsRunner: ({
        required AppDatabase db,
        required int userId,
        required List<CandidatePiece> candidates,
      }) async =>
          [suggestion],
    );

    // Seed constrained armor set with weak pieces.
    await createUserSet(
      db,
      user.id,
      CreateSetCommand(
        id: 'armor-set',
        name: 'My Armor',
        type: SetType.armor,
        optimizerConstraints: serializeOptimizerConstraints(
          const ArmorSetOptimizerConstraints(),
        ),
      ),
    );
    await upsertUserSetItem(
      db,
      user.id,
      'armor-set',
      const UpsertSetItemCommand(
        slot: 'helmet',
        itemHash: 1,
        itemName: 'Old Helm',
        instanceId: 'old-h',
        replaceExisting: true,
      ),
    );

    await controller.syncNow();
    expect(controller.postSyncSuggestions, hasLength(1));

    final before = await listActiveSetItems(db, 'armor-set');
    expect(before.single.instanceId, 'old-h');

    // Dismiss must not write.
    controller.dismissPostSyncSuggestion('armor-set');
    expect(controller.postSyncSuggestions, isEmpty);
    final afterDismiss = await listActiveSetItems(db, 'armor-set');
    expect(afterDismiss.single.instanceId, 'old-h');

    // Re-fetch and Confirm.
    await controller.fetchPostSyncSuggestions();
    expect(controller.postSyncSuggestions, hasLength(1));
    final err = await controller.confirmPostSyncSuggestion('armor-set');
    expect(err, isNull);
    final afterConfirm = await listActiveSetItems(db, 'armor-set');
    expect(afterConfirm.length, EquipmentSlot.armorSlots.length);
    expect(
      afterConfirm.any((i) => i.instanceId == 'i-helmet'),
      isTrue,
    );
    expect(controller.postSyncSuggestions, isEmpty);

    controller.dispose();
  });

  testWidgets('banner shows Confirm/Dismiss keys after injected suggestions',
      (tester) async {
    final store = MemoryTokenStore();
    final session = await signedInSession(store);
    final suggestion = ImprovementSuggestion(
      armorSetId: 's1',
      armorSetName: 'Banner Armor',
      buildIds: const [],
      hasImprovement: true,
      betterCombination: ArmorCombination(
        pieces: [
          for (final s in EquipmentSlot.armorSlots)
            ArmorOptimizePiece(
              slot: s,
              itemHash: 1,
              instanceId: 'x-${s.wireName}',
              isExotic: false,
            ),
        ],
        estimatedStats: const {},
        incompleteEstimate: false,
        setBonusSummary: const [],
        reusePieceCount: 0,
        score: 1,
        meetsSoftThresholds: true,
      ),
    );
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
      lock: lock,
      improvementSuggestionsRunner: ({
        required AppDatabase db,
        required int userId,
        required List<CandidatePiece> candidates,
      }) async =>
          [suggestion],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: InventorySyncCard(controller: controller, session: session),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await controller.syncNow();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const Key('inventory_post_sync_better_kits_banner')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventory_post_sync_confirm_s1')), findsOneWidget);
    expect(find.byKey(const Key('inventory_post_sync_dismiss_s1')), findsOneWidget);

    controller.dismissPostSyncSuggestion('s1');
    await tester.pump();
    expect(
      find.byKey(const Key('inventory_post_sync_better_kits_banner')),
      findsNothing,
    );

    controller.dispose();
  });
}
