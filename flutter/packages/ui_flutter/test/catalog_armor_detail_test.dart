import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(body: SizedBox(width: 400, height: 900, child: child)),
  );
}

const _item = CatalogItem(
  hash: 9001,
  name: 'Cuirass of the Falling Star',
  slot: 'Chest',
  classType: 'Titan',
  isExotic: true,
  owned: true,
  ownedCount: 2,
);

const _unowned = CatalogItem(
  hash: 9002,
  name: 'Generic Plate',
  slot: 'Chest',
  classType: 'Hunter',
  isExotic: false,
  owned: false,
  ownedCount: 0,
);

ArmorStatBoardData _board(Map<String, int> stats) {
  final total = stats.values.fold<int>(0, (a, b) => a + b);
  return ArmorStatBoardData(stats: stats, total: total);
}

ArmorInstanceStripItem _copy({
  required String id,
  required int power,
  required Map<String, int> base,
  Map<String, int>? live,
  bool liveUnavailable = false,
  List<ArmorModPlugData> mods = const [],
  ArmorEnergyData? energy,
}) {
  final baseBoard = _board(base);
  return ArmorInstanceStripItem(
    instanceId: id,
    power: power,
    baseTotal: baseBoard.total,
    baseBoard: baseBoard,
    liveBoard: live == null ? null : _board(live),
    liveUnavailable: liveUnavailable || live == null,
    mods: mods,
    energy: energy,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArmorBaseLiveStatBoard', () {
    testWidgets('simultaneous Base|Live labels when both present',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArmorBaseLiveStatBoard(
            baseBoard: _board(const {
              'Health': 20,
              'Melee': 30,
              'Grenade': 10,
              'Super': 15,
              'Class': 12,
              'Weapons': 8,
            }),
            liveBoard: _board(const {
              'Health': 40,
              'Melee': 50,
              'Grenade': 20,
              'Super': 25,
              'Class': 22,
              'Weapons': 18,
            }),
            ownedCopy: true,
          ),
        ),
      );

      expect(find.byKey(const Key('armor_base_live_stat_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_stat_label_base')), findsOneWidget);
      expect(find.byKey(const Key('armor_stat_label_live')), findsOneWidget);
      expect(find.byKey(const Key('armor_base_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_live_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_stat_base_health')), findsOneWidget);
      expect(find.byKey(const Key('armor_stat_live_health')), findsOneWidget);
    });

    testWidgets('base-only board', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ArmorBaseLiveStatBoard(
            baseBoard: _board(const {
              'Health': 20,
              'Melee': 10,
              'Grenade': 10,
              'Super': 10,
              'Class': 10,
              'Weapons': 10,
            }),
            ownedCopy: true,
            liveUnavailable: true,
          ),
        ),
      );
      expect(find.byKey(const Key('armor_base_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_live_board')), findsNothing);
      expect(find.byKey(const Key('armor_live_unavailable')), findsOneWidget);
    });

    testWidgets('unknown unowned', (tester) async {
      await tester.pumpWidget(
        _wrap(const ArmorBaseLiveStatBoard(ownedCopy: false)),
      );
      expect(find.byKey(const Key('armor_stats_unknown')), findsOneWidget);
      expect(find.text('Stats unknown'), findsOneWidget);
    });

    testWidgets('live-null copy says unavailable for this copy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ArmorBaseLiveStatBoard(
            ownedCopy: true,
            liveUnavailable: true,
          ),
        ),
      );
      expect(find.byKey(const Key('armor_live_unavailable')), findsOneWidget);
      expect(find.textContaining('unavailable for this copy'), findsWidgets);
      expect(find.textContaining('unpinned'), findsNothing);
    });
  });

  group('ArmorInstanceStrip', () {
    testWidgets('base-total sort; select rebinds Base+Live boards',
        (tester) async {
      final copies = [
        _copy(
          id: 'low',
          power: 2000,
          base: const {
            'Health': 10,
            'Melee': 10,
            'Grenade': 10,
            'Super': 10,
            'Class': 10,
            'Weapons': 10,
          },
          live: const {
            'Health': 15,
            'Melee': 15,
            'Grenade': 15,
            'Super': 15,
            'Class': 15,
            'Weapons': 15,
          },
        ),
        _copy(
          id: 'high',
          power: 1800,
          base: const {
            'Health': 30,
            'Melee': 30,
            'Grenade': 20,
            'Super': 20,
            'Class': 20,
            'Weapons': 20,
          },
          live: const {
            'Health': 50,
            'Melee': 50,
            'Grenade': 30,
            'Super': 30,
            'Class': 30,
            'Weapons': 30,
          },
        ),
      ];
      String? selectedId = 'low';
      ArmorInstanceStripItem? selected = copies.first;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              Column(
                children: [
                  ArmorInstanceStrip(
                    instances: copies,
                    selectedInstanceId: selectedId,
                    onSelect: (c) {
                      setState(() {
                        selectedId = c.instanceId;
                        selected = c;
                      });
                    },
                  ),
                  ArmorBaseLiveStatBoard(
                    baseBoard: selected?.baseBoard,
                    liveBoard: selected?.liveBoard,
                    ownedCopy: true,
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Sorted base total desc: high (140) before low (60).
      final ordered = ArmorInstanceStrip.sortByBaseTotal(copies);
      expect(ordered.first.instanceId, 'high');
      expect(ordered.last.instanceId, 'low');

      // Initial selection low → base health 10.
      expect(find.byKey(const Key('armor_stat_base_health')), findsOneWidget);
      expect(find.text('10'), findsWidgets);

      await tester.tap(find.byKey(const Key('armor_instance_high')));
      await tester.pump();
      expect(selectedId, 'high');
      expect(selected?.baseBoard?.stats['Health'], 30);
      expect(selected?.liveBoard?.stats['Health'], 50);
    });
  });

  group('ArmorModsEnergyBlock', () {
    testWidgets('visible with plugs; hidden when none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              ArmorModsEnergyBlock(
                mods: const [
                  ArmorModPlugData(
                    hash: 1,
                    displayName: 'Heavy Handed',
                    energyCost: 3,
                  ),
                ],
                energy: const ArmorEnergyData(used: 3, capacity: 10),
              ),
              const ArmorModsEnergyBlock(),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('armor_mods_energy_block')), findsOneWidget);
      expect(find.byKey(const Key('armor_mod_1')), findsOneWidget);
      expect(find.byKey(const Key('armor_energy_bar')), findsOneWidget);
      expect(find.byKey(const Key('armor_mods_energy_hidden')), findsOneWidget);
      // No empty-note clutter.
      expect(find.textContaining('No mods'), findsNothing);
    });
  });

  group('set-bonus + exotic', () {
    testWidgets('set-bonus 2pc/4pc or explicit none (no meters)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const ArmorSetBonusCallout(
                data: ArmorSetBonusData(
                  setName: 'Techsec',
                  twoPiece: 'Reload speed',
                  fourPiece: 'Orbs on final blow',
                ),
              ),
              const ArmorSetBonusCallout(
                data: ArmorSetBonusData(explicitNone: true),
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('armor_set_bonus_callout')), findsOneWidget);
      expect(find.byKey(const Key('armor_set_bonus_2pc')), findsOneWidget);
      expect(find.byKey(const Key('armor_set_bonus_4pc')), findsOneWidget);
      expect(find.byKey(const Key('armor_set_bonus_none')), findsOneWidget);
      expect(find.text('No set bonus'), findsOneWidget);
      // No vault progress meters.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('exotic callout; class-item omitted without data',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              const ArmorExoticPerkCallout(
                data: ArmorExoticPerkData(
                  name: 'Impact Conversion',
                  description: 'Supers gain damage.',
                ),
              ),
              const ArmorExoticPerkCallout(),
            ],
          ),
        ),
      );
      expect(find.byKey(const Key('armor_exotic_perk_callout')), findsOneWidget);
      expect(find.byKey(const Key('armor_exotic_perk_name')), findsOneWidget);
      expect(find.byKey(const Key('armor_exotic_callout_omitted')), findsOneWidget);
    });
  });

  group('CatalogArmorDetail', () {
    testWidgets('unowned omits live/mods/energy; stubs disabled; soft error',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              Expanded(
                child: CatalogArmorDetail(
                  item: _unowned,
                  setBonus: const ArmorSetBonusData(
                    setName: 'Field-Tested',
                    twoPiece: '2pc effect',
                  ),
                ),
              ),
              CatalogSoftErrorBanner(
                message: 'Soft load warning',
                onDismiss: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('catalog_armor_detail_9002')), findsOneWidget);
      expect(find.byKey(const Key('armor_instance_strip')), findsNothing);
      expect(find.byKey(const Key('armor_live_board')), findsNothing);
      expect(find.byKey(const Key('armor_mods_energy_block')), findsNothing);
      expect(find.byKey(const Key('armor_set_bonus_callout')), findsOneWidget);
      expect(find.byKey(const Key('catalog_outbound_stubs')), findsOneWidget);
      expect(find.byKey(const Key('catalog_stub_set')), findsOneWidget);
      final setBtn = tester.widget<FilledButton>(
        find.byKey(const Key('catalog_stub_set')),
      );
      expect(setBtn.onPressed, isNull);
      expect(find.byKey(const Key('catalog_soft_error_banner')), findsOneWidget);
    });

    testWidgets('owned multi-copy detail rebinds boards', (tester) async {
      final copies = [
        _copy(
          id: 'a',
          power: 2000,
          base: const {
            'Health': 10,
            'Melee': 10,
            'Grenade': 10,
            'Super': 10,
            'Class': 10,
            'Weapons': 10,
          },
          live: const {
            'Health': 20,
            'Melee': 20,
            'Grenade': 20,
            'Super': 20,
            'Class': 20,
            'Weapons': 20,
          },
          mods: const [
            ArmorModPlugData(hash: 55, displayName: 'Powerful Friends'),
          ],
          energy: const ArmorEnergyData(used: 4, capacity: 10),
        ),
        _copy(
          id: 'b',
          power: 1990,
          base: const {
            'Health': 40,
            'Melee': 30,
            'Grenade': 20,
            'Super': 20,
            'Class': 20,
            'Weapons': 20,
          },
          live: const {
            'Health': 60,
            'Melee': 40,
            'Grenade': 30,
            'Super': 30,
            'Class': 30,
            'Weapons': 30,
          },
        ),
      ];
      String? selId = 'a';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogArmorDetail(
                item: _item,
                instances: copies,
                selectedInstanceId: selId,
                onSelectInstance: (c) => setState(() => selId = c.instanceId),
                exoticPerk: const ArmorExoticPerkData(
                  name: 'Impact Conversion',
                ),
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('armor_instance_strip')), findsOneWidget);
      expect(find.byKey(const Key('armor_base_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_live_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_mods_energy_block')), findsOneWidget);
      expect(find.byKey(const Key('armor_exotic_perk_callout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('armor_instance_b')));
      await tester.pump();
      expect(selId, 'b');
    });

    testWidgets('workspace armor detail ~400 beside main', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: Scaffold(
            body: CatalogWeaponsWorkspace(
              main: CatalogArmorGrid(
                items: const [_item, _unowned],
                showOwned: true,
              ),
              detail: CatalogArmorDetail(
                item: _item,
                instances: [
                  _copy(
                    id: 'x',
                    power: 2000,
                    base: const {
                      'Health': 20,
                      'Melee': 20,
                      'Grenade': 20,
                      'Super': 20,
                      'Class': 20,
                      'Weapons': 20,
                    },
                    live: const {
                      'Health': 30,
                      'Melee': 30,
                      'Grenade': 30,
                      'Super': 30,
                      'Class': 30,
                      'Weapons': 30,
                    },
                  ),
                ],
                selectedInstanceId: 'x',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('catalog_weapons_workspace')), findsOneWidget);
      expect(find.byKey(const Key('catalog_detail_pane')), findsOneWidget);
      final detail = tester.getSize(find.byKey(const Key('catalog_detail_pane')));
      expect(detail.width, 400);
    });
  });
}
