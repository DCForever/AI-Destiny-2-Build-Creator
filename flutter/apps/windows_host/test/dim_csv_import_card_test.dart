import 'package:destiny2_windows_host/settings/dim_csv_import_card.dart';
import 'package:destiny2_windows_host/settings/dim_csv_import_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DIM Armor CSV import card', () {
    testWidgets('initial load shows not imported yet', (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.armor,
        cachePath: r'C:\app\fill_in\dim_armor_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached inventory yet'),
        importFromPath: (_) async => (count: null, error: 'unused'),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const Key('dim_armor_csv_import_card')), findsOneWidget);
      expect(
        find.byKey(const Key('dim_armor_csv_import_source_field')),
        findsOneWidget,
      );
      expect(find.text('not imported yet'), findsOneWidget);
      expect(
        find.textContaining(r'fill_in\dim_armor_inventory.csv'),
        findsOneWidget,
      );
    });

    testWidgets('initial load shows cached count when cache exists',
        (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.armor,
        cachePath: r'C:\app\fill_in\dim_armor_inventory.csv',
        loadCache: () async => (count: 7, error: null),
        importFromPath: (_) async => (count: null, error: 'unused'),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text('Cached: 7 items'), findsOneWidget);
    });

    testWidgets('import success shows item count', (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.armor,
        cachePath: r'C:\app\fill_in\dim_armor_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached'),
        importFromPath: (path) async {
          expect(path, r'D:\exports\armor.csv');
          return (count: 4, error: null);
        },
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(
        find.byKey(const Key('dim_armor_csv_import_source_field')),
        r'D:\exports\armor.csv',
      );
      await tester.tap(find.byKey(const Key('dim_armor_csv_import_import')));
      await _pumpFrames(tester);

      expect(find.text('Imported 4 items'), findsOneWidget);
    });

    testWidgets('import error shows message', (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.armor,
        cachePath: r'C:\app\fill_in\dim_armor_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached'),
        importFromPath: (_) async => (
          count: null,
          error: "Couldn't read file: missing required column",
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(
        find.byKey(const Key('dim_armor_csv_import_source_field')),
        r'D:\exports\bad.csv',
      );
      await tester.tap(find.byKey(const Key('dim_armor_csv_import_import')));
      await _pumpFrames(tester);

      expect(find.textContaining("Couldn't read file"), findsOneWidget);
    });
  });

  group('DIM Weapons CSV import card', () {
    testWidgets('initial load shows not imported yet', (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.weapons,
        cachePath: r'C:\app\fill_in\dim_weapons_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached inventory yet'),
        importFromPath: (_) async => (count: null, error: 'unused'),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(
        find.byKey(const Key('dim_weapons_csv_import_card')),
        findsOneWidget,
      );
      expect(find.text('not imported yet'), findsOneWidget);
    });

    testWidgets('import success shows item count', (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.weapons,
        cachePath: r'C:\app\fill_in\dim_weapons_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached'),
        importFromPath: (_) async => (count: 2, error: null),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(
        find.byKey(const Key('dim_weapons_csv_import_source_field')),
        r'D:\exports\weapons.csv',
      );
      await tester.tap(find.byKey(const Key('dim_weapons_csv_import_import')));
      await _pumpFrames(tester);

      expect(find.text('Imported 2 items'), findsOneWidget);
    });

    testWidgets('import error shows message', (tester) async {
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.weapons,
        cachePath: r'C:\app\fill_in\dim_weapons_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached'),
        importFromPath: (_) async => (
          count: null,
          error: "Couldn't read file: empty Id",
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(controller: controller),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(
        find.byKey(const Key('dim_weapons_csv_import_source_field')),
        r'D:\exports\bad.csv',
      );
      await tester.tap(find.byKey(const Key('dim_weapons_csv_import_import')));
      await _pumpFrames(tester);

      expect(find.textContaining("Couldn't read file"), findsOneWidget);
    });
  });
}
