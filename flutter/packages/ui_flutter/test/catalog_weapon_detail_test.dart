import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    testWidgets(
        'Possible rolls is mock view-toggle (not FilterChip); OFF default; Semantics toggled; craft hidden when craftAvailable false',
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

      // Mock residual chrome: no Material FilterChip look-alike.
      expect(find.byType(FilterChip), findsNothing);
      // Two toggle rows (craftAvailable true + false) both expose can-roll key.
      expect(find.byKey(const Key('catalog_toggle_can_roll')), findsNWidgets(2));
      expect(find.textContaining('POSSIBLE ROLLS'), findsWidgets);

      final canRollFinder = find.byKey(const Key('catalog_toggle_can_roll')).first;
      final canRollSem = tester.getSemantics(canRollFinder);
      expect(canRollSem.hasFlag(SemanticsFlag.isToggled), isFalse);
      expect(canRollSem.hasFlag(SemanticsFlag.isButton), isTrue);

      expect(find.byKey(const Key('catalog_toggle_craft')), findsOneWidget);

      // craftAvailable false → craft toggle hidden.
      expect(
        find.descendant(
          of: find.byKey(const Key('toggles_no_craft')),
          matching: find.byKey(const Key('catalog_toggle_craft')),
        ),
        findsNothing,
      );

      // Tap first (craftAvailable) toggles Semantics + callback.
      await tester.tap(canRollFinder);
      await tester.pump();
      expect(canRoll, isTrue);
      final toggledSem = tester.getSemantics(canRollFinder);
      expect(toggledSem.hasFlag(SemanticsFlag.isToggled), isTrue);
    });

    testWidgets(
        'craft toggle same chrome as Possible rolls when craftAvailable true',
        (tester) async {
      var craft = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogDetailToggles(
                showCanRoll: false,
                showCraft: craft,
                craftAvailable: true,
                onCanRollChanged: (_) {},
                onCraftChanged: (v) => setState(() => craft = v),
              ),
            );
          },
        ),
      );
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byKey(const Key('catalog_toggle_craft')), findsOneWidget);
      final craftSem = tester.getSemantics(
        find.byKey(const Key('catalog_toggle_craft')),
      );
      expect(craftSem.hasFlag(SemanticsFlag.isToggled), isFalse);
      expect(craftSem.hasFlag(SemanticsFlag.isButton), isTrue);
      await tester.tap(find.byKey(const Key('catalog_toggle_craft')));
      await tester.pump();
      expect(craft, isTrue);
      expect(
        tester
            .getSemantics(find.byKey(const Key('catalog_toggle_craft')))
            .hasFlag(SemanticsFlag.isToggled),
        isTrue,
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

    testWidgets(
        'owned: ① badge on selected; ② badge + gold chevron on unselected',
        (tester) async {
      final cols = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: cols)));
      // ① selected badge
      expect(find.byKey(const Key('perk_tier_badge_10')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('perk_tier_badge_10')),
          matching: find.text('①'),
        ),
        findsOneWidget,
      );
      // ② unselected badge + gold chevron
      expect(find.byKey(const Key('perk_tier_badge_11')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('perk_tier_badge_11')),
          matching: find.text('②'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('perk_chevron_11')), findsOneWidget);
      // Selected has no chevron
      expect(find.byKey(const Key('perk_chevron_10')), findsNothing);
      // Band labels present for owned tiers
      expect(find.byKey(const Key('perk_band_selected_0')), findsOneWidget);
      expect(find.byKey(const Key('perk_band_unselected_0')), findsOneWidget);
      expect(find.byKey(const Key('catalog_perk_legend')), findsOneWidget);
    });

    testWidgets(
        '③ ON: dashed muted pool cells + tier badge 3; no E on pool cells',
        (tester) async {
      final cols = buildCatalogPerkColumns(
        socketPlugs: sockets,
        definitionSocketPlugs: defSockets,
        plugNameByHash: {
          ...names,
          13: 'Enhanced Polygonal',
        },
        plugEnhancedByHash: const {13: true},
        showCanRoll: true,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: cols)));
      expect(find.byKey(const Key('perk_cell_13')), findsOneWidget);
      expect(find.byKey(const Key('perk_tier_badge_13')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('perk_tier_badge_13')),
          matching: find.text('③'),
        ),
        findsOneWidget,
      );
      // No E chrome on pool even if map says enhanced.
      expect(find.byKey(const Key('perk_enhanced_mark_13')), findsNothing);
      expect(find.byKey(const Key('perk_band_possible_0')), findsOneWidget);
    });

    testWidgets(
        'uniform perk tile minHeight (~48); equal Expanded @400; no H-scroll',
        (tester) async {
      final cols = buildCatalogPerkColumns(
        socketPlugs: sockets,
        definitionSocketPlugs: defSockets,
        plugNameByHash: names,
        showCanRoll: true,
      );
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

      // Uniform min height for every perk cell.
      for (final hash in [10, 11, 13]) {
        final size = tester.getSize(find.byKey(Key('perk_cell_$hash')));
        expect(
          size.height,
          greaterThanOrEqualTo(kCatalogPerkCellMinHeight - 0.5),
          reason: 'perk cell $hash must be uniform minHeight',
        );
      }

      final grid = find.byKey(const Key('catalog_perk_grid'));
      final row = tester.widget<Row>(grid);
      expect(row.children.whereType<Expanded>().length, cols.length);

      final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
      for (final s in scrollables) {
        expect(
          s.axisDirection == AxisDirection.left ||
              s.axisDirection == AxisDirection.right,
          isFalse,
        );
      }
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
          cells: [CatalogPerkCell(hash: 99, displayName: 'Enhanced Harmony')],
          canBeEnhanced: true,
        ),
      ];
      final off = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: false,
        craftColumns: craftCols,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: off)));
      expect(find.text('Harmony'), findsNothing);
      expect(find.text('Enhanced Harmony'), findsNothing);

      final on = buildCatalogPerkColumns(
        socketPlugs: sockets,
        plugNameByHash: names,
        showCraft: true,
        craftColumns: craftCols,
      );
      await tester.pumpWidget(_wrap(CatalogPerkGrid(columns: on)));
      // Craft pool: stripped base display, no E mark on pool cell.
      expect(find.text('Harmony'), findsOneWidget);
      expect(find.byKey(const Key('perk_cell_99')), findsOneWidget);
      expect(find.byKey(const Key('perk_enhanced_mark_99')), findsNothing);
      expect(on.any((c) => c.canBeEnhanced), isTrue);
    });

    test('pool/unowned: no E cells; canBeEnhanced note flag; identity collapse',
        () {
      final unowned = buildCatalogPerkColumns(
        definitionSocketPlugs: const [
          {
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': 20,
            'reusablePlugHashes': [20, 21, 22],
          },
        ],
        plugNameByHash: const {
          20: 'Kill Clip',
          21: 'Enhanced Kill Clip',
          22: 'Frenzy',
        },
        plugEnhancedByHash: const {21: true},
      );
      expect(unowned.single.cells.map((c) => c.hash).toSet(), {20, 22});
      expect(unowned.single.cells.every((c) => !c.enhanced), isTrue);
      expect(unowned.single.canBeEnhanced, isTrue);
      expect(catalogColumnsCanBeEnhanced(unowned), isTrue);

      final ownedPool = buildCatalogPerkColumns(
        socketPlugs: const [
          {
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': 20,
            'reusablePlugHashes': [20, 21],
          },
        ],
        definitionSocketPlugs: const [
          {
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': 20,
            'reusablePlugHashes': [20, 21, 30],
          },
        ],
        plugNameByHash: const {
          20: 'Kill Clip',
          21: 'Rampage',
          30: 'Enhanced Frenzy',
        },
        showCanRoll: true,
      );
      // ①+② + ③ Frenzy (stripped); no E on pool.
      expect(
        ownedPool.single.cells.where((c) => c.fromCanRollPool).every(
              (c) => !c.enhanced,
            ),
        isTrue,
      );
      expect(ownedPool.single.canBeEnhanced, isTrue);
      expect(
        ownedPool.single.cells
            .where((c) => c.fromCanRollPool)
            .map((c) => c.displayName)
            .toSet(),
        contains('Frenzy'),
      );
    });

    test('instance ①/② get E from host map; name heuristic still works', () {
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
      expect(cols.single.cells.firstWhere((c) => c.hash == 20).enhanced, isTrue);
      expect(cols.single.cells.firstWhere((c) => c.hash == 21).enhanced, isTrue);
      expect(cols.single.cells.every((c) => !c.fromCanRollPool), isTrue);
    });

    testWidgets('③ ON headers: ellipsis + Tooltip + Semantics; no H-scroll',
        (tester) async {
      final multi = <Map<String, Object?>>[
        for (var i = 0; i < 5; i++)
          {
            'columnKind': i == 4 ? 'origin' : 'trait',
            'columnLabel': i == 4
                ? 'Origin Trait Super Long Label'
                : 'Masterwork Column $i Extra',
            'equippedPlugHash': 100 + i,
            'reusablePlugHashes': [100 + i],
          },
      ];
      final namesMulti = <int, String>{
        for (var i = 0; i < 5; i++) 100 + i: 'Sel $i',
      };
      final cols = buildCatalogPerkColumns(
        socketPlugs: multi,
        plugNameByHash: namesMulti,
      );

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

      expect(find.byKey(const Key('perk_column_header_0')), findsOneWidget);
      expect(find.byKey(const Key('perk_column_header_4')), findsOneWidget);

      // Tooltip + Semantics wrappers present on headers.
      final header = find.byKey(const Key('perk_column_header_4'));
      expect(
        find.descendant(of: header, matching: find.byType(Tooltip)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byType(Semantics)),
        findsWidgets,
      );
      final tip = tester.widget<Tooltip>(
        find.descendant(of: header, matching: find.byType(Tooltip)),
      );
      expect(tip.message, 'Origin Trait Super Long Label');

      // Equal Expanded; no horizontal scroll.
      final grid = find.byKey(const Key('catalog_perk_grid'));
      final row = tester.widget<Row>(grid);
      expect(row.children.whereType<Expanded>().length, 5);
      final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
      for (final s in scrollables) {
        expect(
          s.axisDirection == AxisDirection.left ||
              s.axisDirection == AxisDirection.right,
          isFalse,
        );
      }
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

    testWidgets('soft catalyst omitted when empty; present display-only',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ExoticIdentityBlock(
            intrinsicName: 'Memento Mori',
            intrinsicDescription: 'Kills with primary reload the magazine.',
          ),
        ),
      );
      expect(find.byKey(const Key('exotic_identity_block')), findsOneWidget);
      expect(find.byKey(const Key('exotic_catalyst_name')), findsNothing);
      expect(find.byKey(const Key('exotic_catalyst_display_only')), findsNothing);
      expect(find.text('CATALYST'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const ExoticIdentityBlock(
            catalystName: 'Ace of Spades Catalyst',
            catalystComplete: true,
          ),
        ),
      );
      expect(find.byKey(const Key('exotic_catalyst_name')), findsOneWidget);
      expect(find.byKey(const Key('exotic_catalyst_display_only')), findsOneWidget);
      expect(find.byKey(const Key('exotic_catalyst_status')), findsOneWidget);
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

    testWidgets('chip size == 22×22; strip not full-width bars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 80,
              child: CatalogWeaponMetaStrip(
                itemTypeName: 'Pulse Rifle',
                frame: 'Lightweight Frame',
                element: 'Kinetic',
                slot: 'Kinetic',
                ammo: 'Primary',
                owned: true,
                ownedCount: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final chipKeys = [
        const Key('catalog_meta_type'),
        const Key('catalog_meta_frame'),
        const Key('catalog_meta_element'),
        const Key('catalog_meta_slot'),
        const Key('catalog_meta_ammo'),
      ];
      final rects = <Rect>[];
      for (final key in chipKeys) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, kCatalogMetaChipSize,
            reason: '$key width must be fixed 22');
        expect(size.height, kCatalogMetaChipSize,
            reason: '$key height must be fixed 22');
        // Not full-width bars under 400 parent.
        expect(size.width, lessThan(100));
        rects.add(tester.getRect(find.byKey(key)));
      }

      // Compact horizontal strip: chips share a row and advance left→right.
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].left, greaterThan(rects[i - 1].right - 0.5),
            reason: 'chips must lay out horizontally, not stacked full-width');
        expect((rects[i].top - rects[0].top).abs(), lessThan(1.0));
      }
      // Total chip band width is well under the 400 pane (not bar geometry).
      final band = rects.last.right - rects.first.left;
      expect(band, lessThan(200));
    });

    testWidgets('mapped type → silhouette; unmapped → letter + Semantics',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              CatalogWeaponMetaStrip(
                key: Key('mapped'),
                itemTypeName: 'Pulse Rifle',
              ),
              CatalogWeaponMetaStrip(
                key: Key('unmapped'),
                itemTypeName: 'Mystery Weapon Type',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(officialWeaponTypeVisual('Pulse Rifle'), isNotNull);
      expect(officialWeaponTypeVisual('Mystery Weapon Type'), isNull);

      // Mapped uses DestinyWeaponTypeIcon path.
      expect(
        find.descendant(
          of: find.byKey(const Key('mapped')),
          matching: find.byType(DestinyWeaponTypeIcon),
        ),
        findsOneWidget,
      );

      // Unmapped letter mark.
      expect(
        find.descendant(
          of: find.byKey(const Key('unmapped')),
          matching: find.text(weaponTypeLetterMark('Mystery Weapon Type')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('unmapped')),
          matching: find.byType(DestinyWeaponTypeIcon),
        ),
        findsNothing,
      );
    });

    testWidgets('×N only when owned+count; showOwnedMark false omits chrome',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              CatalogWeaponMetaStrip(
                key: Key('owned_on'),
                itemTypeName: 'Sword',
                owned: true,
                ownedCount: 4,
                showOwnedMark: true,
              ),
              CatalogWeaponMetaStrip(
                key: Key('signed_out'),
                itemTypeName: 'Sword',
                owned: true,
                ownedCount: 4,
                showOwnedMark: false,
              ),
              CatalogWeaponMetaStrip(
                key: Key('zero_count'),
                itemTypeName: 'Sword',
                owned: true,
                ownedCount: 0,
                showOwnedMark: true,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('owned_on')),
          matching: find.byKey(const Key('catalog_meta_owned_count')),
        ),
        findsOneWidget,
      );
      expect(find.text('×4'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('signed_out')),
          matching: find.byKey(const Key('catalog_meta_owned_count')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('zero_count')),
          matching: find.byKey(const Key('catalog_meta_owned_count')),
        ),
        findsNothing,
      );
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
      expect(find.byType(FilterChip), findsNothing);
      expect(
        tester
            .getSemantics(find.byKey(const Key('catalog_toggle_can_roll')))
            .hasFlag(SemanticsFlag.isToggled),
        isFalse,
      );
      expect(find.textContaining('POSSIBLE ROLLS'), findsOneWidget);
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

    testWidgets(
        'unowned enhance note when canBeEnhanced; no E cells; no fake selected',
        (tester) async {
      const item = CatalogItem(
        hash: 50,
        name: 'Hung Jury SR4',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Scout Rifle',
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
                'columnKind': 'trait',
                'columnLabel': 'Trait',
                'equippedPlugHash': 3,
                'reusablePlugHashes': [3, 4],
              },
            ],
            plugNameByHash: const {
              3: 'Rapid Hit',
              4: 'Enhanced Frenzy',
            },
            plugEnhancedByHash: const {4: true},
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('catalog_enhance_note')), findsOneWidget);
      expect(find.textContaining('Can be enhanced'), findsOneWidget);
      // No E marks on pool cells.
      expect(find.byKey(const Key('perk_enhanced_mark_3')), findsNothing);
      expect(find.byKey(const Key('perk_enhanced_mark_4')), findsNothing);
      // No fake selected roll.
      expect(find.byKey(const Key('perk_selected_3')), findsNothing);
      expect(find.byKey(const Key('perk_selected_4')), findsNothing);
    });

    testWidgets('detail enhanced: gold+E on ①/② only; ③ ON → no E on pool',
        (tester) async {
      const item = CatalogItem(
        hash: 99,
        name: 'Chattering Bone',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Pulse Rifle',
        isExotic: false,
        owned: true,
        ownedCount: 1,
      );
      final instances = [
        _inst(
          id: 'a',
          power: 550,
          socketPlugs: const [
            {
              'columnKind': 'trait',
              'columnLabel': 'Trait',
              'equippedPlugHash': 20,
              'reusablePlugHashes': [20, 21],
            },
          ],
        ),
      ];

      var canRoll = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogWeaponDetail(
                item: item,
                instances: instances,
                showCanRoll: canRoll,
                showCraft: false,
                craftAvailable: false,
                onCanRollChanged: (v) => setState(() => canRoll = v),
                onCraftChanged: (_) {},
                definitionSocketPlugs: const [
                  {
                    'columnKind': 'trait',
                    'columnLabel': 'Trait',
                    'equippedPlugHash': 20,
                    'reusablePlugHashes': [20, 21, 22],
                  },
                ],
                plugNameByHash: const {
                  20: 'Rapid Hit',
                  21: 'Overflow',
                  22: 'Enhanced Kill Clip',
                },
                plugEnhancedByHash: const {20: true},
              ),
            );
          },
        ),
      );
      await tester.pump();

      // ① enhanced from host map.
      expect(find.byKey(const Key('perk_enhanced_mark_20')), findsOneWidget);
      // ② not enhanced.
      expect(find.byKey(const Key('perk_enhanced_mark_21')), findsNothing);

      await tester.tap(find.byKey(const Key('catalog_toggle_can_roll')));
      await tester.pump();
      // ③ pool cell present without E.
      expect(find.byKey(const Key('perk_cell_22')), findsOneWidget);
      expect(find.byKey(const Key('perk_enhanced_mark_22')), findsNothing);
      expect(find.byKey(const Key('catalog_enhance_note')), findsOneWidget);
      // ① still has E.
      expect(find.byKey(const Key('perk_enhanced_mark_20')), findsOneWidget);
    });
  });
}
