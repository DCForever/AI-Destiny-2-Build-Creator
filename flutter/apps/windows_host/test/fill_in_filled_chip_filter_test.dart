import 'package:destiny2_windows_host/builds_mock/builds_mock_derived_name.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_loadout_card.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'detail card no longer shows Filled in · item chips (tables cover status)',
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

    // Chip row removed — Armor/Weapons tables already show fill status.
    expect(find.textContaining('Filled in ·'), findsNothing);
    expect(
      find.byKey(const Key('builds_mock_filled_in_chip_filter_primary')),
      findsNothing,
    );
  });
}
