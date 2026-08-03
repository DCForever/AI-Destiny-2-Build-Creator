import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
  );
}

CatalogInstanceProjection _inst({
  required String id,
  required int power,
  List<Map<String, Object?>>? socketPlugs,
  bool isCrafted = false,
}) {
  return CatalogInstanceProjection(
    instanceId: id,
    itemHash: 99,
    bucket: 'Equippable',
    location: 'Vault',
    power: power,
    isCrafted: isCrafted,
    socketPlugs: socketPlugs,
    syncedAt: '2026-01-01T00:00:00.000Z',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogDetailToggles', () {
    testWidgets('can-roll and craft OFF by default', (tester) async {
      var canRoll = false;
      var craft = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogDetailToggles(
                showCanRoll: canRoll,
                showCraft: craft,
                onCanRollChanged: (v) => setState(() => canRoll = v),
                onCraftChanged: (v) => setState(() => craft = v),
              ),
            );
          },
        ),
      );

      final canRollChip =
          tester.widget<FilterChip>(find.byKey(const Key('catalog_toggle_can_roll')));
      final craftChip =
          tester.widget<FilterChip>(find.byKey(const Key('catalog_toggle_craft')));
      expect(canRollChip.selected, isFalse);
      expect(craftChip.selected, isFalse);
    });
  });

  group('buildCatalogPerkColumns / CatalogPerkGrid', () {
    final sockets = [
      {
        'columnKind': 'barrel',
        'columnLabel': 'Barrel',
        'equippedPlugHash': 10,
        'reusablePlugHashes': [10, 11, 12],
      },
      {
        'columnKind': 'trait',
        'columnLabel': 'Trait',
        'equippedPlugHash': 20,
        'reusablePlugHashes': [20, 21],
      },
    ];
    final names = {
      10: 'Fluted Barrel',
      11: 'Arrowhead Brake',
      12: 'Chambered Compensator',
      20: 'Kill Clip',
      21: 'Rampage',
    };

    test('selected plugs only when can-roll off; pool when on', () {
      final off = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCanRoll: false,
      );
      expect(off.length, 2);
      expect(off[0].cells.map((c) => c.hash).toList(), [10]);
      expect(off[0].cells.single.selected, isTrue);
      expect(off[0].cells.single.fromCanRollPool, isFalse);

      final on = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCanRoll: true,
      );
      expect(on[0].cells.map((c) => c.hash).toList(), [10, 11, 12]);
      expect(on[0].cells.where((c) => c.fromCanRollPool).length, 2);
    });

    test('craft pool only when toggled; never invent when empty', () {
      final craftCols = [
        CatalogPerkColumn(
          label: 'Trait',
          kind: 'trait',
          cells: const [
            CatalogPerkCell(hash: 99, displayName: 'Craft Trait'),
          ],
        ),
      ];
      final off = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: false,
        craftColumns: craftCols,
      );
      expect(off.any((c) => c.cells.any((x) => x.hash == 99)), isFalse);

      final on = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: true,
        craftColumns: craftCols,
      );
      final trait = on.firstWhere((c) => c.label == 'Trait');
      expect(trait.cells.any((c) => c.hash == 99 && c.fromCraftPool), isTrue);

      final emptyCraft = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: true,
        craftColumns: const [],
      );
      expect(emptyCraft.every((c) => c.cells.every((x) => !x.fromCraftPool)),
          isTrue);
    });

    testWidgets('selected plugs distinct; can-roll pool only when toggled on',
        (tester) async {
      final colsOff = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCanRoll: false,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: colsOff)));
      expect(find.byKey(const Key('perk_selected_10')), findsOneWidget);
      expect(find.byKey(const Key('perk_cell_11')), findsNothing);

      final colsOn = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCanRoll: true,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: colsOn)));
      expect(find.byKey(const Key('perk_cell_11')), findsOneWidget);
      expect(find.text('Arrowhead Brake'), findsOneWidget);
    });

    testWidgets('craftable same-column cells when on; off shows no craft pool',
        (tester) async {
      final craftCols = [
        const CatalogPerkColumn(
          label: 'Trait',
          kind: 'trait',
          cells: [CatalogPerkCell(hash: 99, displayName: 'Enhanced Kill Clip')],
        ),
      ];
      final off = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: false,
        craftColumns: craftCols,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: off)));
      expect(find.text('Enhanced Kill Clip'), findsNothing);

      final on = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: true,
        craftColumns: craftCols,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: on)));
      expect(find.text('Enhanced Kill Clip'), findsOneWidget);
      expect(find.byKey(const Key('perk_cell_99')), findsOneWidget);
    });
  });

  group('ExoticIdentityBlock', () {
    testWidgets('catalyst display-only; independent of craft; never gates',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ExoticIdentityBlock(
            intrinsicName: 'Wolfpack Rounds',
            intrinsicDescription: 'Rockets spawn wolfpack seekers.',
            catalystName: 'Gjallarhorn Catalyst',
            catalystComplete: false,
          ),
        ),
      );
      expect(find.byKey(const Key('exotic_identity_block')), findsOneWidget);
      expect(find.byKey(const Key('exotic_intrinsic_name')), findsOneWidget);
      expect(find.byKey(const Key('exotic_catalyst_name')), findsOneWidget);
      expect(
        find.byKey(const Key('exotic_catalyst_display_only')),
        findsOneWidget,
      );
      // No gate buttons / save blockers.
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.textContaining('gate'), findsOneWidget);
    });
  });

  group('CatalogHashFooter', () {
    testWidgets('unknown perk label + hash; no bare-hash primary name',
        (tester) async {
      final cols = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnLabel': 'Trait',
            'equippedPlugHash': 555,
            'reusablePlugHashes': <int>[],
          },
        ],
        plugNameByHash: const {},
      );
      expect(cols.single.cells.single.displayName, 'Unknown perk');
      expect(cols.single.cells.single.unknown, isTrue);

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              CatalogPerkGrid(columns: cols),
              CatalogHashFooter(unknownHashes: unknownPerkHashes(cols)),
            ],
          ),
        ),
      );
      expect(find.text('Unknown perk'), findsOneWidget);
      expect(find.byKey(const Key('catalog_hash_footer_555')), findsOneWidget);
      expect(find.text('#555'), findsNothing); // not bare-hash primary
      expect(find.textContaining('Unknown perk · #555'), findsOneWidget);
    });
  });

  group('CatalogOutboundStubs', () {
    testWidgets('Set and Synergy present and disabled', (tester) async {
      await tester.pumpWidget(_wrap(const CatalogOutboundStubs()));
      final setBtn =
          tester.widget<FilledButton>(find.byKey(const Key('catalog_stub_set')));
      final synBtn = tester
          .widget<FilledButton>(find.byKey(const Key('catalog_stub_synergy')));
      expect(setBtn.onPressed, isNull);
      expect(synBtn.onPressed, isNull);
    });
  });

  group('WeaponInstanceStrip', () {
    testWidgets('multi-instance power-desc; default selection highest',
        (tester) async {
      final instances = [
        _inst(id: 'a', power: 1800),
        _inst(id: 'b', power: 1810),
        _inst(id: 'c', power: 1790),
      ];
      expect(defaultHighestPowerInstanceId(instances), 'b');

      String? selected = defaultHighestPowerInstanceId(instances);
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              WeaponInstanceStrip(
                instances: instances,
                selectedInstanceId: selected,
                onSelect: (i) => setState(() => selected = i.instanceId),
              ),
            );
          },
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips.length, 3);
      // First displayed is highest power (power-desc).
      expect(chips.first.key, const Key('instance_chip_b'));
      expect(chips.first.selected, isTrue);

      await tester.tap(find.byKey(const Key('instance_chip_a')));
      await tester.pump();
      expect(selected, 'a');
    });
  });

  group('CatalogWeaponDetail', () {
    testWidgets('integrates toggles off + stubs disabled + strip', (tester) async {
      final item = const CatalogItem(
        hash: 99,
        name: 'Funnelweb',
        slot: 'Energy',
        element: 'Void',
        ammo: 'Primary',
        itemTypeName: 'Submachine Gun',
        isExotic: false,
        owned: true,
        ownedCount: 2,
      );
      final instances = [
        _inst(
          id: 'low',
          power: 1800,
          socketPlugs: const [
            {
              'columnLabel': 'Trait',
              'equippedPlugHash': 20,
              'reusablePlugHashes': [20, 21],
            },
          ],
        ),
        _inst(id: 'high', power: 1815),
      ];

      var canRoll = false;
      var craft = false;
      String? selected = defaultHighestPowerInstanceId(instances);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogWeaponDetail(
                item: item,
                instances: instances,
                selectedInstanceId: selected,
                onSelectInstance: (i) =>
                    setState(() => selected = i.instanceId),
                showCanRoll: canRoll,
                showCraft: craft,
                craftAvailable: true,
                onCanRollChanged: (v) => setState(() => canRoll = v),
                onCraftChanged: (v) => setState(() => craft = v),
                plugNameByHash: const {20: 'Frenzy', 21: 'Adrenaline Junkie'},
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('catalog_toggle_can_roll')), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('catalog_toggle_can_roll')))
            .selected,
        isFalse,
      );
      expect(find.byKey(const Key('catalog_stub_set')), findsOneWidget);
      final setBtn =
          tester.widget<FilledButton>(find.byKey(const Key('catalog_stub_set')));
      expect(setBtn.onPressed, isNull);
      expect(find.byKey(const Key('weapon_instance_strip')), findsOneWidget);
      expect(selected, 'high');
    });
  });
}
