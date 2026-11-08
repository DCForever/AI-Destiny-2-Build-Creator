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

List<SetsArmorSlotData> _filledSlots({bool withIconsAndInfo = false}) {
  return [
    for (var i = 0; i < kArmorBoardSlotWires.length; i++)
      SetsArmorSlotData(
        slotWire: kArmorBoardSlotWires[i],
        slotLabel: kArmorBoardSlotLabels[i],
        itemName: 'Piece $i',
        instanceId: 'inst-$i',
        itemHash: withIconsAndInfo ? 1000 + i : null,
        iconPath: withIconsAndInfo ? '/common/destiny2_content/icons/x.png' : null,
        isExotic: i == 0,
        setBonusKey: i < 4 ? 'TechSec' : null,
        stats: {
          for (final l in kArmorBoardEofStatLabels) l: 10 + i,
        },
        entityInfo: withIconsAndInfo
            ? EntityInfoData(
                id: 'armor_${1000 + i}',
                name: 'Piece $i',
                kind: i == 0 ? 'Exotic armor' : 'Armor',
                iconPath: '/common/destiny2_content/icons/x.png',
                description: 'Catalog body for piece $i',
                hashFooter: '#${1000 + i}',
              )
            : null,
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

  group('Create wizard step machine', () {
    testWidgets('Armor step 0 Type only; Continue disabled until type',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: '',
            step: 0,
            showEmbeddedFooter: true,
            canContinue: false,
            availableFamilies: const ['TechSec'],
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_wizard')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dots')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_type')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_class')), findsNothing);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_create_name')), findsNothing);
      expect(find.byKey(const Key('sets_create_button')), findsNothing);
      expect(find.byKey(const Key('sets_create_continue')), findsOneWidget);
      final cont = tester.widget<FilledButton>(
        find.byKey(const Key('sets_create_continue')),
      );
      expect(cont.onPressed, isNull);
      expect(find.byKey(const Key('sets_create_back')), findsNothing);
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsOneWidget);
    });

    testWidgets('Armor step 1 Class only; Continue until class; Back works',
        (tester) async {
      var step = 1;
      String? className;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return SetsCreateWizard(
                setType: 'armor',
                step: step,
                guardianClass: className,
                showEmbeddedFooter: true,
                canContinue: className != null,
                onClassChanged: (c) => setState(() => className = c),
                onBack: () => setState(() => step = 0),
                onContinue: () => setState(() => step = 2),
                availableFamilies: const ['TechSec'],
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_class')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_type')), findsNothing);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_create_back')), findsOneWidget);
      var cont = tester.widget<FilledButton>(
        find.byKey(const Key('sets_create_continue')),
      );
      expect(cont.onPressed, isNull);

      await tester.tap(find.byKey(const Key('sets_create_class_Titan')));
      await tester.pump();
      cont = tester.widget<FilledButton>(
        find.byKey(const Key('sets_create_continue')),
      );
      expect(cont.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('sets_create_back')));
      await tester.pump();
      expect(step, 0);
      expect(find.byKey(const Key('sets_create_type')), findsOneWidget);
    });

    testWidgets('Armor step 2 Bonus optional; Continue always; illegal blocked',
        (tester) async {
      var goals = <SetsBonusGoalData>[];
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return SetsCreateWizard(
                setType: 'armor',
                step: 2,
                guardianClass: 'Titan',
                goals: goals,
                availableFamilies: const ['A', 'B'],
                showEmbeddedFooter: true,
                canContinue: true,
                onContinue: () {},
                isLegalCombo: _legalGoals,
                onGoalsChanged: (next) => setState(() => goals = next),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_name')), findsNothing);
      expect(find.byKey(const Key('sets_create_type')), findsNothing);
      final cont = tester.widget<FilledButton>(
        find.byKey(const Key('sets_create_continue')),
      );
      expect(cont.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('sets_bonus_goal_2pc_A')));
      await tester.pump();
      expect(goals, hasLength(1));
    });

    testWidgets('Armor step 3 Name + auto-name preview; Create only final',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: 'armor',
            step: 3,
            guardianClass: 'Titan',
            namePreview: 'Titan · — · —',
            showEmbeddedFooter: true,
            onCreate: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_name_preview')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_continue')), findsNothing);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_create_class')), findsNothing);
    });

    testWidgets('Non-Armor skips Class/Bonus; thin shell create', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: 'weapon',
            step: 1,
            showEmbeddedFooter: true,
            onCreate: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_thin_shell_hint')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_class')), findsNothing);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dot_0')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dot_1')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dot_2')), findsNothing);
    });

    testWidgets('pieces/compare never shown during any create step',
        (tester) async {
      for (final step in [0, 1, 2, 3]) {
        await tester.pumpWidget(
          _wrap(
            SetsCreateWizard(
              setType: 'armor',
              step: step,
              guardianClass: step >= 1 ? 'Titan' : null,
              availableFamilies: const ['TechSec'],
              namePreview: 'Titan · — · —',
            ),
          ),
        );
        expect(find.byKey(const Key('sets_create_pieces_hidden')), findsOneWidget);
        expect(find.byKey(const Key('sets_owned_compare_table')), findsNothing);
        expect(find.byKey(const Key('sets_armor_board')), findsNothing);
        expect(find.byKey(const Key('catalog_weapons_workspace')), findsNothing);
      }
    });

    testWidgets('step dots + crumb reflect active step', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsCreateWizard(
            setType: 'armor',
            step: 2,
            guardianClass: 'Hunter',
            availableFamilies: ['TechSec'],
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_crumb')), findsOneWidget);
      expect(find.text('New set · bonus'), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dots')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dot_3')), findsOneWidget);
    });

    testWidgets('footer Back hidden on step 0; Create only final',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: 'armor',
            step: 0,
            showEmbeddedFooter: true,
            canContinue: true,
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_back')), findsNothing);
      expect(find.byKey(const Key('sets_create_cancel')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_continue')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_button')), findsNothing);

      await tester.pumpWidget(
        _wrap(
          SetsCreateWizard(
            setType: 'armor',
            step: 3,
            guardianClass: 'Titan',
            showEmbeddedFooter: true,
            onCreate: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_back')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_continue')), findsNothing);
    });

    testWidgets('tags hard-block on Name step (G-SET-033)', (tester) async {
      var tags = <SetsTagData>[];
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return SetsCreateWizard(
                setType: 'armor',
                step: 3,
                guardianClass: 'Titan',
                tags: tags,
                isTagBlocked: (label) {
                  final t = label.toLowerCase();
                  return t == 'verb' || t == 'melee' || t == 'element';
                },
                onTagsChanged: (next) => setState(() => tags = next),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_tags')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('sets_tag_input')), 'verb');
      await tester.tap(find.byKey(const Key('sets_tag_add')));
      await tester.pump();
      expect(find.byKey(const Key('sets_tag_blocked_message')), findsOneWidget);
      expect(tags.map((t) => t.label), isNot(contains('verb')));
    });

    testWidgets('Choice chips only for active type or class step',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsCreateWizard(setType: 'armor', step: 0),
        ),
      );
      expect(find.byKey(const Key('sets_create_type_armor')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_class_Titan')), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const SetsCreateWizard(
            setType: 'armor',
            step: 1,
            guardianClass: null,
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_type_armor')), findsNothing);
      expect(find.byKey(const Key('sets_create_class_Titan')), findsOneWidget);
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

    testWidgets('search matches perk description text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsBonusGoalsEditor(
            goals: const [],
            families: const [
              SetsBonusFamilyOption(
                name: 'Bushido',
                twoPcDescription: 'Increases melee damage after a kill.',
              ),
              SetsBonusFamilyOption(
                name: 'AION Adapter',
                twoPcDescription: 'Grenade energy on orb pickup.',
              ),
            ],
          ),
        ),
      );
      expect(find.text('Bushido'), findsOneWidget);
      expect(find.text('AION Adapter'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('sets_bonus_goals_search')),
        'melee damage',
      );
      await tester.pump();
      expect(find.text('Bushido'), findsOneWidget);
      expect(find.text('AION Adapter'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('sets_bonus_goals_search')),
        'grenade energy',
      );
      await tester.pump();
      expect(find.text('AION Adapter'), findsOneWidget);
      expect(find.text('Bushido'), findsNothing);
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
          SizedBox(
            width: 1100,
            height: 800,
            child: SetsOptimizeConfirmShell(
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
                  rank: 1,
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
        ),
      );
      expect(find.byKey(const Key('sets_optimize_confirm_shell')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_kit_matrix')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_replace_all_warning')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_seed_class')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_seed_exotic')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_sort')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_exotic')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_th_total')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_stat_min_Health')), findsOneWidget);
      // BUG-20260812-001 / 004: stat labels stay one token (no mid-word wrap).
      for (final label in ['GRENADE', 'WEAPONS', 'HEALTH']) {
        final texts = tester.widgetList<Text>(find.text(label));
        expect(texts, isNotEmpty, reason: label);
        for (final t in texts) {
          expect(t.softWrap, isFalse, reason: label);
          expect(t.maxLines, 1, reason: label);
        }
      }
      expect(find.byType(Tooltip), findsWidgets);
      expect(applied, isFalse);
      await tester.tap(find.byKey(const Key('sets_optimize_confirm_apply')));
      await tester.pump();
      expect(applied, isTrue);
    });

    testWidgets('re-optimize control present when onReoptimize set', (tester) async {
      var reruns = 0;
      String? lastExotic;
      Map<String, int>? lastMins;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 800,
            child: SetsOptimizeConfirmShell(
              hasPins: false,
              kits: const [
                SetsOptimizeKitRowData(id: 'k', total: 100, rank: 1),
              ],
              selectedKitId: 'k',
              initialExoticFilter: 'none',
              onReoptimize: ({
                required exoticFilter,
                required statMin,
                required statMax,
              }) {
                reruns++;
                lastExotic = exoticFilter;
                lastMins = statMin;
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_rerun')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sets_optimize_rerun')));
      await tester.pump();
      expect(reruns, 1);
      // Must not clear the user's exotic choice.
      expect(lastExotic, 'none');
      expect(lastMins, isEmpty);
    });

    testWidgets('empty label names mins when 50 kits all fail floors',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 800,
            child: SetsOptimizeConfirmShell(
              hasPins: false,
              engineKitCount: 2,
              kits: const [
                SetsOptimizeKitRowData(
                  id: 'a',
                  total: 200,
                  rank: 1,
                  exoticName: 'Chromatic Fire',
                  exoticItemHash: 42,
                  stats: {
                    'Health': 40,
                    'Melee': 50,
                    'Grenade': 40,
                    'Super': 30,
                    'Class': 20,
                    'Weapons': 20,
                  },
                ),
                SetsOptimizeKitRowData(
                  id: 'b',
                  total: 190,
                  rank: 2,
                  exoticName: 'Chromatic Fire',
                  exoticItemHash: 42,
                  stats: {
                    'Health': 40,
                    'Melee': 45,
                    'Grenade': 35,
                    'Super': 30,
                    'Class': 20,
                    'Weapons': 20,
                  },
                ),
              ],
              exoticOptions: const [
                SetsOptimizeExoticOption(id: 'any', label: 'Any'),
                SetsOptimizeExoticOption(id: '42', label: 'Chromatic Fire'),
              ],
              initialExoticFilter: '42',
            ),
          ),
        ),
      );
      // Raise mins via dual-range would be heavy; inject by pump after state —
      // use filter helper unit style via public empty path with high mins set
      // through onConstraints isn't available. Assert breakdown helper instead.
      final b = breakdownOptimizeFilters(
        kits: const [
          SetsOptimizeKitRowData(
            id: 'a',
            total: 200,
            exoticItemHash: 42,
            exoticName: 'Chromatic Fire',
            stats: {'Melee': 50, 'Grenade': 40},
          ),
        ],
        exoticFilter: '42',
        statMin: const {'Melee': 82, 'Grenade': 71},
        exoticFilterLabel: 'Chromatic Fire',
      );
      expect(b.engineCount, 1);
      expect(b.afterAll, 0);
      expect(b.failedStatMin, 1);
      final msg = describeOptimizeFilterEmpty(b: b);
      expect(msg, contains('0 of 1'));
      expect(msg, contains('Melee≥82'));
      expect(msg, contains('Grenade≥71'));
    });

    testWidgets('bonus goals Change opens editor and applies', (tester) async {
      List<SetsBonusGoalData>? applied;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 800,
            child: SetsOptimizeConfirmShell(
              hasPins: false,
              kits: const [
                SetsOptimizeKitRowData(id: 'k', total: 100, rank: 1),
              ],
              selectedKitId: 'k',
              initialBonusGoals: const [
                SetsBonusGoalData(familyKey: 'CODA', minPieces: 4),
              ],
              bonusFamilies: const [
                SetsBonusFamilyOption(
                  name: 'CODA',
                  twoPcName: '2pc',
                  twoPcDescription: 'Two piece body',
                  fourPcName: '4pc',
                  fourPcDescription: 'Four piece body',
                ),
                SetsBonusFamilyOption(
                  name: 'TechSec',
                  twoPcName: 'T2',
                  twoPcDescription: 'Tech 2',
                  fourPcName: 'T4',
                  fourPcDescription: 'Tech 4',
                ),
              ],
              isLegalBonusCombo: _legalGoals,
              onBonusGoalsChanged: (g) => applied = g,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_bonus_change')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_bonus_open')), findsOneWidget);
      expect(find.textContaining('CODA 4pc'), findsWidgets);

      await tester.tap(find.byKey(const Key('sets_optimize_bonus_open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sets_optimize_bonus_dialog_title')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_bonus_editor')), findsOneWidget);

      // Switch to TechSec 2pc (legal single goal).
      await tester.tap(find.byKey(const Key('sets_bonus_goal_2pc_TechSec')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sets_optimize_bonus_apply')));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      expect(applied, hasLength(1));
      expect(applied!.first.familyKey, 'TechSec');
      expect(applied!.first.minPieces, 2);
    });

    testWidgets('no replace-all warning when zero pins', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 800,
            child: SetsOptimizeConfirmShell(
              hasPins: false,
              kits: const [
                SetsOptimizeKitRowData(id: 'k', total: 100, rank: 1),
              ],
              selectedKitId: 'k',
              onConfirmApply: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_replace_all_warning')), findsNothing);
    });

    testWidgets('dual-range min thumb can raise floor (G-SET-036)', (tester) async {
      var minV = 0;
      var maxV = kSetsOptimizeStatSliderMax;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 360,
                  child: SetsOptimizeDualRange(
                    statLabel: 'Health',
                    minValue: minV,
                    maxValue: maxV,
                    onChanged: (a, b) => setState(() {
                      minV = a;
                      maxV = b;
                    }),
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_stat_readout_Health')), findsOneWidget);
      expect(find.text('any'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
      final health = tester.widget<Text>(find.text('HEALTH'));
      expect(health.softWrap, isFalse);
      expect(health.maxLines, 1);

      // Drag start thumb from left end toward mid track (must not be stolen by max).
      final box = tester.getRect(find.byType(RangeSlider));
      await tester.timedDragFrom(
        Offset(box.left + 6, box.center.dy),
        Offset(box.width * 0.55, 0),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();

      expect(minV, greaterThan(0));
      expect(maxV, equals(kSetsOptimizeStatSliderMax));
      final readout = tester
          .widget<Text>(find.byKey(const Key('sets_optimize_stat_readout_Health')));
      expect(readout.data, startsWith('≥'));
    });

    test('filterSortOptimizeKits honors Health min floor', () {
      final kits = filterSortOptimizeKits(
        kits: const [
          SetsOptimizeKitRowData(
            id: 'low',
            total: 100,
            stats: {'Health': 20},
          ),
          SetsOptimizeKitRowData(
            id: 'high',
            total: 200,
            stats: {'Health': 80},
          ),
        ],
        statMin: const {'Health': 50},
      );
      expect(kits.map((k) => k.id), ['high']);
    });

    testWidgets('constraints collapse when kit matrix scrolls down', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 700,
            child: SetsOptimizeConfirmShell(
              hasPins: false,
              kits: [
                for (var i = 0; i < 20; i++)
                  SetsOptimizeKitRowData(
                    id: 'k$i',
                    total: 200 - i,
                    rank: i + 1,
                    stats: const {'Health': 40},
                    slotNames: const {
                      'helmet': 'H',
                      'arms': 'A',
                      'chest': 'C',
                      'legs': 'L',
                      'class_item': 'CI',
                    },
                  ),
              ],
              selectedKitId: 'k0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sets_optimize_constraints')), findsOneWidget);
      expect(
        find.byKey(const Key('sets_optimize_constraints_collapsed')),
        findsNothing,
      );

      // Scroll the kit matrix; constraints should collapse to summary bar.
      final matrix = find.byKey(const Key('sets_optimize_kit_matrix'));
      expect(matrix, findsOneWidget);
      await tester.drag(matrix, const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('sets_optimize_constraints_collapsed')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sets_optimize_constraints')), findsNothing);

      // Tap collapsed bar to expand constraints again.
      await tester.tap(find.byKey(const Key('sets_optimize_constraints_collapsed')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sets_optimize_constraints')), findsOneWidget);
    });

    testWidgets('current board row stays pinned while proposals scroll', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 700,
            child: SetsOptimizeConfirmShell(
              hasPins: true,
              currentBoard: const SetsOptimizeKitRowData(
                id: 'current',
                total: 300,
                isCurrent: true,
                label: 'Current board',
                stats: {'Health': 50},
                slotNames: {
                  'helmet': 'CurH',
                  'arms': 'CurA',
                  'chest': 'CurC',
                  'legs': 'CurL',
                  'class_item': 'CurCI',
                },
              ),
              kits: [
                for (var i = 0; i < 25; i++)
                  SetsOptimizeKitRowData(
                    id: 'k$i',
                    total: 400 - i,
                    rank: i + 1,
                    stats: const {'Health': 60},
                    slotNames: const {
                      'helmet': 'H',
                      'arms': 'A',
                      'chest': 'C',
                      'legs': 'L',
                      'class_item': 'CI',
                    },
                  ),
              ],
              selectedKitId: 'k0',
              initialIncludeCurrent: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sets_optimize_kit_current')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_current_pin_rule')), findsOneWidget);
      expect(find.text('CurH'), findsOneWidget);

      // Scroll proposals; current row must remain.
      await tester.drag(
        find.byKey(const Key('sets_optimize_kit_matrix')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sets_optimize_kit_current')), findsOneWidget);
      expect(find.text('CurH'), findsOneWidget);
    });

    testWidgets('header, current, and kits share one horizontal scroll',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 640,
            height: 700,
            child: SetsOptimizeConfirmShell(
              hasPins: true,
              currentBoard: const SetsOptimizeKitRowData(
                id: 'current',
                total: 300,
                isCurrent: true,
                label: 'Current board',
                stats: {'Health': 50},
                slotNames: {
                  'helmet': 'CurH',
                  'arms': 'CurA',
                  'chest': 'CurC',
                  'legs': 'CurL',
                  'class_item': 'CurCI',
                },
              ),
              kits: [
                for (var i = 0; i < 8; i++)
                  SetsOptimizeKitRowData(
                    id: 'k$i',
                    total: 400 - i,
                    rank: i + 1,
                    stats: const {'Health': 60},
                    slotNames: const {
                      'helmet': 'H',
                      'arms': 'A',
                      'chest': 'C',
                      'legs': 'L',
                      'class_item': 'CI',
                    },
                  ),
              ],
              selectedKitId: 'k0',
              initialIncludeCurrent: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double dx(Finder f) => tester.getTopLeft(f).dx;
      final hash = find.text('#');
      final cur = find.byKey(const ValueKey('sets_optimize_kit_current'));
      final rank = find.text('#1');
      expect(hash, findsOneWidget);
      expect(cur, findsOneWidget);
      expect(rank, findsOneWidget);

      final hash0 = dx(hash);
      final cur0 = dx(cur);
      final rank0 = dx(rank);
      expect(cur0, closeTo(hash0, 2));
      expect(rank0, closeTo(hash0, 2));

      await tester.drag(
        find.byKey(const Key('sets_optimize_kit_matrix_hscroll')),
        const Offset(-280, 0),
      );
      await tester.pumpAndSettle();

      final hash1 = dx(hash);
      final cur1 = dx(cur);
      final rank1 = dx(rank);
      expect(hash0 - hash1, greaterThan(50));
      expect(cur1, closeTo(hash1, 2));
      expect(rank1, closeTo(hash1, 2));
    });

    testWidgets('table header sort; no seed chips; min column highlight',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 1100,
            height: 800,
            child: SetsOptimizeConfirmShell(
              hasPins: true,
              currentBoard: const SetsOptimizeKitRowData(
                id: 'current',
                total: 100,
                isCurrent: true,
              ),
              initialIncludeCurrent: true,
              initialStatMin: const {'Melee': 82},
              kits: const [
                SetsOptimizeKitRowData(
                  id: 'low',
                  total: 180,
                  rank: 2,
                  stats: {'Health': 40, 'Melee': 90},
                ),
                SetsOptimizeKitRowData(
                  id: 'high',
                  total: 160,
                  rank: 1,
                  stats: {'Health': 80, 'Melee': 95},
                ),
              ],
              selectedKitId: 'low',
              onSelectKit: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sets_optimize_seed_class')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_sort')), findsNothing);
      expect(find.byKey(const Key('sets_optimize_th_Health')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_col_highlight_Melee')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_stat_highlight_Melee')), findsOneWidget);
      expect(find.textContaining('≥82'), findsWidgets);
      expect(find.byKey(const Key('sets_optimize_include_current')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_optimize_th_Health')));
      await tester.pumpAndSettle();
      expect(find.textContaining('HEALTH ▼'), findsWidgets);
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
      expect(find.text('inst-0'), findsNothing);
      expect(find.text('inst-1'), findsNothing);
      expect(
        find.byKey(const Key('sets_board_slot_instance_helmet')),
        findsNothing,
      );
      expect(find.byKey(const Key('sets_coverage_hard_TechSec_2')), findsOneWidget);
      expect(find.byKey(const Key('sets_coverage_soft_2pc_TechSec')), findsOneWidget);
      // No energy/mods labels when fields null.
      expect(find.byKey(const Key('sets_board_energy_helmet')), findsNothing);
      expect(find.byKey(const Key('sets_board_mods_helmet')), findsNothing);
    });

    testWidgets('filled slots show icons + EntityInfoHotspot; goals too',
        (tester) async {
      final goalInfo = EntityInfoData(
        id: 'set_bonus_tech_2pc',
        name: 'TechSec · 2pc',
        kind: 'Armor set bonus',
        description: 'Reload speed after ability kills.',
      );
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: SetsArmorBoard(
              slots: _filledSlots(withIconsAndInfo: true),
              coverage: SetsCoverageBandData(
                hardGoals: [
                  SetsBonusGoalData(
                    familyKey: 'TechSec',
                    minPieces: 2,
                    entityInfo: goalInfo,
                  ),
                ],
                hardMet: true,
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const Key('sets_board_slot_icon_helmet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('sets_board_slot_info_helmet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('sets_board_slot_name_info_helmet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('sets_coverage_hard_TechSec_2_info')),
        findsOneWidget,
      );
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
      final classHeader = tester.widget<Text>(find.text('CLASS'));
      expect(classHeader.softWrap, isFalse);
      expect(classHeader.maxLines, 1);
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
