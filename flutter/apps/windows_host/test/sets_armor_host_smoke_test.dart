import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sets_armor_capture_fixtures.dart';

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
      expect(kSetsArmorCaptureSurfaceKeys, isNot(contains('catalog_weapons_workspace')));
    });
  });

  group('library → modal create → board', () {
    testWidgets('dual-pane library + create lock + empty board', (tester) async {
      var phase = 'library';
      SetType type = SetType.armor;
      String? className;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              if (phase == 'create') {
                return SetsLifecycleModal(
                  title: 'Create Armor Set',
                  onClose: () => setState(() => phase = 'library'),
                  child: SetsCreateWizard(
                    setType: type.wireName,
                    guardianClass: className,
                    availableFamilies: const ['TechSec'],
                    namePreview: className == null
                        ? ''
                        : resolveArmorSetName(
                            guardianClass: GuardianClass.tryParse(className!) ??
                                GuardianClass.titan,
                          ),
                    onTypeChanged: (t) => setState(() {
                      type = SetType.tryParse(t) ?? SetType.armor;
                    }),
                    onClassChanged: (c) => setState(() => className = c),
                    onCreate: () => setState(() => phase = 'board'),
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
                  onClose: () => setState(() => phase = 'library'),
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
                onNewSet: () => setState(() => phase = 'create'),
                onSelectRow: (_) {},
                detail: Column(
                  children: [
                    const SetsModSetDeepLink(linkedModSetId: 'mod-1'),
                    TextButton(
                      key: const Key('sets_open_board'),
                      onPressed: () => setState(() => phase = 'board'),
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

      // desktop-create-type-class
      expect(find.byKey(const Key('sets_lifecycle_modal')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_wizard')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_create_class_Titan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sets_create_pieces_hidden')), findsNothing);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('sets_create_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sets_create_button')));
      await tester.pumpAndSettle();

      // desktop-empty-board
      expect(find.byKey(const Key('sets_armor_board')), findsOneWidget);
      expect(find.byKey(const Key('sets_optimize_primary')), findsOneWidget);
      expect(find.text('Σ 0'), findsOneWidget);
      for (final w in kArmorBoardSlotWires) {
        expect(find.byKey(Key('sets_board_pick_$w')), findsOneWidget);
      }
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
  });
}
