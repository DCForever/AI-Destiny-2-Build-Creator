import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(1100, 800)}) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: child,
      ),
    ),
  );
}

List<SetsArmorSlotData> _emptySlots() {
  return [
    for (var i = 0; i < kArmorBoardSlotWires.length; i++)
      SetsArmorSlotData(
        slotWire: kArmorBoardSlotWires[i],
        slotLabel: kArmorBoardSlotLabels[i],
      ),
  ];
}

List<SetsArmorSlotData> _filledSlots() {
  return [
    for (var i = 0; i < kArmorBoardSlotWires.length; i++)
      SetsArmorSlotData(
        slotWire: kArmorBoardSlotWires[i],
        slotLabel: kArmorBoardSlotLabels[i],
        itemName: 'Piece $i',
        instanceId: 'inst-$i',
        isExotic: i == 0,
        setBonusKey: i < 4 ? 'TechSec' : null,
        stats: {
          for (final l in kArmorBoardEofStatLabels) l: 10 + i,
        },
      ),
  ];
}

bool _legalGoals(List<SetsBonusGoalData> goals) {
  if (goals.length > 2) return false;
  if (goals.length == 2) {
    if (goals[0].minPieces != 2 || goals[1].minPieces != 2) return false;
    if (goals[0].familyKey.toLowerCase() == goals[1].familyKey.toLowerCase()) {
      return false;
    }
  }
  for (final g in goals) {
    if (g.minPieces != 2 && g.minPieces != 4) return false;
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Create wizard', () {
    testWidgets('piece/compare UI hidden until Type+Class locked', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: 'armor',
            guardianClass: null,
            availableFamilies: const ['TechSec'],
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_button')), findsNothing);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_owned_compare_table')), findsNothing);

      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: 'armor',
            guardianClass: 'Titan',
            availableFamilies: const ['TechSec'],
            namePreview: 'Titan · — · —',
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsNothing);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsOneWidget);
    });
  });

  group('Bonus goals', () {
    testWidgets('only legal G-SET-013 combos accepted', (tester) async {
      var goals = <SetsBonusGoalData>[];
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return SetsBonusGoalsEditor(
                goals: goals,
                availableFamilies: const ['A', 'B'],
                isLegalCombo: _legalGoals,
                onChanged: (next) => setState(() => goals = next),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('sets_bonus_goal_2pc_A')));
      await tester.pump();
      expect(goals, hasLength(1));
      expect(goals.first.minPieces, 2);

      // Second different 2pc → dual 2×2pc (G-SET-013).
      await tester.tap(find.byKey(const Key('sets_bonus_goal_2pc_B')));
      await tester.pump();
      expect(goals, hasLength(2));

      // Selecting none is legal.
      await tester.tap(find.byKey(const Key('sets_bonus_goal_none')));
      await tester.pump();
      expect(goals, isEmpty);
    });

    testWidgets('family and selected chips expose EntityInfoHotspot', (tester) async {
      final family = SetsBonusFamilyOption(
        name: 'Bushido',
        hash: 42,
        twoPcName: 'Melee loop',
        twoPcDescription: 'Increases melee damage after a kill.',
        fourPcName: 'Combo finish',
        fourPcDescription: 'Finishers grant ability energy.',
      );
      var goals = <SetsBonusGoalData>[
        const SetsBonusGoalData(familyKey: 'Bushido', minPieces: 2),
      ];
      await tester.pumpWidget(
        _wrap(
          SetsBonusGoalsEditor(
            goals: goals,
            families: [family],
          ),
        ),
      );
      expect(find.byKey(const Key('sets_bonus_family_info_Bushido')), findsOneWidget);
      expect(
        find.byKey(const Key('sets_bonus_selected_info_Bushido_2')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sets_bonus_goal_2pc_Bushido')), findsOneWidget);
      // Subtitle shows 2pc description snippet in list.
      expect(find.textContaining('Increases melee damage'), findsOneWidget);
    });
  });

  group('Empty board', () {
    testWidgets('Optimize primary; five Pick; Σ zeros', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: SetsArmorBoard(
              slots: _emptySlots(),
              onOptimize: () {},
              onPickSlot: (_) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_primary')), findsOneWidget);
      for (final w in kArmorBoardSlotWires) {
        expect(find.byKey(Key('sets_board_pick_$w')), findsOneWidget);
      }
      expect(find.byKey(const Key('sets_board_sigma')), findsOneWidget);
      expect(find.text('Σ 0'), findsOneWidget);
    });
  });

  group('Optimize shell', () {
    testWidgets('confirm-only; no silent write; one kit; replace-all if pins',
        (tester) async {
      var applied = false;
      await tester.pumpWidget(
        _wrap(
          SetsOptimizeConfirmShell(
            hasPins: true,
            classLabel: 'Titan',
            exoticLabel: 'Cuirass',
            bonusGoalsLabel: 'TechSec 2pc',
            selectedKitId: 'kit-1',
            kits: const [
              SetsOptimizeKitRowData(
                id: 'kit-1',
                total: 200,
                goalsLabel: 'TechSec 2pc',
                deltaVsCurrent: 12,
                slotNames: {
                  'helmet': 'H',
                  'arms': 'A',
                  'chest': 'C',
                  'legs': 'L',
                  'class_item': 'CI',
                },
              ),
            ],
            onSelectKit: (_) {},
            onConfirmApply: () => applied = true,
            onCancel: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_confirm_shell')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_kit_matrix')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_replace_all_warning')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_seed_class')), findsOneWidget);
      expect(applied, isFalse);
      await tester.tap(find.byKey(const Key('sets_optimize_confirm_apply')));
      await tester.pump();
      expect(applied, isTrue);
    });

    testWidgets('no replace-all warning when zero pins', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsOptimizeConfirmShell(
            hasPins: false,
            kits: const [
              SetsOptimizeKitRowData(id: 'k', total: 100),
            ],
            selectedKitId: 'k',
            onConfirmApply: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_replace_all_warning')), findsNothing);
    });
  });

  group('Owned compare', () {
    testWidgets('owned-only; instance id; exotic-block; no catalog embed',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: SetsOwnedCompareTable(
              rows: const [
                SetsOwnedCompareRowData(
                  instanceId: 'inst-a',
                  itemHash: 1,
                  itemName: 'Helm A',
                  total: 60,
                  power: 2000,
                  bonusFit: true,
                  stats: {'Health': 20, 'Melee': 10},
                ),
                SetsOwnedCompareRowData(
                  instanceId: 'inst-x',
                  itemHash: 2,
                  itemName: 'Exotic Helm',
                  isExotic: true,
                  exoticBlocked: true,
                  total: 70,
                  power: 2000,
                ),
              ],
              onSelect: (_) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_owned_compare_table')), findsOneWidget);
      expect(find.byKey(const Key('sets_fill_owned_compare')), findsOneWidget);
      expect(find.byKey(const Key('sets_owned_instance_inst-a')), findsOneWidget);
      expect(find.byKey(const Key('sets_owned_exotic_block_inst-x')), findsOneWidget);
      // Catalog page embed keys must be absent.
      expect(find.byKey(const Key('catalog_weapons_workspace')), findsNothing);
      expect(find.byKey(const Key('catalog_scope_control')), findsNothing);
    });
  });

  group('Board layout A', () {
    testWidgets('base-roll totals; hard/soft coverage; hide unknown energy/mods',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: SetsArmorBoard(
              slots: _filledSlots(),
              coverage: const SetsCoverageBandData(
                hardGoals: [
                  SetsBonusGoalData(familyKey: 'TechSec', minPieces: 2),
                ],
                hardMet: true,
                softTwoPiece: ['TechSec'],
              ),
              showEnergyMods: true,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_board_totals_row')), findsOneWidget);
      expect(find.byKey(const Key('sets_coverage_hard_TechSec_2')), findsOneWidget);
      expect(find.byKey(const Key('sets_coverage_soft_2pc_TechSec')), findsOneWidget);
      // No energy/mods labels when fields null.
      expect(find.byKey(const Key('sets_board_energy_helmet')), findsNothing);
      expect(find.byKey(const Key('sets_board_mods_helmet')), findsNothing);
    });
  });

  group('Tags', () {
    testWidgets('multi-select; Synergy Type hard-blocked', (tester) async {
      var selected = <SetsTagData>[];
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return SetsTagMultiSelect(
                selected: selected,
                isBlocked: (label) {
                  final t = label.toLowerCase();
                  return t == 'verb' || t == 'melee' || t == 'element';
                },
                onChanged: (next) => setState(() => selected = next),
              );
            },
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('sets_tag_input')), 'raid');
      await tester.tap(find.byKey(const Key('sets_tag_add')));
      await tester.pump();
      expect(selected.map((t) => t.label), contains('raid'));

      await tester.enterText(find.byKey(const Key('sets_tag_input')), 'verb');
      await tester.tap(find.byKey(const Key('sets_tag_add')));
      await tester.pump();
      expect(find.byKey(const Key('sets_tag_blocked_message')), findsOneWidget);
      expect(selected.map((t) => t.label), isNot(contains('verb')));
    });
  });

  group('Save gate', () {
    testWidgets('banner when under-min / incomplete goals', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsSaveGateBanner(
            message: 'Need at least 2 pieces (have 0)',
            canSave: false,
          ),
        ),
      );
      expect(find.byKey(const Key('sets_save_gate_blocked')), findsOneWidget);
    });
  });

  group('Delete', () {
    testWidgets('always confirm; SET_IN_USE + used-by', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsDeleteConfirm(
            setName: 'Raid Titan',
            usedBy: const [
              SetsUsedByData(
                buildId: 'b1',
                variantId: 'v1',
                buildName: 'Main',
              ),
            ],
            onCancel: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_delete_confirm_dialog')), findsOneWidget);
      expect(find.byKey(const Key('sets_delete_set_in_use')), findsOneWidget);
      expect(find.byKey(const Key('sets_delete_used_by_b1_v1')), findsOneWidget);
      expect(find.byKey(const Key('sets_delete_confirm')), findsNothing);
    });
  });

  group('Honesty', () {
    testWidgets('signed-out empty — no fake owned armor', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsHonestyEmpty(
            kind: SetsHonestyKind.signedOut,
            message: 'Sign in to manage owned armor sets',
          ),
        ),
      );
      expect(find.byKey(const Key('sets_honesty_signedOut')), findsOneWidget);
      expect(find.textContaining('fake'), findsNothing);
    });

    testWidgets('need-sync honesty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsHonestyEmpty(
            kind: SetsHonestyKind.needSync,
            message: 'Sync inventory to see owned armor',
            onSync: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_honesty_needSync')), findsOneWidget);
      expect(find.byKey(const Key('sets_honesty_sync')), findsOneWidget);
    });
  });

  group('Non-Armor', () {
    testWidgets('shell list + thin detail only', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsNonArmorThinDetail(
            data: SetsNonArmorThinData(
              id: 'w1',
              name: 'Kinetic trio',
              typeLabel: 'weapon',
              pieceSummary: '2/3 filled',
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_non_armor_thin_detail')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_board')), findsNothing);
    });
  });

  group('Library Armor flap', () {
    testWidgets('Name·class·pieces·coverage·used-by columns', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsLibraryWorkspace(
            rows: const [
              SetsArmorLibraryRowData(
                id: 's1',
                name: 'Raid Titan',
                classLabel: 'Titan',
                pieceCount: 4,
                coverageLabel: 'TechSec 2pc',
                usedByLabel: 'Main',
                selected: true,
              ),
            ],
            onSelectRow: (_) {},
            onNewSet: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_library_workspace')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_library_header')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_row_s1')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_row_class_s1')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_row_pieces_s1')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_row_coverage_s1')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_row_usedby_s1')), findsOneWidget);
    });
  });

  group('Mod Set deep link', () {
    testWidgets('present; fill is not Catalog page embed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsModSetDeepLink(
            linkedModSetId: 'mod-1',
            linkedModSetName: 'Raid mods',
            onOpen: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_mod_set_deep_link')), findsOneWidget);
      expect(find.byKey(const Key('sets_mod_set_open')), findsOneWidget);
      expect(find.byKey(const Key('catalog_weapons_workspace')), findsNothing);
    });
  });

  group('Loading / no-matches', () {
    testWidgets('skeleton + honesty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsLibraryWorkspace(
            rows: [],
            loading: true,
          ),
        ),
      );
      expect(find.byKey(const Key('sets_loading_skeleton')), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          SetsLibraryWorkspace(
            rows: const [],
            honesty: SetsHonestyEmpty(
              kind: SetsHonestyKind.noMatches,
              message: 'No sets match',
              onClearFilters: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_honesty_noMatches')), findsOneWidget);
    });
  });
}
