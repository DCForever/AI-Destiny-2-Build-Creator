import 'package:destiny2_windows_host/builds_mock/builds_mock_derived_name.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_loadout_card.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('filled slots never surface blank item names on the detail card',
      (tester) async {
    const build = MockBuild(
      id: 'chip_filter',
      name: 'Chip filter',
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: 'Barrow-Dyad',
      slots: [
        MockSlotAssignment(
          slot: 'primary',
          setId: 'exotic_weapon',
          pieceName: 'Qua Nilus II',
          isExoticSlot: true,
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'special',
          setId: 'weapon',
          pieceName: '   ',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'heavy',
          setId: 'weapon',
          pieceName: '',
          filledIn: true,
        ),
      ],
      loop: 'loop',
      artifact: MockArtifact(name: '—', season: '—'),
      setBonuses: [],
      stats: [],
    );
    final derived = deriveBuildsMockName(build: build);

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: BuildsMockLoadoutCard(
            loadout: build,
            derivedName: derived,
            density: BuildsMockCardDensity.detail,
          ),
        ),
      ),
    );

    expect(find.text('Qua Nilus II'), findsWidgets);
    expect(find.text('Filled in'), findsWidgets);
    // Blank / whitespace piece names must never appear as a titled chip.
    expect(find.textContaining('Filled in ·'), findsNothing);
    expect(find.text('None'), findsNothing);
  });
}
