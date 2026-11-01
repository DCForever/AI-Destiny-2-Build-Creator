import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/warlock/warlock_builds_controller.dart';
import 'package:destiny2_windows_host/warlock/warlock_builds_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  testWidgets('exotic filter and Solipsism flag', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final http = GetOnlyHttpClient(HttpClient());
    final controller = WarlockBuildsController(http: http);
    addTearDown(() => http.close(force: true));
    final decoded = jsonDecode(File(_fixturePath()).readAsStringSync());
    controller.adoptBuilds(parseWarlockMatrix(decoded));

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: WarlockBuildsPage(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Aeon solar sample'), findsOneWidget);
    expect(find.text('Necrotic strand sample'), findsOneWidget);
    expect(find.text('Solipsism only works with Prismatic'), findsOneWidget);
    expect(find.text('Subclass unresolved'), findsOneWidget);

    await _selectExotic(tester, 'Aeon Soul');
    expect(find.text('Aeon solar sample'), findsOneWidget);
    expect(find.text('Aeon void sample'), findsOneWidget);
    expect(find.text('Solipsism prismatic sample'), findsNothing);
    expect(find.text('Solipsism only works with Prismatic'), findsNothing);
    expect(find.text('Subclass unresolved'), findsNothing);

    await _selectExotic(tester, 'Solipsism');
    expect(find.text('Solipsism prismatic sample'), findsOneWidget);
    expect(find.text('Solipsism solar mismatch'), findsOneWidget);
    expect(find.text('Solipsism combo sample'), findsOneWidget);
    expect(find.text('Subclass unresolved'), findsOneWidget);
    expect(find.text('Solipsism only works with Prismatic'), findsOneWidget);
    expect(find.text('Aeon solar sample'), findsNothing);
  });
}

Future<void> _selectExotic(WidgetTester tester, String exotic) async {
  await tester.tap(find.byKey(const Key('warlock_exotic_filter')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(exotic).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'warlock matrix fixture not found from ${Directory.current.path}',
  );
}
