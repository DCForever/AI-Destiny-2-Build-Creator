import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: Daniel 8:41 AM PT Nov 13 2026 — "Bug: doesn't pick up the saved
/// path". Settings showed the saved matrix; Builds said No matrix file path
/// after restart because preference IO finished after BuildsMockPage initState.
///
/// Widget coverage mirrors Destiny2WindowsApp's resolved-gate + didUpdateWidget
/// reload (without full shell). Preference file round-trip is asserted in the
/// storage package tests; here we feed the path that would have been loaded.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'saved path after startup gate → Builds loads matrix (no empty-path flash)',
      (tester) async {
    expect(Platform.environment[warlockMatrixPathEnv], isNull);
    final fixturePath = _fixturePath();

    final harnessKey = GlobalKey<_StartupMatrixPathHarnessState>();
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: _StartupMatrixPathHarness(key: harnessKey),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('builds_mock_matrix_loading')), findsOneWidget);
    expect(find.textContaining('No matrix file path'), findsNothing);

    // App finished reading `{StorageRoot}/settings/warlock_matrix_path.txt`.
    harnessKey.currentState!.resolveSavedSetting(fixturePath);
    await tester.pump();

    var sawGrid = false;
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byKey(const Key('builds_mock_card_grid_3')).evaluate().isNotEmpty ||
          find.byKey(const Key('builds_mock_matrix_error')).evaluate().isNotEmpty) {
        sawGrid =
            find.byKey(const Key('builds_mock_card_grid_3')).evaluate().isNotEmpty;
        break;
      }
    }

    expect(find.textContaining('No matrix file path'), findsNothing);
    expect(find.byKey(const Key('builds_mock_matrix_error')), findsNothing);
    expect(sawGrid, isTrue);
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);
    expect(find.text('Aeon solar sample'), findsWidgets);
  });

  testWidgets(
      'unresolved gate holds loading until preference resolves to none',
      (tester) async {
    expect(Platform.environment[warlockMatrixPathEnv], isNull);

    final harnessKey = GlobalKey<_StartupMatrixPathHarnessState>();
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: _StartupMatrixPathHarness(key: harnessKey),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('builds_mock_matrix_loading')), findsOneWidget);
    expect(find.textContaining('No matrix file path'), findsNothing);

    harnessKey.currentState!.resolveSavedSetting(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_matrix_error')), findsOneWidget);
    expect(find.textContaining('No matrix file path'), findsOneWidget);
  });
}

class _StartupMatrixPathHarness extends StatefulWidget {
  const _StartupMatrixPathHarness({super.key});

  @override
  State<_StartupMatrixPathHarness> createState() =>
      _StartupMatrixPathHarnessState();
}

class _StartupMatrixPathHarnessState extends State<_StartupMatrixPathHarness> {
  String? _savedMatrixPath;
  bool _savedMatrixPathResolved = false;

  void resolveSavedSetting(String? saved) {
    setState(() {
      _savedMatrixPath = saved;
      _savedMatrixPathResolved = true;
    });
  }

  String? get _matrixPath => resolveWarlockMatrixPath(
        savedSetting: _savedMatrixPath,
        environment: Platform.environment,
      );

  @override
  Widget build(BuildContext context) {
    return BuildsMockPage(
      warlockMatrixPath: _matrixPath,
      matrixPathSettingResolved: _savedMatrixPathResolved,
    );
  }
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/../../packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'warlock_matrix_min.json not found from ${Directory.current.path}',
  );
}
