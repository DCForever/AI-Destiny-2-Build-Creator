import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/warlock/pilot_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  testWidgets('review shows gaps, synthetic status, and no personal output',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final board = loadPilotBoard(
      matrixJson: File(_fixture('contrast_matrix.json')).readAsStringSync(),
      csvText: File(_fixture('contrast_queue.csv')).readAsStringSync(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: PilotReviewPage(board: board),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('pilot_synthetic_banner')), findsOneWidget);
    expect(
        find.textContaining('not an account-verified loadout'), findsWidgets);
    expect(find.textContaining('Perfect Fifth'), findsWidgets);
    expect(find.textContaining('perk not specified'), findsWidgets);
    expect(find.textContaining('Spirit of Apotheosis'), findsWidgets);
    expect(find.textContaining('Apotheosis + Harmony'), findsWidgets);
    expect(find.textContaining('invalid_solipsism_subclass'), findsOneWidget);
    expect(find.textContaining('Loop: (blank)'), findsWidgets);
    expect(find.textContaining('Title: Gambit'), findsWidgets);
    expect(
        find.byKey(const Key('pilot_no_export_suutekk-solar')), findsOneWidget);
    expect(find.byKey(const Key('pilot_no_export_kahoona-hexbugs')),
        findsOneWidget);
    expect(find.text('Apply'), findsNothing);

    final sample =
        tester.widget<Text>(find.byKey(const Key('pilot_shape_sample')));
    expect(sample.data, contains(pilotSyntheticBanner));
    expect(sample.data, isNot(contains('dim.gg')));
    expect(find.textContaining('not a global optimum'), findsWidgets);
    expect(
      find.byKey(const Key('pilot_perk_synthetic-solipsism-name-only')),
      findsOneWidget,
    );
    expect(
      find.textContaining('synthetic-solipsism-name-only is not a match'),
      findsOneWidget,
    );
  });
}

String _fixture(String name) {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidates = <File>[
      File('${dir.path}/assets/pilot/$name'),
      File('${dir.path}/apps/windows_host/assets/pilot/$name'),
    ];
    for (final candidate in candidates) {
      if (candidate.existsSync()) return candidate.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
      'pilot fixture $name not found from ${Directory.current.path}');
}
