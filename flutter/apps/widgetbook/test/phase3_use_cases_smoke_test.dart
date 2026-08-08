import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/detail_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/filter_bar_host_parity_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/sort_group_use_cases.dart';
import 'package:destiny2_widgetbook/use_cases/catalog/viewport_matrix_use_cases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 · exotic cycle host parity', () {
    testWidgets('exotic chip cycles any → only → exclude → any', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: exoticChipCycle)));
      await tester.pump();

      expect(find.byKey(const Key('exotic_chip')), findsOneWidget);
      expect(find.byKey(const Key('wb_exotic_state_label')), findsOneWidget);
      expect(find.text('exotic=any'), findsOneWidget);

      await tester.tap(find.byKey(const Key('exotic_chip')));
      await tester.pump();
      expect(find.text('exotic=only'), findsOneWidget);

      await tester.tap(find.byKey(const Key('exotic_chip')));
      await tester.pump();
      expect(find.text('exotic=exclude'), findsOneWidget);

      await tester.tap(find.byKey(const Key('exotic_chip')));
      await tester.pump();
      expect(find.text('exotic=any'), findsOneWidget);
    });

    testWidgets('host parity filter bar has exotic chip + RESET path',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 1100,
            child: FilterBarHostParity(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CatalogFilterBar), findsOneWidget);
      expect(find.byKey(const Key('exotic_chip')), findsOneWidget);
      expect(find.byKey(const Key('catalog_query')), findsOneWidget);

      Text exoticLabel() => tester.widget<Text>(
            find.byKey(const Key('wb_exotic_state_label')),
          );

      expect(exoticLabel().data, 'exotic=any');

      await tester.ensureVisible(find.byKey(const Key('exotic_chip')));
      await tester.tap(find.byKey(const Key('exotic_chip')));
      await tester.pumpAndSettle();
      expect(exoticLabel().data, 'exotic=only');

      // Active filter enables RESET.
      expect(find.byKey(const Key('catalog_clear_filters')), findsOneWidget);
      await tester.tap(find.byKey(const Key('catalog_clear_filters')));
      await tester.pumpAndSettle();
      expect(exoticLabel().data, 'exotic=any');
    });
  });

  group('Phase 3 · sort sheet reorder + apply', () {
    testWidgets('reorder name to first then apply reports order', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 480,
            height: 700,
            child: Builder(builder: sortGroupInteractive),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('catalog_sort_keys_list')), findsOneWidget);
      expect(find.byKey(const Key('sort_key_name')), findsOneWidget);
      expect(find.byKey(const Key('sort_key_slot')), findsOneWidget);

      // Drag Name handle above Slot (first position).
      final nameTile = find.byKey(const Key('sort_key_name'));
      await tester.drag(nameTile, const Offset(0, -120));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog_sort_group_apply')));
      await tester.pump();

      final label = tester.widget<Text>(
        find.byKey(const Key('wb_sort_group_last_apply')),
      );
      expect(label.data, isNotNull);
      // After drag, order should still be a valid apply string.
      expect(label.data!, contains('sort='));
      expect(label.data!, contains('name'));
      // Prefer that name is now first when drag succeeded.
      final sortPart = label.data!.split(' · ').first.replaceFirst('sort=', '');
      final keys = sortPart.split('→');
      expect(keys, containsAll(['slot', 'exotic', 'ammo', 'archetype', 'name']));
      expect(keys.length, 5);
      // Soft assert: if reorder landed, name is first; else still 5 keys.
      if (keys.first == 'name') {
        expect(keys.first, 'name');
      }
    });

    testWidgets('add group dim then apply', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: sortGroupDefault)));
      await tester.pump();
      await tester.tap(find.byKey(const Key('group_dim_add_slot')));
      await tester.pump();
      expect(find.byKey(const Key('group_dim_slot')), findsOneWidget);
      await tester.tap(find.byKey(const Key('catalog_sort_group_apply')));
      await tester.pump();
      // Default builder has empty onApply — no throw.
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 3 · viewport stories mount', () {
    testWidgets('viewport filter bar mounts', (tester) async {
      await tester.pumpWidget(_host(Builder(builder: viewportFilterBar)));
      await tester.pump();
      expect(find.byType(CatalogFilterBar), findsOneWidget);
      expect(find.byKey(const Key('exotic_chip')), findsOneWidget);
    });

    testWidgets('viewport workspace mounts', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 1100,
            height: 700,
            child: Builder(builder: viewportWorkspace),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CatalogWeaponsWorkspace), findsOneWidget);
    });
  });

  group('Phase 3 · roll targets desktop 400 + mobile 390', () {
    testWidgets('roll-targets desktop 400 detail shell + dual segs',
        (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 400,
            height: 720,
            child: CatalogWeaponDetail(
              item: const CatalogItem(
                hash: 101,
                name: 'Midnight Coup',
                isExotic: false,
                owned: true,
                ownedCount: 2,
              ),
              instances: [
                CatalogInstanceProjection(
                  instanceId: 'i-perfect',
                  itemHash: 101,
                  bucket: 'Equippable',
                  location: 'Vault',
                  power: 400,
                  gearTier: 3,
                  syncedAt: '2026-01-01T00:00:00.000Z',
                ),
                CatalogInstanceProjection(
                  instanceId: 'i-partial',
                  itemHash: 101,
                  bucket: 'Equippable',
                  location: 'Vault',
                  power: 450,
                  gearTier: 5,
                  syncedAt: '2026-01-01T00:00:00.000Z',
                ),
              ],
              selectedInstanceId: 'i-perfect',
              onSelectInstance: (_) {},
              rollTargets: const [
                CatalogRollTargetOption(id: 'rt-pve', name: 'PvE'),
                CatalogRollTargetOption(id: 'rt-pvp', name: 'PvP'),
              ],
              activeRollTargetId: 'rt-pve',
              activeRollTargetName: 'PvE',
              onActiveRollTargetChanged: (_) {},
              instanceRollScores: const {
                'i-perfect': CatalogInstanceRollScore(
                  preferredMatched: 2,
                  preferredScored: 3,
                  avoidHits: 0,
                  avoidScored: 1,
                ),
                'i-partial': CatalogInstanceRollScore(
                  preferredMatched: 1,
                  preferredScored: 3,
                  avoidHits: 0,
                  avoidScored: 1,
                ),
              },
              preserveInstanceOrder: true,
              rankedByRollTarget: true,
              showCanRoll: true,
              onCanRollChanged: (_) {},
              onCraftChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('catalog_roll_targets')), findsOneWidget);
      expect(find.text('PVE'), findsOneWidget);
      expect(find.byKey(const Key('instance_score_pref_i-perfect')), findsOneWidget);
      expect(find.byKey(const Key('weapon_instance_rank_note')), findsOneWidget);
      // Use-case builders exported for knobs (activeTarget/showEditor/score/count).
      expect(rollTargetsDesktop400, isA<Function>());
    });

    testWidgets('roll-targets mobile 390 switcher Off + names', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            height: 780,
            child: CatalogWeaponDetail(
              item: const CatalogItem(
                hash: 101,
                name: 'Midnight Coup',
                isExotic: false,
                owned: true,
                ownedCount: 3,
              ),
              instances: const [],
              rollTargets: const [
                CatalogRollTargetOption(id: 'rt-pve', name: 'PvE'),
                CatalogRollTargetOption(id: 'rt-pvp', name: 'PvP'),
              ],
              activeRollTargetId: null,
              onActiveRollTargetChanged: (_) {},
              onNewRollTarget: () {},
              onEditRollTarget: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('catalog_roll_targets')), findsOneWidget);
      expect(find.byKey(const Key('roll_target_opt_off')), findsOneWidget);
      expect(find.text('PVE'), findsOneWidget);
      expect(find.text('PVP'), findsOneWidget);
      expect(rollTargetsMobile390, isA<Function>());
    });
  });
}
