import 'package:destiny2_windows_host/settings/dim_csv_import_card.dart';
import 'package:destiny2_windows_host/settings/dim_csv_import_controller.dart';
import 'package:destiny2_windows_host/settings/path_file_field.dart';
import 'package:destiny2_windows_host/settings/warlock_matrix_path_card.dart';
import 'package:destiny2_windows_host/settings/warlock_matrix_path_controller.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Records the last filter args and returns a canned path (or null to cancel).
class _FakePicker {
  _FakePicker(this.result);

  final String? result;
  List<String>? lastExtensions;
  String? lastLabel;
  int calls = 0;

  Future<String?> call({
    required List<String> extensions,
    String? label,
  }) async {
    calls += 1;
    lastExtensions = List<String>.from(extensions);
    lastLabel = label;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathFileField', () {
    testWidgets('pick fills the field; cancel leaves it unchanged',
        (tester) async {
      final controller = TextEditingController(text: r'C:\keep\me.csv');
      final pick = _FakePicker(r'D:\picked\armor.csv');
      final cancel = _FakePicker(null);
      var changed = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: PathFileField(
              fieldKey: const Key('path_field'),
              browseKey: const Key('path_browse'),
              controller: controller,
              labelText: 'Source',
              typeLabel: 'CSV',
              extensions: const <String>['csv'],
              openFilePicker: pick.call,
              onChanged: changed.add,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('path_browse')));
      await _pumpFrames(tester);

      expect(pick.calls, 1);
      expect(pick.lastExtensions, <String>['csv']);
      expect(controller.text, r'D:\picked\armor.csv');
      expect(changed, <String>[r'D:\picked\armor.csv']);

      // Cancel must not clear the picked path.
      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: PathFileField(
              fieldKey: const Key('path_field'),
              browseKey: const Key('path_browse'),
              controller: controller,
              labelText: 'Source',
              typeLabel: 'CSV',
              extensions: const <String>['csv'],
              openFilePicker: cancel.call,
              onChanged: changed.add,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('path_browse')));
      await _pumpFrames(tester);

      expect(cancel.calls, 1);
      expect(controller.text, r'D:\picked\armor.csv');
      expect(changed, <String>[r'D:\picked\armor.csv']);
    });

    testWidgets('typing a path still works without opening the picker',
        (tester) async {
      final controller = TextEditingController();
      final pick = _FakePicker(r'D:\should-not-appear.csv');
      var last = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: PathFileField(
              fieldKey: const Key('path_field'),
              browseKey: const Key('path_browse'),
              controller: controller,
              labelText: 'Source',
              extensions: const <String>['csv'],
              openFilePicker: pick.call,
              onChanged: (v) => last = v,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(
        find.byKey(const Key('path_field')),
        r'D:\typed\path.csv',
      );
      await _pumpFrames(tester);

      expect(pick.calls, 0);
      expect(controller.text, r'D:\typed\path.csv');
      expect(last, r'D:\typed\path.csv');
    });
  });

  group('DIM CSV import card picker', () {
    testWidgets('armor browse uses .csv filter and does not auto-import',
        (tester) async {
      var importCalls = 0;
      final pick = _FakePicker(r'D:\exports\armor.csv');
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.armor,
        cachePath: r'C:\app\fill_in\dim_armor_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached'),
        importFromPath: (_) async {
          importCalls += 1;
          return (count: 1, error: null);
        },
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(
                controller: controller,
                openFilePicker: pick.call,
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('dim_armor_csv_import_browse')));
      await _pumpFrames(tester);

      expect(pick.calls, 1);
      expect(pick.lastExtensions, <String>['csv']);
      expect(
        find.text(r'D:\exports\armor.csv'),
        findsOneWidget,
      );
      expect(controller.sourcePath, r'D:\exports\armor.csv');
      expect(importCalls, 0);
      expect(find.text('not imported yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dim_armor_csv_import_import')));
      await _pumpFrames(tester);
      expect(importCalls, 1);
      expect(find.text('Imported 1 items'), findsOneWidget);
    });

    testWidgets('weapons browse uses .csv; cancel leaves field unchanged',
        (tester) async {
      final pick = _FakePicker(null);
      final controller = DimCsvImportController.forTest(
        kind: DimCsvImportKind.weapons,
        cachePath: r'C:\app\fill_in\dim_weapons_inventory.csv',
        loadCache: () async => (count: null, error: 'no cached'),
        importFromPath: (_) async => (count: null, error: 'unused'),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DimCsvImportCard(
                controller: controller,
                openFilePicker: pick.call,
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(
        find.byKey(const Key('dim_weapons_csv_import_source_field')),
        r'D:\keep\weapons.csv',
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('dim_weapons_csv_import_browse')));
      await _pumpFrames(tester);

      expect(pick.calls, 1);
      expect(pick.lastExtensions, <String>['csv']);
      expect(controller.sourcePath, r'D:\keep\weapons.csv');
      expect(find.text(r'D:\keep\weapons.csv'), findsOneWidget);
    });
  });

  group('Warlock matrix path card picker', () {
    testWidgets('browse uses .json filter and does not auto-save',
        (tester) async {
      final pick = _FakePicker(r'D:\matrix\warlock.json');
      final setting = _MemorySetting();
      final controller = WarlockMatrixPathController(
        storageRoot: StorageRoot(basePath: '/tmp/warlock-picker-fake'),
        environment: const {},
        setting: setting,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: WarlockMatrixPathCard(
                controller: controller,
                openFilePicker: pick.call,
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('warlock_matrix_path_browse')));
      await _pumpFrames(tester);

      expect(pick.calls, 1);
      expect(pick.lastExtensions, <String>['json']);
      expect(controller.pathField, r'D:\matrix\warlock.json');
      expect(await setting.load(), isNull);
      expect(find.text('No path set'), findsOneWidget);
    });
  });
}

class _MemorySetting implements WarlockMatrixPathSettingStore {
  String? _value;

  @override
  String get settingPath => 'memory://warlock_matrix_path.txt';

  @override
  Future<String?> load() async => _value;

  @override
  Future<void> save(String path) async {
    final trimmed = path.trim();
    _value = trimmed.isEmpty ? null : trimmed;
  }
}
