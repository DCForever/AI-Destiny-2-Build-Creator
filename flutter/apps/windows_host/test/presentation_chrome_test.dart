import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_card.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_material_theme.dart';

import 'inventory_sync_test_fakes.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pure helpers used by chrome (DART-068)', () {
    test('designation chrome', () {
      expect(formatDesignationChrome('verb', 'Scorch'), 'Verb: Scorch');
      expect(formatDesignationChrome('element', 'Solar'), 'Element: Solar');
    });

    test('catalog dense meta', () {
      expect(
        buildCatalogDenseMetaChips(isExotic: true, element: 'Arc'),
        ['Exotic', 'Arc'],
      );
    });

    test('manifest readiness labels', () {
      expect(
        manifestReadinessLabel(
          manifestReadiness(hasEntityCache: true, isStale: false),
        ),
        'READY',
      );
      expect(
        manifestReadinessLabel(
          manifestReadiness(hasEntityCache: false, isStale: true),
        ),
        'NOT DOWNLOADED',
      );
    });

    test('loadout exotic enrich', () {
      const lo = BungieInGameLoadout(
        id: 'c:0',
        characterId: 'c',
        className: 'Hunter',
        characterLight: 1,
        index: 0,
        name: 'L',
        iconHash: 1,
        colorHash: 2,
        nameHash: 3,
        itemInstanceIds: ['i'],
        empty: false,
      );
      final out = enrichLoadoutsWithExotics(
        [lo],
        instanceIdToHash: const {'i': 9},
        catalog: buildExoticCatalogIndex(
          exoticArmor: [(hash: 9, name: 'Orpheus')],
          exoticWeapons: const [],
        ),
      );
      expect(out.single.exoticArmorName, 'Orpheus');
    });

    test('formatLastSyncLabel Never', () {
      expect(formatLastSyncLabel(), 'Never');
    });
  });

  group('inventory chrome DART-068', () {
    testWidgets('ONLINE chip + Sync inventory + Refresh status', (tester) async {
      final db = AppDatabase.memory();
      addTearDown(() async => db.close());

      final store = MemoryTokenStore();
      await seedSignedIn(store);
      final session = buildSignedInSession(store: store);
      await session.restore();
      final controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: FakeProfileClient(),
        lock: InventoryBusyLock(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: InventorySyncCard(controller: controller, session: session),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const Key('inventory_online_chip')), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.byKey(const Key('inventory_sync_now')), findsOneWidget);
      expect(find.text('Sync inventory'), findsOneWidget);
      expect(find.byKey(const Key('inventory_refresh_status')), findsOneWidget);
      expect(find.text('Refresh status'), findsOneWidget);
      expect(find.byKey(const Key('inventory_last_sync')), findsOneWidget);
      expect(find.textContaining('Last sync:'), findsOneWidget);

      controller.dispose();
    });
  });
}
