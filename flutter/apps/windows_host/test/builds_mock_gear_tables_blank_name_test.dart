import 'package:destiny2_windows_host/builds_mock/builds_mock_derived_name.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_loadout_card.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

/// Replaces removed chip-row coverage: Armor / Weapons tables must never
/// render a blank item name (empty / whitespace → Missing / Not in DIM link).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MockBuild blankNameBuild() {
    return const MockBuild(
      id: 'blank_names',
      name: 'Blank names',
      subclass: 'Void',
      exoticArmor: '',
      exoticWeapon: '',
      slots: [
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_a',
          pieceName: '',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'arms',
          setId: 'set_a',
          pieceName: '   ',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'chest',
          setId: 'set_a',
          pieceName: 'Real Chest',
        ),
        MockSlotAssignment(
          slot: 'primary',
          setId: 'weapon',
          pieceName: '',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'special',
          setId: 'weapon',
          pieceName: '  \t  ',
        ),
        MockSlotAssignment(
          slot: 'heavy',
          setId: 'weapon',
          pieceName: 'Real Heavy',
        ),
      ],
      loop: 'loop',
      artifact: MockArtifact(name: '—', season: '—'),
      setBonuses: [],
      stats: [],
    );
  }

  test('buildsMockArmorRows never emits blank itemName', () {
    final rows = buildsMockArmorRows(build: blankNameBuild());
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row.itemName.trim(), isNotEmpty, reason: row.slotLabel);
    }
    expect(
      rows.singleWhere((r) => r.slotLabel == 'Helmet').itemName,
      'Missing',
    );
    expect(
      rows.singleWhere((r) => r.slotLabel == 'Gauntlets').itemName,
      'Missing',
    );
    expect(
      rows.singleWhere((r) => r.slotLabel == 'Chest').itemName,
      'Real Chest',
    );
  });

  test('buildsMockWeaponRows never emits blank itemName', () {
    final rows = buildsMockWeaponRows(build: blankNameBuild());
    expect(rows, hasLength(3));
    for (final row in rows) {
      expect(row.itemName.trim(), isNotEmpty, reason: row.slotLabel);
    }
    expect(
      rows.singleWhere((r) => r.slotLabel == 'Kinetic').itemName,
      'Not in DIM link',
    );
    expect(
      rows.singleWhere((r) => r.slotLabel == 'Energy').itemName,
      'Not in DIM link',
    );
    expect(
      rows.singleWhere((r) => r.slotLabel == 'Power').itemName,
      'Real Heavy',
    );
  });

  testWidgets(
    'Armor and Weapons tables never show blank item names',
    (tester) async {
      final build = blankNameBuild();
      final derived = deriveBuildsMockName(build: build);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuildsMockLoadoutCard(
                loadout: build,
                derivedName: derived,
                density: BuildsMockCardDensity.detail,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('builds_mock_armor_table')), findsOneWidget);
      expect(find.byKey(const Key('builds_mock_weapon_table')), findsOneWidget);

      // Placeholders, not blank cells.
      expect(find.text('Missing'), findsWidgets);
      expect(find.text('Not in DIM link'), findsWidgets);
      expect(find.text('Real Chest'), findsOneWidget);
      expect(find.text('Real Heavy'), findsOneWidget);

      // Tables render the non-blank presentation names (not empty cells).
      final armorRows = buildsMockArmorRows(build: build);
      final weaponRows = buildsMockWeaponRows(build: build);
      for (final row in armorRows) {
        expect(row.itemName.trim(), isNotEmpty);
        expect(find.text(row.itemName), findsWidgets);
      }
      for (final row in weaponRows) {
        expect(row.itemName.trim(), isNotEmpty);
        expect(find.text(row.itemName), findsWidgets);
      }
    },
  );
}
