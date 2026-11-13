import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_cache_loader.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

MockBuild _build({
  String id = 'b01',
  String name = 'Test build',
  String subclass = 'Prismatic',
  String exoticArmor = 'Solipsism',
  String exoticWeapon = 'Sunshot',
  List<MockSlotAssignment> slots = const [],
  String? exoticWeaponType = 'Hand Cannon',
  String? exoticWeaponDamageType = 'Solar',
  String? exoticWeaponSlot = 'special',
}) {
  return MockBuild(
    id: id,
    name: name,
    subclass: subclass,
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    slots: slots,
    loop: 'loop',
    artifact: const MockArtifact(name: '—', season: '—'),
    setBonuses: const [],
    stats: const [],
    exoticWeaponType: exoticWeaponType,
    exoticWeaponDamageType: exoticWeaponDamageType,
    exoticWeaponSlot: exoticWeaponSlot,
  );
}

FillInInventoryItem _armor({
  required String id,
  required int hash,
  required String name,
  required EquipmentSlot slot,
  required GuardianClass cls,
  bool exotic = false,
  int? setHash,
}) {
  return FillInInventoryItem(
    instanceId: id,
    itemHash: hash,
    name: name,
    slot: slot,
    isExotic: exotic,
    guardianClass: cls,
    armorSetHash: setHash,
  );
}

