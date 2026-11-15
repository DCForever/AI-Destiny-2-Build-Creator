import 'package:destiny2_windows_host/builds_mock/builds_mock_gear_tables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('groupStackedLabels preserves first-seen order and counts', () {
    expect(
      groupStackedLabels(const [
        'Kinetic Siphon',
        'Kinetic Siphon',
        'Ashes to Assets',
      ]),
      [
        (name: 'Kinetic Siphon', count: 2),
        (name: 'Ashes to Assets', count: 1),
      ],
    );
    expect(stackedChipLabel('Kinetic Siphon', 2), 'Kinetic Siphon ×2');
    expect(stackedChipLabel('Ashes to Assets', 1), 'Ashes to Assets');
  });

  testWidgets(
    'armor row with duplicate mods renders without exception and stacks ×N',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: BuildsMockArmorTable(
              showMods: true,
              rows: const [
                BuildsMockArmorRow(
                  slotLabel: 'Helmet',
                  itemName: 'The Chosen Key',
                  setName: 'Broodweaver',
                  statTotal: 68,
                  isExotic: false,
                  status: BuildsMockSlotStatus.held,
                  mods: [
                    'Kinetic Siphon',
                    'Kinetic Siphon',
                    'Ashes to Assets',
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Kinetic Siphon ×2'), findsOneWidget);
      expect(find.text('Ashes to Assets'), findsOneWidget);
      expect(find.text('Kinetic Siphon'), findsNothing);
      expect(
        find.byKey(const Key('builds_mock_armor_mod_Kinetic Siphon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_armor_mod_Ashes to Assets')),
        findsOneWidget,
      );
    },
  );
}
