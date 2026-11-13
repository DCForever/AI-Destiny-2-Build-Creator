import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_saved_plan_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'saved Fill In card shows Armor/Weapons under titled section',
    (tester) async {
      const plan = FillInSavedBuildPlan(
        buildId: 'b01',
        missing: <String>['Energy'],
        rows: <FillInSavedSlotRow>[
          FillInSavedSlotRow(
            slotWire: 'helmet',
            slotLabel: 'Helmet',
            state: 'held',
            itemName: 'AION Renewal Hood',
          ),
          FillInSavedSlotRow(
            slotWire: 'primary',
            slotLabel: 'Kinetic',
            state: 'held',
            itemName: 'Barrow-Dyad',
          ),
          FillInSavedSlotRow(
            slotWire: 'special',
            slotLabel: 'Energy',
            state: 'missing',
            itemName: '',
          ),
        ],
        updatedAt: '2026-11-13T18:00:00.000Z',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: const Scaffold(
            body: Column(
              children: [
                Text('buttons'),
                FillInSavedPlanCard(plan: plan),
                Text('DIM link details', key: Key('dim_placeholder')),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('fill_in_saved_plan_b01')), findsOneWidget);
      expect(find.byKey(const Key('fill_in_saved_title')), findsOneWidget);
      expect(find.textContaining('Saved Fill In · saved'), findsOneWidget);
      expect(
        find.byKey(const Key('fill_in_saved_section_armor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fill_in_saved_section_weapons')),
        findsOneWidget,
      );
      expect(find.textContaining('Barrow-Dyad · Held'), findsOneWidget);
      expect(find.textContaining('Energy · Missing'), findsOneWidget);
      // No blank name entries.
      expect(find.textContaining('·  ·'), findsNothing);

      final savedY =
          tester.getTopLeft(find.byKey(const Key('fill_in_saved_plan_b01'))).dy;
      final dimY =
          tester.getTopLeft(find.byKey(const Key('dim_placeholder'))).dy;
      expect(savedY, lessThan(dimY));
    },
  );

  test('title formats local date time from updatedAt', () {
    const plan = FillInSavedBuildPlan(
      buildId: 'b01',
      missing: <String>[],
      updatedAt: '2026-11-13T18:00:00.000Z',
    );
    expect(fillInSavedPlanTitle(plan), contains('Saved Fill In · saved'));
  });

  testWidgets('legacy flat plan drops blank applied labels in display',
      (tester) async {
    const plan = FillInSavedBuildPlan(
      buildId: 'legacy',
      missing: <String>['Helmet', 'Energy'],
      similarWeaponName: 'Qua Nilus II',
      similarForName: 'Barrow-Dyad',
      applied: <FillInAppliedSlot>[
        FillInAppliedSlot(
          slotWire: 'helmet',
          label: 'AION Renewal Hood',
          originalLabel: '',
        ),
        FillInAppliedSlot(
          slotWire: 'arms',
          label: '',
          originalLabel: '',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: const Scaffold(
          body: FillInSavedPlanCard(plan: plan),
        ),
      ),
    );

    expect(find.byKey(const Key('fill_in_saved_applied')), findsOneWidget);
    final filled = tester
        .widget<Text>(find.byKey(const Key('fill_in_saved_applied')))
        .data!;
    expect(filled, 'Filled in: AION Renewal Hood');
    expect(filled.contains(',,'), isFalse);
  });
}
