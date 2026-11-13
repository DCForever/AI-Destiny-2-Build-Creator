import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_matrix.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_matrix_loader.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps matrix rows to MockBuild name/exotic/subclass/creator/dim', () {
    final rows = parseWarlockMatrix(
      jsonDecode(File(_fixturePath()).readAsStringSync()),
    );
    final fixture = buildsMockFixtureFromMatrix(rows);
    expect(fixture.builds, isNotEmpty);
    expect(fixture.sets, isEmpty);

    final sol = fixture.builds.firstWhere(
      (b) => b.name == 'Solipsism solar mismatch',
    );
    expect(sol.exoticArmor, 'Solipsism');
    expect(sol.exoticWeapon, isEmpty);
    expect(sol.subclass, 'Solar');
    expect(sol.creator, 'Fixture');
    expect(sol.dimLink, contains('dim.gg/syn-sol-solar'));
    expect(sol.solipsismNotPrismatic, isTrue);

    final prism = fixture.builds.firstWhere(
      (b) => b.name == 'Solipsism prismatic sample',
    );
    expect(prism.solipsismNotPrismatic, isFalse);

    final weapon = fixture.builds.firstWhere(
      (b) => b.name == 'Sunshot solar sample',
    );
    expect(weapon.exoticWeapon, 'Sunshot');
    expect(weapon.exoticArmor, isEmpty);
  });

  testWidgets('missing matrix path shows error, not sample builds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: const Scaffold(
          body: BuildsMockPage(
            // No controller → production path; null path → clear empty/error.
            warlockMatrixPath: null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_matrix_error')), findsOneWidget);
    expect(find.textContaining('WARLOCK_MATRIX_PATH'), findsOneWidget);
    expect(find.textContaining('Settings'), findsOneWidget);
    expect(find.text('MOCK-UP — example data'), findsNothing);
    expect(find.text('Techsec Prismatic core'), findsNothing);
    expect(find.byKey(const Key('builds_mock_list')), findsNothing);
  });

  testWidgets('matrix-backed controller fills the lazy build list', (
    tester,
  ) async {
    final rows = parseWarlockMatrix(
      jsonDecode(File(_fixturePath()).readAsStringSync()),
    );
    final controller = BuildsMockController.forMatrixLoad()
      ..adoptFixture(buildsMockFixtureFromMatrix(rows));

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: BuildsMockPage(controller: controller),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_matrix_error')), findsNothing);
    expect(find.byKey(const Key('builds_mock_card_grid_3')), findsOneWidget);
    expect(find.text('Aeon solar sample'), findsWidgets);
    expect(find.text('Solipsism only works with Prismatic'), findsWidgets);
    expect(find.text('MOCK-UP — example data'), findsNothing);
    expect(find.byKey(const Key('builds_mock_count')), findsOneWidget);
  });

  testWidgets('matrix read failure shows error, not sample builds', (
    tester,
  ) async {
    final controller = BuildsMockController.forMatrixLoad()
      ..failMatrixLoad('File not found.');

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: BuildsMockPage(controller: controller),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('builds_mock_matrix_error')), findsOneWidget);
    expect(find.textContaining('File not found'), findsOneWidget);
    expect(find.text('Techsec Prismatic core'), findsNothing);
    expect(find.text('MOCK-UP — example data'), findsNothing);
  });

  testWidgets('matrix over-cap error copy is shown (no sample builds)', (
    tester,
  ) async {
    // Injected-message path (no dart:io). Real Builds loader over-cap IO is
    // covered by the sibling non-widget test below (mirrors Warlocks).
    final controller = BuildsMockController.forMatrixLoad()
      ..failMatrixLoad('file exceeds size limit (64 > 8 bytes)');

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(body: BuildsMockPage(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('builds_mock_matrix_error')), findsOneWidget);
    expect(find.textContaining('file exceeds size limit'), findsOneWidget);
    expect(find.textContaining('64 > 8'), findsOneWidget);
    expect(find.text('Techsec Prismatic core'), findsNothing);
  });

  test('Builds matrix load over maxBytes surfaces a clear size-limit error',
      () async {
    final dir = await Directory.systemTemp.createTemp('builds_matrix_cap_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/huge.json')
      ..writeAsBytesSync(List<int>.filled(64, 0x20));

    final controller = BuildsMockController.forMatrixLoad();
    await loadBuildsMatrixIntoController(
      controller: controller,
      path: file.path,
      maxBytes: 8,
    );

    expect(controller.fixture.builds, isEmpty);
    expect(controller.matrixError, contains('file exceeds size limit'));
    expect(controller.matrixError, contains('64 > 8'));
    expect(controller.showMockBanner, isFalse);
  });

  test('shouldApply false after await skips adopt and failMatrixLoad', () async {
    final controller = BuildsMockController.forMatrixLoad();
    var gates = 0;
    await loadBuildsMatrixIntoController(
      controller: controller,
      path: _fixturePath(),
      // Allow beginMatrixLoad, then refuse adopt/fail after the async read.
      shouldApply: () {
        gates += 1;
        return gates == 1;
      },
    );
    expect(gates, greaterThanOrEqualTo(2));
    expect(controller.matrixLoading, isTrue);
    expect(controller.matrixError, isNull);
    expect(controller.fixture.builds, isEmpty);
  });
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
