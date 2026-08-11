import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:destiny2_windows_host/sets/sets_armor_capture_fixtures.dart';
import 'package:destiny2_windows_host/sets/sets_lifecycle_controller.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildFlapTheme(),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Capture surface keys + fixtures', () {
    test('must shot ids + surface keys documented', () {
      expect(kSetsArmorMustShotIds, contains('desktop-library-armor'));
      expect(kSetsArmorMustShotIds, contains('desktop-optimize-confirm'));
      expect(kSetsArmorCaptureSurfaceKeys, contains('sets_armor_board'));
      expect(kSetsArmorCaptureSurfaceKeys, contains('sets_fill_owned_compare'));
      // No Catalog embed key in Capture contract.
      expect(
        kSetsArmorCaptureSurfaceKeys,
        isNot(contains('catalog_weapons_workspace')),
      );
      // 002 create wizard must-shot ids registered.
      expect(
        kSetsCreateWizardMustShotIds,
        contains('desktop-create-step-type'),
      );
      expect(
        kSetsCreateWizardMustShotIds,
        contains('desktop-create-post-board'),
      );
      expect(
        kSetsCreateWizardCaptureSurfaceKeys,
        contains('sets_create_step_dots'),
      );
      expect(
        kSetsCreateWizardCaptureSurfaceKeys,
        contains('sets_create_continue'),
      );
    });
  });

  group('library → stepped create → empty board', () {
    testWidgets('Type→Class→Bonus→Name Create opens empty board layout A',
        (tester) async {
      final life = SetsLifecycleController();
      var phase = 'library';
      final nameCtrl = TextEditingController();

      await tester.pumpWidget(
        _wrap(
          ListenableBuilder(
            listenable: life,
            builder: (context, _) {
              if (phase == 'create') {
                return SetsLifecycleModal(
                  title: life.createCrumb,
                  onClose: () {
                    phase = 'library';
                    life.close();
                  },
                  footer: SetsCreateWizardFooter(
                    step: life.createStep,
                    isFinalStep: life.isCreateFinalStep,
                    canContinue: life.canContinueCreate,
                    onBack: life.createStep == 0 ? null : life.backCreate,
                    onCancel: () {
                      phase = 'library';
                      life.close();
                    },
                    onContinue: life.isCreateFinalStep
                        ? null
                        : () {
                            if (life.canContinueCreate) life.continueCreate();
                          },
                    onCreate: life.isCreateFinalStep
                        ? () {
                            phase = 'board';
                            life.openBoard('new-armor');
                          }
                        : null,
                  ),
                  child: SetsCreateWizard(
                    step: life.createStep,
                    setType: life.createType.wireName,
                    guardianClass: life.createClass?.wireName,
                    availableFamilies: const ['TechSec'],
                    namePreview: life.namePreview,
                    nameController: nameCtrl,
                    onTypeChanged: (t) {
                      life.setCreateType(SetType.tryParse(t) ?? SetType.armor);
                    },
                    onClassChanged: (c) {
                      life.setCreateClass(GuardianClass.tryParse(c));
                    },
                    onGoalsChanged: (g) {
                      life.setCreateGoals([
                        for (final goal in g)
                          SetBonusCoverageGoal(
                            setBonusKey: goal.familyKey,
                            minPieces: goal.minPieces,
                          ),
                      ]);
                    },
                    onNameChanged: life.setCreateName,
                    isLegalCombo: (goals) => isLegalSetBonusGoalCombo([
                      for (final g in goals)
                        SetBonusCoverageGoal(
                          setBonusKey: g.familyKey,
                          minPieces: g.minPieces,
                        ),
                    ]),
                  ),
                );
              }
              if (phase == 'board') {
                return SetsLifecycleModal(
                  title: 'Armor board',
                  onClose: () {
                    phase = 'library';
                    life.close();
                  },
                  child: SingleChildScrollView(
                    child: SetsArmorBoard(
                      slots: fixtureEmptyBoardSlots(),
                      onOptimize: () {},
                      onPickSlot: (_) {},
                    ),
                  ),
                );
              }
              return SetsLibraryWorkspace(
                rows: fixtureLibraryArmorRows(),
                onNewSet: () {
                  life.openCreate();
                  phase = 'create';
                },
                onSelectRow: (_) {},
                detail: Column(
                  children: [
                    const SetsModSetDeepLink(linkedModSetId: 'mod-1'),
                    TextButton(
                      key: const Key('sets_open_board'),
                      onPressed: () {
                        phase = 'board';
                        life.openBoard('armor-raid');
                      },
                      child: const Text('Open board'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // desktop-library-armor
      expect(find.byKey(const Key('sets_library_workspace')), findsOneWidget);
      expect(find.byKey(const Key('sets_armor_row_armor-raid')), findsOneWidget);
      expect(find.byKey(const Key('sets_mod_set_deep_link')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_library_new')));
      await tester.pumpAndSettle();

      // Step 0 Type
      expect(find.byKey(const Key('sets_lifecycle_modal')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_wizard')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_step_dots')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_type')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_class')), findsNothing);
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_continue')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_create_continue')));
      await tester.pumpAndSettle();

      // Step 1 Class
      expect(find.byKey(const Key('sets_create_class')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_back')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsOneWidget);
      // Continue gated until class
      var cont = tester.widget<FilledButton>(
        find.byKey(const Key('sets_create_continue')),
      );
      expect(cont.onPressed, isNull);

      await tester.tap(find.byKey(const Key('sets_create_class_Titan')));
      await tester.pumpAndSettle();
      cont = tester.widget<FilledButton>(
        find.byKey(const Key('sets_create_continue')),
      );
      expect(cont.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('sets_create_continue')));
      await tester.pumpAndSettle();

      // Step 2 Bonus
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_name')), findsNothing);
      await tester.tap(find.byKey(const Key('sets_create_continue')));
      await tester.pumpAndSettle();

      // Step 3 Name + Create
      expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_continue')), findsNothing);
      await tester.tap(find.byKey(const Key('sets_create_button')));
      await tester.pumpAndSettle();

      // desktop-create-post-board / empty board layout A
      expect(find.byKey(const Key('sets_armor_board')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_primary')), findsOneWidget);
      expect(find.text('Σ 0'), findsOneWidget);
      for (final w in kArmorBoardSlotWires) {
        expect(find.byKey(Key('sets_board_pick_$w')), findsOneWidget);
      }
    });

    testWidgets('non-Armor thin shell skips Class/Bonus and board',
        (tester) async {
      final life = SetsLifecycleController();
      var phase = 'library';
      var created = false;

      await tester.pumpWidget(
        _wrap(
          ListenableBuilder(
            listenable: life,
            builder: (context, _) {
              if (phase == 'create') {
                return SetsLifecycleModal(
                  title: life.createCrumb,
                  onClose: () => phase = 'library',
                  footer: SetsCreateWizardFooter(
                    step: life.createStep,
                    isFinalStep: life.isCreateFinalStep,
                    canContinue: life.canContinueCreate,
                    onBack: life.createStep == 0 ? null : life.backCreate,
                    onCancel: () => phase = 'library',
                    onContinue: life.isCreateFinalStep
                        ? null
                        : life.continueCreate,
                    onCreate: life.isCreateFinalStep
                        ? () {
                            created = true;
                            phase = 'library';
                            life.close();
                          }
                        : null,
                    createLabel: 'Create shell',
                  ),
                  child: SetsCreateWizard(
                    step: life.createStep,
                    setType: life.createType.wireName,
                    onTypeChanged: (t) {
                      life.setCreateType(SetType.tryParse(t) ?? SetType.weapon);
                    },
                  ),
                );
              }
              return SetsLibraryWorkspace(
                rows: const [],
                onNewSet: () {
                  life.openCreate();
                  phase = 'create';
                },
                onSelectRow: (_) {},
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('sets_library_new')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sets_create_type_weapon')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sets_create_continue')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sets_create_thin_shell_hint')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_class')), findsNothing);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_create_button')));
      await tester.pumpAndSettle();
      expect(created, isTrue);
      expect(find.byKey(const Key('sets_armor_board')), findsNothing);
    });
  });

  group('host-fixture shots', () {
    testWidgets('desktop-signed-out-honesty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SetsHonestyEmpty(
            kind: SetsHonestyKind.signedOut,
            message: 'Sign in to manage owned armor sets',
          ),
        ),
      );
      expect(find.byKey(const Key('sets_honesty_signedOut')), findsOneWidget);
    });

    testWidgets('desktop-filled-board-coverage', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: SetsArmorBoard(
              slots: fixtureFilledBoardSlots(),
              coverage: fixtureCoverageBand(),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_board_totals_row')), findsOneWidget);
      expect(find.byKey(const Key('sets_coverage_hard_TechSec_2')), findsOneWidget);
      expect(find.byKey(const Key('sets_coverage_soft_2pc_TechSec')), findsOneWidget);
    });

    testWidgets('desktop-owned-compare', (tester) async {
      final rows = fixtureOwnedCompareRows();
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: SetsOwnedCompareTable(
              rows: [
                for (final r in rankOwnedArmorCompare(rows))
                  SetsOwnedCompareRowData(
                    instanceId: r.instanceId,
                    itemHash: r.itemHash,
                    itemName: r.itemName,
                    isExotic: r.isExotic,
                    total: r.totalStats,
                    power: r.power,
                    bonusFit: r.bonusFit,
                  ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_fill_owned_compare')), findsOneWidget);
      expect(find.byKey(const Key('sets_owned_instance_own-1')), findsOneWidget);
      expect(find.byKey(const Key('catalog_weapons_workspace')), findsNothing);
    });

    testWidgets('desktop-optimize-confirm', (tester) async {
      var applied = false;
      await tester.pumpWidget(
        _wrap(
          SetsOptimizeConfirmShell(
            kits: fixtureOptimizeKits(),
            selectedKitId: 'kit-a',
            hasPins: true,
            classLabel: 'Titan',
            exoticLabel: 'current',
            bonusGoalsLabel: 'TechSec 2pc',
            onConfirmApply: () => applied = true,
          ),
        ),
      );
      expect(find.byKey(const Key('sets_optimize_kit_matrix')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_replace_all_warning')), findsOneWidget);
      expect(applied, isFalse);
      await tester.tap(find.byKey(const Key('sets_optimize_confirm_apply')));
      await tester.pump();
      expect(applied, isTrue);
    });

    testWidgets('desktop-delete-set-in-use', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsDeleteConfirm(
            setName: 'Raid Titan',
            usedBy: const [
              SetsUsedByData(
                buildId: 'b1',
                variantId: 'default',
                buildName: 'Main',
              ),
            ],
            onCancel: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('sets_delete_set_in_use')), findsOneWidget);
      expect(find.byKey(const Key('sets_delete_confirm')), findsNothing);
    });

    testWidgets('desktop-create-step-type fixture chrome', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SetsLifecycleModal(
            title: 'New set · type',
            footer: SetsCreateWizardFooter(
              step: 0,
              isFinalStep: false,
              canContinue: true,
              onContinue: () {},
              onCancel: () {},
            ),
            child: const SetsCreateWizard(
              setType: 'armor',
              step: 0,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('sets_create_step_dots')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_type')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_continue')), findsOneWidget);
      expect(find.byKey(const Key('sets_bonus_goals_editor')), findsNothing);
      expect(find.byKey(const Key('sets_create_name')), findsNothing);
    });
  });
}
