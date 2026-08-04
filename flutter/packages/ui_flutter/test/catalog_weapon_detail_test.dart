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
    testWidgets('Possible rolls + craft OFF by default; craft hidden when unavailable',
        (tester) async {
      var canRoll = false;
      var craft = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              Column(
                children: [
                  CatalogDetailToggles(
                    showCanRoll: canRoll,
                    showCraft: craft,
                    craftAvailable: true,
                    onCanRollChanged: (v) => setState(() => canRoll = v),
                    onCraftChanged: (v) => setState(() => craft = v),
                  ),
                  CatalogDetailToggles(
                    key: const Key('toggles_no_craft'),
                    showCanRoll: false,
                    showCraft: false,
                    craftAvailable: false,
                    onCanRollChanged: (_) {},
                    onCraftChanged: (_) {},
                  ),
                ],
              ),
            );
          },
        ),
      );

      final canRollChip = tester
          .widget<FilterChip>(find.byKey(const Key('catalog_toggle_can_roll')).first);
      expect(canRollChip.selected, isFalse);
      expect(find.text('Possible rolls'), findsWidgets);
      expect(find.byKey(const Key('catalog_toggle_craft')), findsOneWidget);

      // craftAvailable false → craft chip hidden.
      expect(
        find.descendant(
          of: find.byKey(const Key('toggles_no_craft')),
          matching: find.byKey(const Key('catalog_toggle_craft')),
        ),
        findsNothing,
      );
    });
  });

  group('buildCatalogPerkColumns definition fallback', () {
    test('unowned always shows full possible rolls (not curated-only)', () {
      final cols = buildCatalogPerkColumns(
        socketPlugs: null,
        definitionSocketPlugs: const [
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 10,
            'reusablePlugHashes': [10, 11, 12],
          },
        ],
        plugNameByHash: const {
          10: 'Arrowhead Brake',
          11: 'Chambered',
          12: 'Corkscrew',
        },
        // Can-roll toggle is for owned copies; unowned ignores it.
        showCanRoll: false,
      );
      expect(cols, hasLength(1));
      expect(cols.single.cells.map((c) => c.hash).toSet(), {10, 11, 12});
      expect(cols.single.cells.every((c) => !c.selected), isTrue);
      expect(cols.single.cells.every((c) => c.fromCanRollPool), isTrue);
    });

    test('definition possible rolls include pool without can-roll flag', () {
      final cols = buildCatalogPerkColumns(
        definitionSocketPlugs: const [
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 10,
            'reusablePlugHashes': [10, 11],
          },
        ],
        plugNameByHash: const {10: 'Arrowhead Brake', 11: 'Chambered'},
        showCanRoll: false,
      );
      expect(cols.single.cells.map((c) => c.hash).toList(), [10, 11]);
      expect(cols.single.cells.every((c) => c.fromCanRollPool), isTrue);
    });

    test('owned ③ merges definition reusables when Possible rolls on', () {
      final cols = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnKind': 'intrinsic',
            'columnLabel': 'Intrinsic',
            'equippedPlugHash': 1,
            'reusablePlugHashes': [1],
          },
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 10,
            'reusablePlugHashes': [10],
          },
        ],
        definitionSocketPlugs: const [
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 10,
            'reusablePlugHashes': [10, 11, 12],
          },
        ],
        plugNameByHash: const {
          1: 'Frame',
          10: 'Arrowhead Brake',
          11: 'Chambered',
          12: 'Corkscrew',
        },
        showCanRoll: true,
      );
      expect(cols, hasLength(2));
      final barrel = cols.firstWhere((c) => c.label == 'Barrel');
      expect(barrel.cells.map((c) => c.hash).toSet(), {10, 11, 12});
      expect(
        barrel.cells.where((c) => c.fromCanRollPool).map((c) => c.hash).toSet(),
        {11, 12},
      );
    });

    test('column-label hash fallback treated as unknown', () {
      final cols = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnLabel': 'Trait',
            'equippedPlugHash': 555,
            'reusablePlugHashes': <int>[],
          },
        ],
        plugCards: const [],
        plugNameByHash: const {},
      );
      expect(cols.single.cells.single.unknown, isTrue);
      expect(cols.single.cells.single.displayName, 'Unknown perk');
    });

    test('Origin column present when origin plugs exist; absent when none', () {
      final withOrigin = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 10,
            'reusablePlugHashes': [10],
          },
          {
            'columnKind': 'origin',
            'columnLabel': 'Origin Trait',
            'equippedPlugHash': 90,
            'reusablePlugHashes': [90],
          },
        ],
        plugNameByHash: const {
          10: 'Fluted Barrel',
          90: 'Elliptical Orbit',
        },
      );
      expect(withOrigin.any((c) => c.kind == 'origin'), isTrue);
      expect(
        withOrigin.firstWhere((c) => c.kind == 'origin').cells.single.displayName,
        'Elliptical Orbit',
      );

      final noOrigin = buildCatalogPerkColumns(
        definitionSocketPlugs: const [
          {
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': 10,
            'reusablePlugHashes': [10, 11],
          },
        ],
        plugNameByHash: const {10: 'Fluted Barrel', 11: 'Arrowhead'},
      );
      expect(noOrigin.any((c) => c.kind == 'origin'), isFalse);
      expect(noOrigin.any((c) => c.label.toLowerCase().contains('origin')), isFalse);

      // Empty origin column never invented.
      final emptyOrigin = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnKind': 'origin',
            'columnLabel': 'Origin Trait',
            'equippedPlugHash': 0,
            'reusablePlugHashes': <int>[],
          },
        ],
      );
      expect(emptyOrigin, isEmpty);
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
    final defSockets = [
      {
        'columnKind': 'barrel',
        'columnLabel': 'Barrel',
        'equippedPlugHash': 10,
        'reusablePlugHashes': [10, 11, 12, 13],
      },
      {
        'columnKind': 'trait',
        'columnLabel': 'Trait',
        'equippedPlugHash': 20,
        'reusablePlugHashes': [20, 21, 22],
      },
    ];
    final names = {
      10: 'Fluted Barrel',
      11: 'Arrowhead Brake',
      12: 'Chambered Compensator',
      13: 'Polygonal Rifling',
      20: 'Kill Clip',
      21: 'Rampage',
      22: 'Frenzy',
    };

    test('owned default ①+②; ③ only after Possible rolls ON', () {
      final off = buildCatalogPerkColumns(
        socketPlugs: sockets,
        definitionSocketPlugs: defSockets,
        plugNameByHash: names,
        showCanRoll: false,
      );
      expect(off.length, 2);
      // ① selected + ② instance reusables
      expect(off[0].cells.map((c) => c.hash).toList(), [10, 11, 12]);
      expect(off[0].cells.where((c) => c.selected).map((c) => c.hash), [10]);
      expect(
        off[0].cells.where((c) => c.isInstanceUnselected).map((c) => c.hash).toSet(),
        {11, 12},
      );
      expect(off[0].cells.every((c) => !c.fromCanRollPool), isTrue);
      // Definition-only 13 must not appear until Possible rolls ON.
      expect(off[0].cells.any((c) => c.hash == 13), isFalse);

      final on = buildCatalogPerkColumns(
        socketPlugs: sockets,
        definitionSocketPlugs: defSockets,
        plugNameByHash: names,
        showCanRoll: true,
      );
      expect(on[0].cells.map((c) => c.hash).toSet(), {10, 11, 12, 13});
      expect(
        on[0].cells.where((c) => c.fromCanRollPool).map((c) => c.hash).toSet(),
        {13},
      );
      // ② stay unselected instance, not reclassified as pool.
      expect(
        on[0].cells.where((c) => c.isInstanceUnselected).map((c) => c.hash).toSet(),
        {11, 12},
      );
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

    test('enhanced flag from name heuristic and host map', () {
      final cols = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': 20,
            'reusablePlugHashes': [20, 21],
          },
        ],
        plugNameByHash: const {
          20: 'Kill Clip',
          21: 'Enhanced Frenzy',
        },
        plugEnhancedByHash: const {20: true},
      );
      final cells = cols.single.cells;
      expect(cells.firstWhere((c) => c.hash == 20).enhanced, isTrue);
      expect(cells.firstWhere((c) => c.hash == 21).enhanced, isTrue);
    });

    testWidgets('①② default visible; ③ pool only when Possible rolls on',
        (tester) async {
      final colsOff = buildCatalogPerkColumns(
        socketPlugs: sockets,
        definitionSocketPlugs: defSockets,
        plugNameByHash: names,
        showCanRoll: false,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: colsOff)));
      expect(find.byKey(const Key('perk_selected_10')), findsOneWidget);
      expect(find.byKey(const Key('perk_cell_11')), findsOneWidget); // ②
      expect(find.byKey(const Key('perk_cell_13')), findsNothing); // ③ hidden

      final colsOn = buildCatalogPerkColumns(
        socketPlugs: sockets,
        definitionSocketPlugs: defSockets,
        plugNameByHash: names,
        showCanRoll: true,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: colsOn)));
      expect(find.byKey(const Key('perk_cell_13')), findsOneWidget);
      expect(find.text('Polygonal Rifling'), findsOneWidget);
    });

    testWidgets('equal Expanded columns; no horizontal Scrollable at width 400',
        (tester) async {
      final multi = <Map<String, Object?>>[
        for (var i = 0; i < 5; i++)
          {
            'columnKind': i == 4 ? 'origin' : 'trait',
            'columnLabel': i == 4 ? 'Origin Trait' : 'Col $i',
            'equippedPlugHash': 100 + i,
            'reusablePlugHashes': [100 + i, 200 + i, 300 + i],
          },
      ];
      final namesMulti = <int, String>{
        for (var i = 0; i < 5; i++) ...{
          100 + i: 'Sel $i',
          200 + i: 'Uns $i',
          300 + i: 'Pool $i',
        },
      };
      final cols = buildCatalogPerkColumns(
        socketPlugs: multi,
        definitionSocketPlugs: multi,
        plugNameByHash: namesMulti,
        showCanRoll: true,
      );
      expect(cols.length, 5);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: Scaffold(
            body: SizedBox(
              width: kCatalogWeaponsDetailWidth,
              height: 600,
              child: CatalogPerkGrid(columns: cols),
            ),
          ),
        ),
      );
      await tester.pump();

      final grid = find.byKey(const Key('catalog_perk_grid'));
      expect(grid, findsOneWidget);
      final gridSize = tester.getSize(grid);
      expect(gridSize.width, lessThanOrEqualTo(kCatalogWeaponsDetailWidth + 0.5));

      // No horizontal scroll view on the perk grid itself.
      final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
      for (final s in scrollables) {
        expect(
          s.axisDirection == AxisDirection.left ||
              s.axisDirection == AxisDirection.right,
          isFalse,
          reason: 'perk grid must not use horizontal Scrollable',
        );
      }

      // Equal-width columns: Expanded children of the Row.
      final row = tester.widget<Row>(grid);
      expect(row.children.whereType<Expanded>().length, 5);
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
      expect(find.byKey(const Key('perk_enhanced_mark_99')), findsOneWidget);
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

  group('CatalogWeaponMetaStrip', () {
    testWidgets('icon-only meta; no type·frame text; no KINETIC/OWNED pills',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CatalogWeaponMetaStrip(
            itemTypeName: 'Pulse Rifle',
            frame: 'Lightweight Frame',
            element: 'Kinetic',
            slot: 'Kinetic',
            ammo: 'Primary',
            owned: true,
            ownedCount: 5,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('catalog_weapon_meta_strip')), findsOneWidget);
      expect(find.byKey(const Key('catalog_meta_type')), findsOneWidget);
      expect(find.byKey(const Key('catalog_meta_frame')), findsOneWidget);
      expect(find.byKey(const Key('catalog_meta_element')), findsOneWidget);
      expect(find.byKey(const Key('catalog_meta_slot')), findsOneWidget);
      expect(find.byKey(const Key('catalog_meta_ammo')), findsOneWidget);
      expect(find.byKey(const Key('catalog_meta_owned_count')), findsOneWidget);
      expect(find.text('×5'), findsOneWidget);

      // No text subtitle or text pills.
      expect(find.textContaining('Pulse Rifle ·'), findsNothing);
      expect(find.text('KINETIC'), findsNothing);
      expect(find.text('OWNED'), findsNothing);
      expect(find.textContaining('Owned ×'), findsNothing);
    });
  });

  group('CatalogWeaponDetail', () {
    testWidgets('icon-only meta strip; no type subtitle or KINETIC/OWNED pills',
        (tester) async {
      const item = CatalogItem(
        hash: 99,
        name: 'Chattering Bone',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Pulse Rifle',
        frame: 'Lightweight Frame',
        isExotic: false,
        owned: true,
        ownedCount: 5,
      );
      final instances = [
        _inst(
          id: 'a',
          power: 550,
          socketPlugs: const [
            {
              'columnKind': 'origin',
              'columnLabel': 'Origin Trait',
              'equippedPlugHash': 90,
              'reusablePlugHashes': [90],
            },
            {
              'columnLabel': 'Trait',
              'equippedPlugHash': 20,
              'reusablePlugHashes': [20, 21],
            },
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          CatalogWeaponDetail(
            item: item,
            instances: instances,
            craftAvailable: false,
            onCanRollChanged: (_) {},
            onCraftChanged: (_) {},
            plugNameByHash: const {
              20: 'Rapid Hit',
              21: 'Overflow',
              90: 'Elliptical Orbit',
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('catalog_weapon_meta_strip')), findsOneWidget);
      expect(find.text('Pulse Rifle · Lightweight Frame · Kinetic'), findsNothing);
      expect(find.text('KINETIC'), findsNothing);
      expect(find.text('OWNED'), findsNothing);
      // Origin present when data.
      expect(find.text('ORIGIN TRAIT'), findsOneWidget);
      expect(find.text('Elliptical Orbit'), findsOneWidget);
      // Craft hidden.
      expect(find.byKey(const Key('catalog_toggle_craft')), findsNothing);
      // ①+② default (not just selected).
      expect(find.byKey(const Key('perk_selected_20')), findsOneWidget);
      expect(find.byKey(const Key('perk_cell_21')), findsOneWidget);
    });

    testWidgets('owned: ①+② default; ③ after Possible rolls ON', (tester) async {
      const item = CatalogItem(
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
              'columnKind': 'trait',
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
                definitionSocketPlugs: const [
                  {
                    'columnKind': 'trait',
                    'columnLabel': 'Trait',
                    'equippedPlugHash': 20,
                    'reusablePlugHashes': [20, 21, 22],
                  },
                ],
                plugNameByHash: const {
                  20: 'Frenzy',
                  21: 'Adrenaline Junkie',
                  22: 'Kill Clip',
                },
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
      expect(find.text('Possible rolls'), findsOneWidget);
      expect(find.byKey(const Key('catalog_stub_set')), findsOneWidget);
      final setBtn =
          tester.widget<FilledButton>(find.byKey(const Key('catalog_stub_set')));
      expect(setBtn.onPressed, isNull);
      expect(find.byKey(const Key('weapon_instance_strip')), findsOneWidget);
      expect(find.byKey(const Key('catalog_perk_section_perks')), findsOneWidget);
      expect(selected, 'high');

      // Switch to instance with sockets for tier assertions.
      await tester.tap(find.byKey(const Key('instance_chip_low')));
      await tester.pump();
      expect(find.byKey(const Key('perk_cell_21')), findsOneWidget); // ②
      expect(find.byKey(const Key('perk_cell_22')), findsNothing); // ③ off

      await tester.tap(find.byKey(const Key('catalog_toggle_can_roll')));
      await tester.pump();
      expect(canRoll, isTrue);
      expect(find.byKey(const Key('perk_cell_22')), findsOneWidget); // ③ on
    });

    testWidgets('unowned: POSSIBLE ROLLS + full ③; no Possible rolls toggle',
        (tester) async {
      const item = CatalogItem(
        hash: 50,
        name: 'Hung Jury SR4',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Scout Rifle',
        frame: 'Precision Frame',
        isExotic: false,
        owned: false,
      );

      await tester.pumpWidget(
        _wrap(
          CatalogWeaponDetail(
            item: item,
            instances: const [],
            definitionSocketPlugs: const [
              {
                'columnKind': 'barrel',
                'columnLabel': 'Barrel',
                'equippedPlugHash': 1,
                'reusablePlugHashes': [1, 2],
              },
              {
                'columnKind': 'trait',
                'columnLabel': 'Trait 1',
                'equippedPlugHash': 3,
                'reusablePlugHashes': [3, 4],
              },
            ],
            plugNameByHash: const {
              1: 'Volatile Launch',
              2: 'Confined Launch',
              3: 'Impulse Amplifier',
              4: 'Clown Cartridge',
            },
            onCanRollChanged: (_) {},
            onCraftChanged: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('catalog_perk_section_possible_rolls')),
        findsOneWidget,
      );
      expect(find.text('POSSIBLE ROLLS'), findsOneWidget);
      expect(find.byKey(const Key('catalog_toggle_can_roll')), findsNothing);
      expect(find.byKey(const Key('catalog_toggle_craft')), findsNothing);
      expect(find.text('Volatile Launch'), findsOneWidget);
      expect(find.text('Confined Launch'), findsOneWidget);
      expect(find.text('Impulse Amplifier'), findsOneWidget);
      expect(find.text('Clown Cartridge'), findsOneWidget);
      expect(find.byKey(const Key('catalog_perk_grid')), findsOneWidget);
      // No Origin when definition has none.
      expect(find.text('ORIGIN TRAIT'), findsNothing);
      // Icon-only meta.
      expect(find.byKey(const Key('catalog_weapon_meta_strip')), findsOneWidget);
      expect(find.textContaining('Scout Rifle ·'), findsNothing);
    });
  });
}
