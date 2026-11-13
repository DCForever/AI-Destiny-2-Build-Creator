import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/settings/warlock_matrix_path_card.dart';
import 'package:destiny2_windows_host/settings/warlock_matrix_path_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<String?> _noopPicker({
  required List<String> extensions,
  String? label,
}) async =>
    null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('card shows path field, Save, and no-path status', (tester) async {
    final controller = WarlockMatrixPathController(
      storageRoot: StorageRoot(basePath: '/tmp/warlock-matrix-card-fake'),
      environment: const {},
      setting: _MemorySetting(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WarlockMatrixPathCard(
              controller: controller,
              openFilePicker: _noopPicker,
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('warlock_matrix_path_card')), findsOneWidget);
    expect(find.byKey(const Key('warlock_matrix_path_field')), findsOneWidget);
    expect(find.byKey(const Key('warlock_matrix_path_browse')), findsOneWidget);
    expect(find.byKey(const Key('warlock_matrix_path_save')), findsOneWidget);
    expect(find.text('No path set'), findsOneWidget);
  });

  testWidgets('save invokes onSaved and shows not-found for missing path',
      (tester) async {
    String? saved;
    final controller = WarlockMatrixPathController(
      storageRoot: StorageRoot(basePath: '/tmp/warlock-matrix-card-fake2'),
      environment: const {},
      setting: _MemorySetting(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: WarlockMatrixPathCard(
              controller: controller,
              onSaved: (p) => saved = p,
              openFilePicker: _noopPicker,
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    await tester.enterText(
      find.byKey(const Key('warlock_matrix_path_field')),
      r'D:\matrix.json',
    );
    await tester.tap(find.byKey(const Key('warlock_matrix_path_save')));
    // Probe uses real dart:io — advance real async then rebuild.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (saved != null && find.text('File not found').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(saved, r'D:\matrix.json');
    expect(find.text('File not found'), findsOneWidget);
  });
}

/// In-memory setting store so widget tests avoid writing StorageRoot.
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