FillInInventoryItem _weapon({
  required String id,
  required int hash,
  required String name,
  EquipmentSlot slot = EquipmentSlot.special,
  String? weaponType,
  String? damageType,
  bool exotic = true,
}) {
  return FillInInventoryItem(
    instanceId: id,
    itemHash: hash,
    name: name,
    slot: slot,
    isExotic: exotic,
    guardianClass: null,
    weaponType: weaponType,
    damageType: damageType,
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required MockBuild build,
  required FillInCacheLoader loadCaches,
  FillInClipboardWriter? clipboardWriter,
  FillInMissingListSaver? saveMissingList,
  VoidCallback? onMissingListSaved,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: testMaterialTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              key: const Key('open_fill_in'),
              onPressed: () {
                showFillInDialog(
                  context: context,
                  build: build,
                  loadCaches: loadCaches,
                  clipboardWriter: clipboardWriter,
                  saveMissingList: saveMissingList,
                  onMissingListSaved: onMissingListSaved,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open_fill_in')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('caches missing shows Settings import message', (tester) async {
    await _pumpDialog(
      tester,
      build: _build(),
      loadCaches: () async => FillInCacheLoadResult.missing(
        'DIM Armor inventory cache is missing or unreadable (no cached). '
        'Import it in Settings (DIM Armor CSV), then try Fill In again.',
      ),
    );

    expect(find.byKey(const Key('fill_in_dialog_b01')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_cache_error')), findsOneWidget);
    expect(find.textContaining('Settings'), findsOneWidget);
    expect(find.byKey(const Key('fill_in_copy_missing')), findsNothing);
  });

  testWidgets('all held shows held chips and no copy-missing', (tester) async {
    final build = _build(
      slots: const [
        MockSlotAssignment(
          slot: 'class_item',
          setId: 'exotic',
          pieceName: 'Solipsism',
          isExoticSlot: true,
        ),
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_techsec',
          pieceName: 'Techsec Helmet',
        ),
      ],
    );
    final inventory = [
      _armor(
        id: 'a1',
        hash: 9001,
        name: 'Solipsism',
        slot: EquipmentSlot.classItem,
        cls: GuardianClass.warlock,
        exotic: true,
      ),
      _armor(
        id: 'a2',
        hash: 111001,
        name: 'Techsec Helmet',
        slot: EquipmentSlot.helmet,
        cls: GuardianClass.warlock,
      ),
      _weapon(id: 'w1', hash: 3118677280, name: 'Sunshot'),
    ];

    await _pumpDialog(
      tester,
      build: build,
      loadCaches: () async => FillInCacheLoadResult.ok(inventory),
    );

    expect(find.byKey(const Key('fill_in_chip_class_item_held')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_chip_helmet_held')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_chip_special_held')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_copy_missing')), findsNothing);
    expect(find.byKey(const Key('fill_in_solipsism_flag')), findsNothing);
  });

  testWidgets('some missing lists chips and copy-missing copies clipboard',
      (tester) async {
    final copied = <String>[];
    final build = _build(
      exoticWeapon: 'Sunshot',
      slots: const [
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_techsec',
          pieceName: 'Techsec Helmet',
        ),
        MockSlotAssignment(
          slot: 'arms',
          setId: 'set_techsec',
          pieceName: 'Techsec Gauntlets',
        ),
      ],
      exoticArmor: '',
    );
    final inventory = [
      _armor(
        id: 'a1',
        hash: 111001,
        name: 'Techsec Helmet',
        slot: EquipmentSlot.helmet,
        cls: GuardianClass.warlock,
      ),
    ];

    await _pumpDialog(
      tester,
      build: build,
      loadCaches: () async => FillInCacheLoadResult.ok(inventory),
      clipboardWriter: (text) async => copied.add(text),
    );

    expect(find.byKey(const Key('fill_in_chip_helmet_held')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_chip_arms_missing')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_chip_special_missing')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_copy_missing')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fill_in_copy_missing')));
    await tester.pump();
    expect(copied, hasLength(1));
    expect(copied.single, contains('Gauntlets'));
    expect(copied.single, contains('Exotic weapon'));
  });

  testWidgets('over-cap armor shows over cap chip and label', (tester) async {
    final build = _build(
      exoticArmor: '',
      exoticWeapon: '',
      slots: const [
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_techsec',
          pieceName: 'Techsec Helmet',
        ),
      ],
    );
    final inventory = [
      for (var i = 0; i < 3; i++)
        _armor(
          id: 'h-$i',
          hash: 111001 + i,
          name: 'Techsec Helmet',
          slot: EquipmentSlot.helmet,
          cls: GuardianClass.warlock,
        ),
    ];

    await _pumpDialog(
      tester,
      build: build,
      loadCaches: () async => FillInCacheLoadResult.ok(inventory),
    );

    expect(find.byKey(const Key('fill_in_chip_helmet_over cap')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_over_cap_helmet')), findsOneWidget);
    expect(find.text('More than 2 held'), findsOneWidget);
  });

  testWidgets('Solipsism on non-Prismatic shows flag', (tester) async {
    final build = _build(
      subclass: 'Solar',
      exoticArmor: 'Solipsism',
      exoticWeapon: '',
      slots: const [
        MockSlotAssignment(
          slot: 'class_item',
          setId: 'exotic',
          pieceName: 'Solipsism',
          isExoticSlot: true,
        ),
      ],
    );
    final inventory = [
      _armor(
        id: 'a1',
        hash: 9001,
        name: 'Solipsism',
        slot: EquipmentSlot.classItem,
        cls: GuardianClass.warlock,
        exotic: true,
      ),
    ];

    await _pumpDialog(
      tester,
      build: build,
      loadCaches: () async => FillInCacheLoadResult.ok(inventory),
    );

    expect(find.byKey(const Key('fill_in_solipsism_flag')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_chip_class_item_held')), findsOneWidget);
  });

  testWidgets('Close dismisses the dialog', (tester) async {
    await _pumpDialog(
      tester,
      build: _build(),
      loadCaches: () async => FillInCacheLoadResult.ok(const []),
    );
    expect(find.byKey(const Key('fill_in_dialog_b01')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fill_in_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fill_in_dialog_b01')), findsNothing);
  });

  testWidgets('missing weapon shows Similar suggestion from held CSV',
      (tester) async {
    final build = _build(
      exoticArmor: '',
      exoticWeapon: 'Sunshot',
      slots: const [],
    );
    final inventory = [
      _weapon(
        id: 'alt',
        hash: 55,
        name: "Zaouli's Bane",
        slot: EquipmentSlot.special,
        weaponType: 'Hand Cannon',
        damageType: 'Solar',
        exotic: false,
      ),
    ];

    await _pumpDialog(
      tester,
      build: build,
      loadCaches: () async => FillInCacheLoadResult.ok(inventory),
    );

    expect(find.byKey(const Key('fill_in_chip_special_missing')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_similar_weapon')), findsOneWidget);
    expect(find.textContaining("Zaouli's Bane"), findsOneWidget);
  });

  testWidgets('Save missing list calls saver with missing labels',
      (tester) async {
    FillInSavedBuildPlan? savedPlan;
    var savedCallbacks = 0;

    final build = _build(
      exoticArmor: '',
      exoticWeapon: 'Sunshot',
      slots: const [
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_techsec',
          pieceName: 'Techsec Helmet',
        ),
      ],
    );

    await _pumpDialog(
      tester,
      build: build,
      loadCaches: () async => FillInCacheLoadResult.ok(const []),
      saveMissingList: (plan) async {
        savedPlan = plan;
      },
      onMissingListSaved: () => savedCallbacks += 1,
    );

    expect(find.byKey(const Key('fill_in_save_missing')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fill_in_save_missing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(savedCallbacks, 1);
    expect(find.byKey(const Key('fill_in_save_status')), findsOneWidget);
    expect(savedPlan, isNotNull);
    expect(savedPlan!.buildId, 'b01');
    expect(savedPlan!.missing, contains('Helmet'));
    expect(savedPlan!.missing, contains('Exotic weapon (energy)'));
  });
}
